#include "StackTrace/StackTrace.h"
#include "StackTrace/ErrorHandlers.h"
#include "StackTrace/Utilities.h"

// Replace sith std::string_view when we switch to c++17
#include "StackTrace/string_view.h"

#include <algorithm>
#include <csignal>
#include <cstring>
#include <iostream>
#include <map>
#include <memory>
#include <mutex>
#include <random>
#include <set>
#include <sstream>
#include <stdexcept>
#include <thread>


#define perr std::cerr

using StackTrace::string_view;

// Detect the OS
// clang-format off
#if defined( WIN32 ) || defined( _WIN32 ) || defined( WIN64 ) || defined( _WIN64 ) || defined( _MSC_VER )
    #define USE_WINDOWS
    #define NOMINMAX
#elif defined( __APPLE__ )
    #define USE_MAC
    #define USE_NM
#elif defined( __linux ) || defined( __linux__ ) || defined( __unix ) || defined( __posix )
    #define USE_LINUX
    #define USE_NM
#else
    #error Unknown OS
#endif
// clang-format on


// Include system dependent headers
// clang-format off
// Detect the OS and include system dependent headers
#ifdef USE_WINDOWS
    #include <windows.h>
    #include <dbghelp.h>
    #include <DbgHelp.h>
    #include <TlHelp32.h>
    #include <Psapi.h>
    #include <process.h>
    #include <stdio.h>
    #include <tchar.h>
    #pragma comment( lib, "version.lib" ) // for "VerQueryValue"
#else
    #include <dlfcn.h>
    #include <execinfo.h>
    #include <sched.h>
    #include <sys/time.h>
    #include <ctime>
    #include <unistd.h>
    #include <sys/syscall.h>
#endif
#ifdef USE_MAC
    #include <mach-o/dyld.h>
    #include <mach/mach.h>
    #include <sys/sysctl.h>
    #include <sys/types.h>
    #define SIGRTMIN SIGUSR1
    #define SIGRTMAX SIGUSR2
#endif
// clang-format on


#ifdef __GNUC__
#define USE_ABI
#include <cxxabi.h>
#endif


#ifndef NULL_USE
#define NULL_USE( variable )                       \
    do {                                           \
        if ( 0 ) {                                 \
            auto static temp = (char *) &variable; \
            temp++;                                \
        }                                          \
    } while ( 0 )
#endif


// Mutex for StackTrace opertions that need blocking
static std::mutex StackTrace_mutex;


// Helper thread
static std::shared_ptr<std::thread> globalMonitorThread;


// Function to replace all instances of a string with another
static constexpr size_t replace(
    char *str, size_t N, size_t pos, size_t len, const string_view &r ) noexcept
{
    size_t Nr = r.size();
    auto tmp  = str;
    size_t k  = pos;
    for ( size_t i = 0; i < Nr && k < N; i++, k++ )
        str[k] = r[i];
    for ( size_t i = pos + len; i < N && k < N; i++, k++ )
        str[k] = tmp[i];
    for ( size_t m = k; m < N; m++ )
        str[k] = 0;
    return k;
}
template<std::size_t N>
static constexpr size_t replace(
    std::array<char, N> &str, size_t pos, size_t len, const string_view &r ) noexcept
{
    return replace( str.data(), N, pos, len, r );
}
template<std::size_t N>
static inline constexpr size_t find(
    std::array<char, N> &str, const string_view &match, size_t pos = 0 ) noexcept
{
    string_view str2( str.data(), str.size() );
    return str2.find( match, pos );
}
static inline constexpr size_t find(
    const string_view &str, const string_view &match, size_t pos = 0 ) noexcept
{
    return str.find( match, pos );
}
template<std::size_t N>
static constexpr void strrep(
    std::array<char, N> &str, const string_view &s, const string_view &r ) noexcept
{
    size_t Ns  = s.size();
    size_t pos = find( str, s );
    while ( pos != std::string::npos ) {
        Ns  = replace( str, pos, Ns, r );
        pos = find( str, s );
    }
}
static constexpr void strrep(
    char *str, size_t &N, const string_view &s, const string_view &r ) noexcept
{
    size_t Ns  = s.size();
    size_t pos = find( str, s );
    while ( pos != std::string::npos ) {
        N   = replace( str, N, pos, Ns, r );
        pos = find( str, s );
    }
}

static void cleanupFunctionName( char * );


// Utility to strip the path from a filename
static constexpr const char *stripPath( const char *filename ) noexcept
{
    const char *s = filename;
    while ( *s ) {
        if ( *s == 47 || *s == 92 )
            filename = s + 1;
        ++s;
    }
    return filename;
}


// Functions to hash strings
constexpr uint32_t hashString( const char *s )
{
    uint32_t c    = 0;
    uint32_t hash = 5381;
    while ( ( c = *s++ ) )
        hash = ( ( hash << 5 ) + hash ) ^ c;
    return hash;
}
template<std::size_t N1, std::size_t N2>
static constexpr uint64_t objHash(
    const std::array<char, N1> &obj, const std::array<char, N2> &objPath )
{
    uint32_t v1  = hashString( obj.data() );
    uint32_t v2  = hashString( objPath.data() );
    uint64_t key = ( static_cast<uint64_t>( v1 ) << 32 ) + static_cast<uint64_t>( v1 ^ v2 );
    return key;
}


//! Assign a string to a std::array
template<std::size_t N2>
static constexpr void copy( const char *in, std::array<char, N2> &out ) noexcept
{
    size_t N1 = strlen( in );
    out.fill( 0 );
    if ( N1 < N2 ) {
        memcpy( out.data(), in, N1 );
    } else {
        memcpy( out.data(), in, N2 - 4 );
        out[N2 - 4] = out[N2 - 3] = out[N2 - 2] = '.';
    }
}
template<std::size_t N1, std::size_t N2>
static constexpr void copy( const std::array<char, N1> &in, std::array<char, N2> &out ) noexcept
{
    out.fill( 0 );
    if ( N1 < N2 ) {
        memcpy( out.data(), in.data(), N1 );
    } else {
        memcpy( out.data(), in.data(), N2 - 4 );
        out[N2 - 4] = out[N2 - 3] = out[N2 - 2] = '.';
    }
}
template<std::size_t N2, std::size_t N3>
static constexpr void copy(
    const char *in, std::array<char, N2> &out, std::array<char, N3> &outPath ) noexcept
{
    auto ptr = stripPath( in );
    copy( ptr, out );
    outPath.fill( 0 );
    if ( ptr != in ) {
        size_t N = ptr - in - 1;
        if ( N < N3 ) {
            memcpy( outPath.data(), in, N );
        } else {
            memcpy( outPath.data(), in, N3 - 4 );
            outPath[N3 - 4] = outPath[N3 - 3] = outPath[N3 - 2] = '.';
        }
    }
}


// Inline function to subtract two addresses returning the absolute difference
static inline void *subtractAddress( void *a, void *b ) noexcept
{
    return reinterpret_cast<void *>(
        std::abs( reinterpret_cast<int64_t>( a ) - reinterpret_cast<int64_t>( b ) ) );
}


#ifdef USE_WINDOWS
static BOOL __stdcall readProcMem( HANDLE hProcess, DWORD64 qwBaseAddress, PVOID lpBuffer,
    DWORD nSize, LPDWORD lpNumberOfBytesRead )
{
    SIZE_T st;
    BOOL bRet = ReadProcessMemory( hProcess, (LPVOID) qwBaseAddress, lpBuffer, nSize, &st );
    *lpNumberOfBytesRead = (DWORD) st;
    return bRet;
}
static inline std::string getCurrentDirectory()
{
    char temp[1024] = { 0 };
    GetCurrentDirectoryA( sizeof( temp ), temp );
    return temp;
}
namespace StackTrace {
BOOL GetModuleListTH32( HANDLE hProcess, DWORD pid );
BOOL GetModuleListPSAPI( HANDLE hProcess );
DWORD LoadModule( HANDLE hProcess, LPCSTR img, LPCSTR mod, DWORD64 baseAddr, DWORD size );
void LoadModules();
}; // namespace StackTrace
#endif


// Functions to copy data
static char *copy_in( size_t N, const void *data, char *ptr )
{
    memcpy( ptr, data, N );
    return ptr + N;
}
static const char *copy_out( size_t N, void *data, const char *ptr )
{
    memcpy( data, ptr, N );
    return ptr + N;
}


/****************************************************************************
 *  Utility functions to use std::vector like a set                          *
 ****************************************************************************/
template<class TYPE>
static inline void erase( std::vector<TYPE> &x, TYPE y )
{
    x.erase( std::find( x.begin(), x.end(), y ) );
}
template<class TYPE>
static inline void insert( std::vector<TYPE> &x, TYPE y )
{
    if ( std::find( x.begin(), x.end(), y ) == x.end() ) {
        x.push_back( y );
        std::sort( x.begin(), x.end() );
    }
}


/****************************************************************************
 *  Utility to call system command and return output                         *
 ****************************************************************************/
#ifdef USE_WINDOWS
#define popen _popen
#define pclose _pclose
#endif
static std::vector<std::array<char, 1024>> exec2( const char *cmd )
{
    std::vector<std::array<char, 1024>> out;
    auto old  = signal( SIGCHLD, SIG_DFL ); // Clear child exited
    auto pipe = popen( cmd, "r" );
    if ( pipe == nullptr )
        return out;
    out.reserve( 128 );
    while ( !feof( pipe ) ) {
        char buffer[0x2000];
        buffer[0] = 0;
        auto ptr  = fgets( buffer, sizeof( buffer ), pipe );
        NULL_USE( ptr );
        size_t N2 = strlen( buffer );
        if ( N2 > 0 ) {
            size_t k = out.size();
            out.resize( k + 1 );
            out[k].fill( 0 );
            memcpy( out[k].data(), buffer, N2 );
            if ( out[k][N2 - 1] == '\n' )
                out[k][N2 - 1] = 0;
        }
    }
    pclose( pipe );
    std::this_thread::yield(); // Allow any signals to process
    signal( SIGCHLD, old );    // Reset child exited signal
    return out;
}
std::string StackTrace::exec( const std::string &cmd, int &code )
{
    auto old   = signal( SIGCHLD, SIG_DFL ); // Clear child exited
    FILE *pipe = popen( cmd.c_str(), "r" );
    if ( pipe == nullptr )
        return std::string();
    std::string result = "";
    result.reserve( 1024 );
    while ( !feof( pipe ) ) {
        char buffer[257];
        buffer[256] = 0;
        if ( fgets( buffer, 128, pipe ) != nullptr )
            result += buffer;
    }
    auto status = pclose( pipe );
    code        = WEXITSTATUS( status );
    std::this_thread::yield(); // Allow any signals to process
    signal( SIGCHLD, old );    // Reset child exited signal
    return result;
}


/****************************************************************************
 *  stack_info                                                               *
 ****************************************************************************/
static_assert( sizeof( StackTrace::stack_info ) <= 512, "Unexpected size for stack_info" );
StackTrace::stack_info::stack_info() { clear(); }
void StackTrace::stack_info::clear()
{
    line     = 0;
    address  = nullptr;
    address2 = nullptr;
    object.fill( 0 );
    objectPath.fill( 0 );
    filename.fill( 0 );
    filenamePath.fill( 0 );
    function.fill( 0 );
}
bool StackTrace::stack_info::operator==( const StackTrace::stack_info &rhs ) const
{
    if ( address == rhs.address )
        return true;
    if ( address2 == rhs.address2 && object == rhs.object )
        return true;
    return false;
}
bool StackTrace::stack_info::operator!=( const StackTrace::stack_info &rhs ) const
{
    return !operator==( rhs );
}
int StackTrace::stack_info::getAddressWidth() const
{
    auto addr = reinterpret_cast<unsigned long long int>( address );
    if ( addr <= 0xFFFF )
        return 4;
    if ( addr <= 0xFFFFFFFF )
        return 8;
    if ( addr <= 0xFFFFFFFFFFFF )
        return 12;
    return 16;
}
std::string StackTrace::stack_info::print( int w1, int w2, int w3 ) const
{
    char out[8192] = { 0 };
    char tmp1[16], tmp2[16];
    sprintf( tmp1, "0x%%0%illx:  ", w1 );
    sprintf( tmp2, "%%%is  %%%is", w2, w3 );
    size_t pos = 0;
    pos += sprintf( &out[pos], tmp1, reinterpret_cast<unsigned long long int>( address ) );
    pos += sprintf( &out[pos], tmp2, stripPath( object.data() ), function.data() );
    if ( filename[0] != 0 && line > 0 ) {
        pos += sprintf( &out[pos], "  %s:%u", stripPath( filename.data() ), line );
    } else if ( filename[0] != 0 ) {
        pos += sprintf( &out[pos], "  %s", stripPath( filename.data() ) );
    } else if ( line > 0 ) {
        pos += sprintf( &out[pos], " : %u", line );
    }
    return std::string( out );
}
size_t StackTrace::stack_info::size() const { return sizeof( *this ); }
char *StackTrace::stack_info::pack( char *ptr ) const
{
    memcpy( ptr, this, sizeof( *this ) );
    return ptr + sizeof( *this );
}
const char *StackTrace::stack_info::unpack( const char *ptr )
{
    memcpy( this, ptr, sizeof( *this ) );
    return ptr + sizeof( *this );
}
std::vector<char> StackTrace::stack_info::packArray( const std::vector<stack_info> &data )
{
    size_t size = sizeof( int );
    for ( const auto &i : data )
        size += i.size();
    std::vector<char> vec( size, 0 );
    char *ptr = vec.data();
    int N     = data.size();
    ptr       = copy_in( sizeof( int ), &N, ptr );
    for ( const auto &i : data )
        ptr = i.pack( ptr );
    return vec;
}
std::vector<StackTrace::stack_info> StackTrace::stack_info::unpackArray( const char *ptr )
{
    int N;
    ptr = copy_out( sizeof( int ), &N, ptr );
    std::vector<stack_info> data( N );
    for ( auto &i : data )
        ptr = i.unpack( ptr );
    return data;
}
#ifdef USE_MPI
static std::vector<char> pack( const std::vector<std::vector<StackTrace::stack_info>> &data )
{
    size_t size = sizeof( int );
    for ( const auto &i : data ) {
        size += sizeof( int );
        for ( size_t j = 0; j < i.size(); j++ )
            size += i[j].size();
    }
    std::vector<char> out( size, 0 );
    char *ptr = out.data();
    int N     = data.size();
    ptr       = copy_in( sizeof( int ), &N, ptr );
    for ( int i = 0; i < N; i++ ) {
        int M = data[i].size();
        ptr   = copy_in( sizeof( int ), &M, ptr );
        for ( int j = 0; j < M; j++ )
            ptr = data[i][j].pack( ptr );
    }
    return out;
}
static std::vector<std::vector<StackTrace::stack_info>> unpack( const std::vector<char> &in )
{
    const char *ptr = in.data();
    int N;
    ptr = copy_out( sizeof( int ), &N, ptr );
    std::vector<std::vector<StackTrace::stack_info>> data( N );
    for ( int i = 0; i < N; i++ ) {
        int M;
        ptr = copy_out( sizeof( int ), &M, ptr );
        data[i].resize( M );
        for ( int j = 0; j < M; j++ )
            ptr = data[i][j].unpack( ptr );
    }
    return data;
}
#endif


/****************************************************************************
 *  multi_stack_info                                                         *
 ****************************************************************************/
StackTrace::multi_stack_info::multi_stack_info( const std::vector<stack_info> &rhs )
{
    operator=( rhs );
}
StackTrace::multi_stack_info &StackTrace::multi_stack_info::operator=(
    const std::vector<stack_info> &rhs )
{
    clear();
    if ( rhs.empty() )
        return *this;
    N     = 1;
    stack = rhs[0];
    if ( rhs.size() > 1 )
        add( rhs.size() - 1, &rhs[1] );
    return *this;
}
void StackTrace::multi_stack_info::clear()
{
    N = 0;
    stack.clear();
    children.clear();
}
void StackTrace::multi_stack_info::print2(
    const std::string &prefix, int w[3], std::vector<std::string> &text ) const
{
    if ( stack == stack_info() ) {
        for ( const auto &child : children )
            child.print2( "", w, text );
        return;
    }
    std::string line = prefix + "[" + std::to_string( N ) + "] " + stack.print( w[0], w[1], w[2] );
    text.push_back( line );
    std::string prefix2 = prefix + "  ";
    for ( size_t i = 0; i < children.size(); i++ ) {
        const auto &child = children[i];
        std::vector<std::string> text2;
        child.print2( "", w, text2 );
        for ( size_t j = 0; j < text2.size(); j++ ) {
            std::string line = prefix2 + text2[j];
            if ( children.size() > 1 && j > 0 && i < children.size() - 1 )
                line[prefix2.size()] = '|';
            text.push_back( line );
        }
    }
}
std::vector<std::string> StackTrace::multi_stack_info::print( const std::string &prefix ) const
{
    std::vector<std::string> text;
    int w[3] = { getAddressWidth(), getObjectWidth(), getFunctionWidth() };
    print2( prefix, w, text );
    return text;
}
int StackTrace::multi_stack_info::getAddressWidth() const
{
    int w = stack.getAddressWidth();
    for ( const auto &child : children )
        w = std::max( w, child.getAddressWidth() );
    return w;
}
int StackTrace::multi_stack_info::getObjectWidth() const
{
    int w = std::min<int>( stack.object.size() + 1, 20 );
    for ( const auto &child : children )
        w = std::max( w, child.getObjectWidth() );
    return w;
}
int StackTrace::multi_stack_info::getFunctionWidth() const
{
    int w = std::min<int>( stack.function.size() + 1, 40 );
    for ( const auto &child : children )
        w = std::max( w, child.getFunctionWidth() );
    return w;
}
void StackTrace::multi_stack_info::add( size_t len, const stack_info *stack )
{
    if ( len == 0 )
        return;
    const auto &s = stack[len - 1];
    for ( auto &i : children ) {
        if ( i.stack == s ) {
            i.N++;
            if ( len > 1 )
                i.add( len - 1, stack );
            return;
        }
    }
    children.resize( children.size() + 1 );
    children.back().N     = 1;
    children.back().stack = s;
    if ( len > 1 )
        children.back().add( len - 1, stack );
}


/****************************************************************************
 *  abort_error                                                              *
 ****************************************************************************/
StackTrace::abort_error::abort_error()
    : type( terminateType::unknown ), signal( 0 ), line( -1 ), bytes( 0 )
{
}
const char *StackTrace::abort_error::what() const noexcept
{
    d_msg.clear();
    if ( type == terminateType::abort ) {
        d_msg += "Program abort called";
    } else if ( type == terminateType::signal ) {
        d_msg += "Unhandled signal (" + std::to_string( signal ) + ") caught";
    } else if ( type == terminateType::exception ) {
        d_msg += "Unhandled exception caught";
    } else if ( type == terminateType::MPI ) {
        d_msg += "Error calling MPI routine";
    } else {
        d_msg += "Unknown error called";
    }
    if ( !filename.empty() ) {
        d_msg += " in file '" + filename + "'";
        if ( line > 0 ) {
            d_msg += " at line " + std::to_string( line );
        }
    }
    d_msg += ":\n";
    d_msg += "   " + message + "\n";
    if ( bytes > 0 ) {
        d_msg += "Bytes used = " + std::to_string( bytes ) + "\n";
    }
    if ( !stack.empty() ) {
        d_msg += "Stack Trace:\n";
        auto data = stack.print();
        for ( const auto &tmp : data )
            d_msg += " " + tmp + "\n";
    }
    for ( size_t i = 0; i < d_msg.size(); i++ )
        if ( d_msg[i] == 0 )
            d_msg.erase( i, 1 );
    return d_msg.c_str();
}


/****************************************************************************
 *  Function to get the executable name                                      *
 ****************************************************************************/
static char global_exe_name[1000] = { 0 };
static bool setGlobalExecutableName( char *exe )
{
    try {
#ifdef USE_LINUX
        auto *buf = new char[0x10000];
        int len   = ::readlink( "/proc/self/exe", buf, 0x10000 );
        if ( len != -1 ) {
            buf[len] = '\0';
            strcpy( exe, buf );
        }
        delete[] buf;
#elif defined( USE_MAC )
        uint32_t size = 0x10000;
        char *buf     = new char[size];
        memset( buf, 0, size );
        if ( _NSGetExecutablePath( buf, &size ) == 0 )
            strcpy( exe, buf );
        delete[] buf;
#elif defined( USE_WINDOWS )
        DWORD size = 0x10000;
        char *buf  = new char[size];
        memset( buf, 0, size );
        GetModuleFileName( nullptr, buf, size );
        strcpy( exe, buf );
        delete[] buf;
#endif
    } catch ( ... ) {
    }
    return true;
}
static bool global_exe_name_set = setGlobalExecutableName( global_exe_name );
std::string StackTrace::getExecutable()
{
    if ( !global_exe_name_set )
        global_exe_name_set = setGlobalExecutableName( global_exe_name );
    return std::string( global_exe_name );
}


/****************************************************************************
 * Function to get symbols for the executable from nm (if availible)         *
 * Note: this function maintains an internal cached copy to prevent          *
 *    exccessive calls to nm.  This function also uses a lock to ensure      *
 *    thread safety.                                                         *
 ****************************************************************************/
static_assert( sizeof( StackTrace::symbols_struct ) <= 128, "Unexpected size for symbols_struct" );
std::vector<StackTrace::symbols_struct> global_symbols_data;
static bool global_symbols_loaded = false;
static std::vector<StackTrace::symbols_struct> getSymbolData()
{
    std::vector<StackTrace::symbols_struct> data;
#ifdef USE_NM
    try {
        char cmd[1024];
#ifdef USE_LINUX
        sprintf( cmd, "nm -n --demangle %s", global_exe_name );
#elif defined( USE_MAC )
        sprintf( cmd, "nm -n %s | c++filt", global_exe_name );
#else
#error Unknown OS using nm
#endif
        auto output = exec2( cmd );
        for ( auto &line : output ) {
            if ( line[0] == ' ' )
                continue;
            auto *a = line.data();
            char *b = strchr( a, ' ' );
            if ( b == nullptr )
                continue;
            b[0] = 0;
            b++;
            char *c = strchr( b, ' ' );
            if ( c == nullptr )
                continue;
            c[0] = 0;
            c++;
            char *d = strchr( c, '\n' );
            if ( d )
                d[0] = 0;
            size_t add = strtoul( a, nullptr, 16 );
            size_t k   = data.size();
            data.resize( k + 1 );
            data[k].address = reinterpret_cast<void *>( add );
            data[k].type    = b[0];
            copy( c, data[k].obj, data[k].objPath );
        }
    } catch ( ... ) {
    }
#endif
    return data;
}
std::vector<StackTrace::symbols_struct> StackTrace::getSymbols()
{
    StackTrace_mutex.lock();
    if ( !global_symbols_loaded ) {
        global_symbols_data   = getSymbolData();
        global_symbols_loaded = true;
    }
    auto data = global_symbols_data;
    StackTrace_mutex.unlock();
    return data;
}
void StackTrace::clearSymbols()
{
    StackTrace_mutex.lock();
    if ( global_symbols_loaded ) {
        global_symbols_data   = std::vector<StackTrace::symbols_struct>();
        global_symbols_loaded = false;
    }
    StackTrace_mutex.unlock();
}


/****************************************************************************
 *  Function to get call stack info                                          *
 ****************************************************************************/
#ifdef USE_MAC
static void *loadAddress( const uint32_t &obj_hash )
{
    static std::map<uint32_t, void *> obj_map;
    if ( obj_map.empty() ) {
        uint32_t numImages = _dyld_image_count();
        for ( uint32_t i = 0; i < numImages; i++ ) {
            auto header  = _dyld_get_image_header( i );
            auto name    = _dyld_get_image_name( i );
            auto p       = strrchr( name, '/' );
            auto address = const_cast<struct mach_header *>( header );
            auto hash    = hashString( p + 1 );
            obj_map.insert( std::make_pair( hash, address ) );
        }
    }
    auto it       = obj_map.find( obj_hash );
    void *address = 0;
    if ( it != obj_map.end() ) {
        address = it->second;
    } else {
        it = obj_map.find( obj_hash );
        if ( it != obj_map.end() )
            address = it->second;
    }
    return address;
}
static auto split_atos( const std::string &buf )
{
    int line = 0;
    std::array<char, 2048> fun;
    std::array<char, 64> obj, file, objPath, filePath;
    if ( buf.empty() )
        return std::tie( fun, obj, objPath, file, filePath, line );
    // Get the function
    size_t index = buf.find( " (in " );
    if ( index == std::string::npos ) {
        copy( buf.c_str(), fun );
        cleanupFunctionName( fun );
        return std::tie( fun, obj, objPath, file, filePath, line );
    }
    copy( buf.substr( 0, index ).c_str(), fun );
    cleanupFunctionName( fun );
    std::string tmp = buf.substr( index + 5 );
    // Get the object
    index = tmp.find( ')' );
    copy( tmp.substr( 0, index ).c_str(), obj, objPath );
    tmp = tmp.substr( index + 1 );
    // Get the filename and line number
    size_t p1 = tmp.find( '(' );
    size_t p2 = tmp.find( ')' );
    tmp       = tmp.substr( p1 + 1, p2 - p1 - 1 );
    index     = tmp.find( ':' );
    if ( index != std::string::npos ) {
        copy( tmp.substr( 0, index ).c_str(), file, filePath );
        line = std::stoi( tmp.substr( index + 1 ) );
    } else if ( p1 != std::string::npos ) {
        copy( tmp.c_str(), file, filePath );
    }
    return std::tie( fun, obj, objPath, file, filePath, line );
}
#endif
// clang-format off
static void getFileAndLineObject( std::vector<StackTrace::stack_info*> &info )
{
    if ( info.empty() )
        return;
    // This gets the file and line numbers for multiple stack lines in the same object
    #if defined( USE_LINUX )
        // Create the call command
        char cmd[4096];
        static_assert( sizeof(unsigned long) == sizeof(size_t), "Unxpected size for ul" );
        uint32_t N = sprintf(cmd,"addr2line -C -e %s -f",info[0]->object.data());
        for (size_t i=0; i<info.size() && N < sizeof(cmd) - 32; i++) {
            N += sprintf(&cmd[N]," %lx %lx",
                reinterpret_cast<unsigned long>( info[i]->address ),
                reinterpret_cast<unsigned long>( info[i]->address2 ) );
        }
        N += sprintf(&cmd[N]," 2> /dev/null");
        // Get the function/line/file
        auto output = exec2( cmd );
        if ( output.size() != 4*info.size() )
            return;
        // Add the results to info
        for (size_t i=0; i<info.size(); i++) {
            char *tmp1 = output[4*i+0].data();
            char *tmp2 = output[4*i+1].data();
            if ( tmp1[0] == '?' && tmp1[1] == '?' ) {
                tmp1 = output[4*i+2].data();
                tmp2 = output[4*i+3].data();
            }
            if ( tmp1[0] == '?' && tmp1[1] == '?' ) {
                continue;
            }
            // get function name
            if ( info[i]->function.empty() ) {
                cleanupFunctionName( tmp1 );
                copy( tmp1, info[i]->function );
            }
            // get file and line
            char *buf = tmp2;
            if ( buf[0] != '?' && buf[0] != 0 ) {
                size_t j = 0;
                for ( j = 0; j < 4095 && buf[j] != ':'; j++ ) {
                }
                buf[j] = 0;
                copy( buf, info[i]->filename, info[i]->filenamePath );
                info[i]->line = atoi( &buf[j + 1] );
            }
        }
    #elif defined( USE_MAC ) 
        // Create the call command
        void* load_address = loadAddress( hashString( info[0]->object.data() ) );
        if ( load_address == nullptr )
            return;
        // Call atos to get the object info
        char cmd[4096];
        static_assert( sizeof(unsigned long) == sizeof(size_t), "Unxpected size for ul" );
        uint32_t N = sprintf( cmd, "atos -o %s -f -l %lx", info[0]->object.data(),
            reinterpret_cast<unsigned long>( load_address ) );
        for (size_t i=0; i<info.size() && N < sizeof(cmd) - 32; i++)
            N += sprintf( &cmd[N], " %lx", reinterpret_cast<unsigned long>( info[i]->address ) );
        N += sprintf(&cmd[N]," 2> /dev/null");
        // Get the function/line/file
        auto output = exec2( cmd );
        if ( output.size() != info.size() )
            return;
        // Parse the output for function, file and line info
        for ( size_t i=0; i<info.size(); i++) {
            auto data = split_atos( output[2*i].data() );
            if ( info[i]->function.empty() )
                info[i]->function = std::get<0>(data);
            if ( info[i]->object.empty() ) {
                info[i]->object = std::get<1>(data);
                info[i]->objectPath = std::get<2>(data);
            }
            if ( info[i]->filename.empty() ) {
                info[i]->filename = std::get<3>(data);
                info[i]->filenamePath = std::get<4>(data);
            }
            if ( info[i]->line==0 )
                info[i]->line = std::get<5>(data);
        }
    #endif
}
static void getFileAndLine( std::vector<StackTrace::stack_info> &info )
{
    // Get a list of objects
    std::vector<uint64_t> objectHash;
    objectHash.reserve( 1024 );
    for ( const auto & tmp : info )
        insert( objectHash, objHash( tmp.object, tmp.objectPath ) );
    // For each object, get the file/line numbers for all entries
    std::vector<StackTrace::stack_info*> list;
    list.reserve( info.size() );
    for ( const auto & hash : objectHash ) {
        list.clear();
        for (auto & tmp : info ) {
            if ( objHash( tmp.object, tmp.objectPath ) == hash )
                list.push_back( &tmp );
        }
        getFileAndLineObject( list );
    }
}
// Try to use the global symbols to decode info about the stack
static void getDataFromGlobalSymbols( StackTrace::stack_info &info )
{
    if ( !global_symbols_loaded ) {
        global_symbols_data   = getSymbolData();
        global_symbols_loaded = true;
    }
    const auto &data = global_symbols_data;
    if ( !data.empty() ) {
        // Find the closest address
        size_t lower = 0;
        size_t upper = data.size() - 1;
        while ( ( upper - lower ) != 1 ) {
            size_t value = ( upper + lower ) / 2;
            if ( data[value].address >= info.address )
                upper = value;
            else
                lower = value;
        }
        if ( upper > 0 ) {
            copy( data[lower].obj, info.object );
            copy( data[lower].objPath, info.objectPath );
        } else {
            copy( global_exe_name, info.object, info.objectPath );
        }
    }
}
static void signal_handler( int sig )
{
    printf("Signal caught acquiring stack (%i)\n",sig);
    StackTrace::setErrorHandler( [](const StackTrace::abort_error &err) { std::cerr << err.what(); exit( -1 ); } );
}
StackTrace::stack_info StackTrace::getStackInfo( void *address )
{
    return getStackInfo( std::vector<void*>(1,address) )[0];
}
std::vector<StackTrace::stack_info> StackTrace::getStackInfo( const std::vector<void*>& address )
{
    // Temporarily handle signals to prevent recursion on the stack
    auto prev_handler = signal( SIGINT, signal_handler );
    // Get the detailed stack info
    std::vector<StackTrace::stack_info> info(address.size());
    try {
        #ifdef USE_WINDOWS
            IMAGEHLP_SYMBOL64 pSym[1024];
            memset( pSym, 0, sizeof( pSym ) );
            pSym->SizeOfStruct  = sizeof( IMAGEHLP_SYMBOL64 );
            pSym->MaxNameLength = 1024;

            IMAGEHLP_MODULE64 Module;
            memset( &Module, 0, sizeof( Module ) );
            Module.SizeOfStruct = sizeof( Module );

            HANDLE pid = GetCurrentProcess();

            for (size_t i=0; i<address.size(); i++) {
                info[i].address = address[i];
                DWORD64 address2 = reinterpret_cast<DWORD64>( address[i] );
                DWORD64 offsetFromSymbol;
                if ( SymGetSymFromAddr( pid, address2, &offsetFromSymbol, pSym ) != FALSE ) {
                    char name[8192]={0};
                    DWORD rtn = UnDecorateSymbolName( pSym->Name, name, sizeof(name)-1, UNDNAME_COMPLETE );
                    if ( rtn == 0 ) {
                        cleanupFunctionName( pSym->Name );
                        copy( pSym->Name, info[i].function );
                    } else {
                        info[i].function.fill( 0 );
                    }
                } else {
                    printf( "ERROR: SymGetSymFromAddr (%d,%p)\n", GetLastError(), address2 );
                }

                // Get line number
                IMAGEHLP_LINE64 Line;
                memset( &Line, 0, sizeof( Line ) );
                Line.SizeOfStruct = sizeof( Line );
                DWORD offsetFromLine;
                if ( SymGetLineFromAddr64( pid, address2, &offsetFromLine, &Line ) != FALSE ) {
                    info[i].line     = Line.LineNumber;
                    copy( Line.FileName, info[i].filename, info[i].filenamePath );
                } else {
                    info[i].line     = 0;
                    copy( nullptr, info[i].filename, info[i].filenamePath );
                }

                // Get the object
                if ( SymGetModuleInfo64( pid, address2, &Module ) != FALSE ) {
                    copy( Module.LoadedImageName, info[i].object, info[i].objectPath );
                }
            }
        #else
            for (size_t i=0; i<address.size(); i++) {
                info[i].address = address[i];
                #if defined(_GNU_SOURCE) || defined(USE_MAC)
                    Dl_info dlinfo;
                    if ( !dladdr( info[i].address, &dlinfo ) ) {
                        getDataFromGlobalSymbols( info[i] );
                        continue;
                    }
                    info[i].address2 = subtractAddress( info[i].address, dlinfo.dli_fbase );
                    copy( dlinfo.dli_fname, info[i].object, info[i].objectPath );
                    #if defined( USE_ABI )
                        int status;
                        char *demangled = abi::__cxa_demangle( dlinfo.dli_sname, nullptr, nullptr, &status );
                        if ( status == 0 && demangled != nullptr ) {
                            cleanupFunctionName( demangled );
                            copy( demangled, info[i].function );
                        } else if ( dlinfo.dli_sname != nullptr ) {
                            copy( dlinfo.dli_sname, info[i].function );
                        }
                        free( demangled );
                    #endif
                    if ( dlinfo.dli_sname != nullptr && info[i].function[0] == 0 ) {
                        std::array<char,4096> tmp;
                        copy( dlinfo.dli_sname, tmp );
                        cleanupFunctionName( tmp.data() );
                        copy( tmp, info[i].function );
                    }
                #else
                    getDataFromGlobalSymbols( info[i] );
                #endif
            }
            // Get the filename / line numbers for each item on the stack
            getFileAndLine( info );
        #endif
    } catch ( ... ) {
    }
    signal( SIGINT, prev_handler ) ;
    return info;
}


/****************************************************************************
*  Helper functions for controlling interal signals                         *
****************************************************************************/
static int backtrace_thread( const std::thread::native_handle_type&, void**, size_t );
#if defined( USE_LINUX ) || defined( USE_MAC )
static int thread_backtrace_count;
static void* thread_backtrace[1000];
static void _callstack_signal_handler( int, siginfo_t*, void* )
{
    thread_backtrace_count = backtrace_thread( StackTrace::thisThread(), thread_backtrace, 1000 );
}
static int get_thread_callstack_signal()
{
    if ( 39 >= SIGRTMIN && 39 <= SIGRTMAX )
        return 39;
    return std::min<int>( SIGRTMIN+4, SIGRTMAX );
}
static int thread_callstack_signal = get_thread_callstack_signal();
#endif


/****************************************************************************
*  Function to get the list of all active threads                           *
****************************************************************************/
#if defined( USE_LINUX ) || defined( USE_MAC )
static std::thread::native_handle_type thread_handle;
static bool thread_id_finished;
static void _activeThreads_signal_handler( int )
{
    auto handle = StackTrace::thisThread( );
    thread_handle = handle;
    thread_id_finished = true;
}
/*static void _activeThreads2( void )
{
    auto handle = StackTrace::thisThread( );
    thread_handle = handle;
    thread_id_finished = true;
}*/
#endif
#ifdef USE_LINUX
static constexpr int get_tid( int pid, const char *line )
{
    char buf2[128]={0};
    int i1 = 0;
    while ( line[i1]==' ' ) { i1++; }
    int i2 = i1;
    while ( line[i2]!=' ' ) { i2++; }
    memcpy(buf2,&line[i1],i2-i1);
    buf2[i2-i1+1] = 0;
    int pid2 = atoi(buf2);
    if ( pid2 != pid )
        return -1;
    i1 = i2;
    while ( line[i1]==' ' ) { i1++; }
    i2 = i1;
    while ( line[i2]!=' ' ) { i2++; }
    memcpy(buf2,&line[i1],i2-i1);
    buf2[i2-i1+1] = 0;
    int tid = atoi(buf2);
    return tid;
}
#endif
std::thread::native_handle_type StackTrace::thisThread( )
{
    #if defined( USE_LINUX ) || defined( USE_MAC )
        return pthread_self();
    #elif defined( USE_WINDOWS )
        return GetCurrentThread();
    #else
        #warning Stack trace is not supported on this compiler/OS
        return std::thread::native_handle_type();
    #endif
}
static std::vector<std::thread::native_handle_type> getActiveThreads( )
{
    std::vector<std::thread::native_handle_type> threads;
    threads.reserve( 128 );
    #if defined( USE_LINUX )
        std::vector<int> tid;
        tid.reserve( 128 );
        int pid = getpid();
        char cmd[128];
        sprintf( cmd, "ps -T -p %i", pid );
        auto output = exec2( cmd );
        for ( const auto& line : output ) {
            int tid2 = get_tid( pid, line.data() );
            if ( tid2 != -1 )
                insert( tid, tid2 );
        }
        erase<int>( tid, syscall(SYS_gettid) );
        auto old = signal( thread_callstack_signal, _activeThreads_signal_handler );
        for ( auto tid2 : tid ) {
            StackTrace_mutex.lock();
            thread_id_finished = false;
            thread_handle = StackTrace::thisThread();
            syscall( SYS_tgkill, pid, tid2, thread_callstack_signal );
            auto t1 = std::chrono::high_resolution_clock::now();
            auto t2 = std::chrono::high_resolution_clock::now();
            while ( !thread_id_finished && std::chrono::duration<double>(t2-t1).count()<0.1 ) {
                std::this_thread::yield();
                t2 = std::chrono::high_resolution_clock::now();
            }
            threads.push_back( thread_handle );
            StackTrace_mutex.unlock();
        }
        signal( thread_callstack_signal, old );
    #elif defined( USE_MAC )
        thread_act_port_array_t thread_list;
        mach_msg_type_number_t thread_count = 0;
        task_threads(mach_task_self(), &thread_list, &thread_count);
        auto old = signal( thread_callstack_signal, _activeThreads_signal_handler );
        for ( int i=0; i<thread_count; i++) {
            if ( thread_list[i] == mach_thread_self() )
                continue;
            static bool called = false;
            if ( !called ) {
                called = true;
                std::cerr << "activeThreads not finished for MAC\n";
            }
            /*
            StackTrace_mutex.lock();
            thread_id_finished = false;
            thread_handle = thisThread();
            x86_thread_state64_t state;
            unsigned int count = MACHINE_THREAD_STATE_COUNT;
            thread_abort( thread_list[i] );  // Abort system calls
            thread_suspend( thread_list[i] );
            thread_get_state( thread_list[i], MACHINE_THREAD_STATE, (thread_state_t) &state, &count );
            state.__rip = (uint64_t) _activeThreads2;
            thread_set_state( thread_list[i], MACHINE_THREAD_STATE, (thread_state_t) &state, MACHINE_THREAD_STATE_COUNT );
            thread_resume( thread_list[i] );
            //pthread_kill( thread_list[i], CALLSTACK_SIG );
            //syscall( SYS___pthread_kill, getpid(), thread_list[i], CALLSTACK_SIG );
            //syscall( SYS_kill, thread_list[i], CALLSTACK_SIG );
            auto t1 = std::chrono::high_resolution_clock::now();
            auto t2 = std::chrono::high_resolution_clock::now();
            while ( !thread_id_finished && std::chrono::duration<double>(t2-t1).count()<0.1 ) {
                std::this_thread::yield();
                t2 = std::chrono::high_resolution_clock::now();
            }
            threads.push_back( thread_handle );
            StackTrace_mutex.unlock();*/
        }
        signal( thread_callstack_signal, old );
    #elif defined( USE_WINDOWS )
        HANDLE hThreadSnap = CreateToolhelp32Snapshot( TH32CS_SNAPTHREAD, 0 ); 
        if( hThreadSnap != INVALID_HANDLE_VALUE ) {
            // Fill in the size of the structure before using it
            THREADENTRY32 te32
            te32.dwSize = sizeof(THREADENTRY32 );
            // Retrieve information about the first thread, and exit if unsuccessful
            if( !Thread32First( hThreadSnap, &te32 ) ) {
                printError( TEXT("Thread32First") );    // Show cause of failure
                CloseHandle( hThreadSnap );             // Must clean up the snapshot object!
                return( FALSE );
            }
            // Now walk the thread list of the system
            do { 
                if ( te32.th32OwnerProcessID == dwOwnerPID )
                    threads.push_back( te32.th32ThreadID );
            } while( Thread32Next(hThreadSnap, &te32 ) );
            CloseHandle( hThreadSnap );                 // Must clean up the snapshot object!
        }
    #else
        #warning activeThreads is not yet supported on this compiler/OS
    #endif
    // Add the current thread
    threads.push_back( StackTrace::thisThread() );
    // Remove the globalMonitorThread
    if ( globalMonitorThread ) {
        auto globalThreadId = globalMonitorThread->native_handle();
        for ( int i = threads.size() - 1; i >= 0; i-- ) {
            if ( threads[i] == globalThreadId ) {
                std::swap( threads[i], threads.back() );
                threads.pop_back();
            }
        }
    }
    // Sort the threads, remove any duplicates and remove the globalMonitorThread
    std::sort( threads.begin(), threads.end() );
    return threads;
}
// clang-format on
std::set<std::thread::native_handle_type> StackTrace::activeThreads()
{
    auto threads = getActiveThreads();
    return std::set<std::thread::native_handle_type>( threads.begin(), threads.end() );
}


/****************************************************************************
 *  Function to get the backtrace                                            *
 ****************************************************************************/
static int backtrace_thread(
    const std::thread::native_handle_type &tid, void **buffer, size_t size )
{
    int count = 0;
#if defined( USE_LINUX ) || defined( USE_MAC )
    // Get the trace
    if ( tid == pthread_self() ) {
        count = ::backtrace( buffer, size );
    } else {
        // Note: this will get the backtrace, but terminates the thread in the process!!!
        StackTrace_mutex.lock();
        struct sigaction sa;
        sigfillset( &sa.sa_mask );
        sa.sa_flags     = SA_SIGINFO;
        sa.sa_sigaction = _callstack_signal_handler;
        sigaction( thread_callstack_signal, &sa, nullptr );
        thread_backtrace_count = -1;
        pthread_kill( tid, thread_callstack_signal );
        auto t1 = std::chrono::high_resolution_clock::now();
        auto t2 = std::chrono::high_resolution_clock::now();
        while ( thread_backtrace_count == -1 &&
                std::chrono::duration<double>( t2 - t1 ).count() < 0.15 ) {
            std::this_thread::yield();
            t2 = std::chrono::high_resolution_clock::now();
        }
        count = std::max( thread_backtrace_count, 0 );
        memcpy( buffer, thread_backtrace, count * sizeof( void * ) );
        thread_backtrace_count = -1;
        StackTrace_mutex.unlock();
    }
#elif defined( USE_WINDOWS )
#if defined( DBGHELP )

    // Load the modules for the stack trace
    LoadModules();

    // Initialize stackframe for first call
    ::CONTEXT context;
    memset( &context, 0, sizeof( context ) );
    context.ContextFlags = CONTEXT_FULL;
    RtlCaptureContext( &context );
    STACKFRAME64 frame; // in/out stackframe
    memset( &frame, 0, sizeof( frame ) );
#ifdef _M_IX86
    DWORD imageType = IMAGE_FILE_MACHINE_I386;
    frame.AddrPC.Offset = context.Eip;
    frame.AddrPC.Mode = AddrModeFlat;
    frame.AddrFrame.Offset = context.Ebp;
    frame.AddrFrame.Mode = AddrModeFlat;
    frame.AddrStack.Offset = context.Esp;
    frame.AddrStack.Mode = AddrModeFlat;
#elif _M_X64
    DWORD imageType        = IMAGE_FILE_MACHINE_AMD64;
    frame.AddrPC.Offset    = context.Rip;
    frame.AddrPC.Mode      = AddrModeFlat;
    frame.AddrFrame.Offset = context.Rsp;
    frame.AddrFrame.Mode   = AddrModeFlat;
    frame.AddrStack.Offset = context.Rsp;
    frame.AddrStack.Mode   = AddrModeFlat;
#elif _M_IA64
    DWORD imageType         = IMAGE_FILE_MACHINE_IA64;
    frame.AddrPC.Offset     = context.StIIP;
    frame.AddrPC.Mode       = AddrModeFlat;
    frame.AddrFrame.Offset  = context.IntSp;
    frame.AddrFrame.Mode    = AddrModeFlat;
    frame.AddrBStore.Offset = context.RsBSP;
    frame.AddrBStore.Mode   = AddrModeFlat;
    frame.AddrStack.Offset  = context.IntSp;
    frame.AddrStack.Mode    = AddrModeFlat;
#else
#error "Platform not supported!"
#endif

    auto pid = GetCurrentProcess();
    for ( int frameNum = 0; frameNum < 1024; ++frameNum ) {
        BOOL rtn = StackWalk64( imageType, pid, tid, &frame, &context, readProcMem,
            SymFunctionTableAccess, SymGetModuleBase64, NULL );
        if ( !rtn ) {
            printf( "ERROR: StackWalk64 (%p)\n", frame.AddrPC.Offset );
            break;
        }
        if ( frame.AddrPC.Offset != 0 ) {
                    buffer[count] = reinterpret_cast<void*>( frame.AddrPC.Offset ) );
                    count++;
        }
        if ( frame.AddrReturn.Offset == 0 )
            break;
    }
    SetLastError( ERROR_SUCCESS );
#endif
#else
#warning Stack trace is not supported on this compiler/OS
#endif
    return count;
}
std::vector<void *> StackTrace::backtrace( std::thread::native_handle_type tid )
{
    std::vector<void *> trace( 1000, nullptr );
    size_t count = backtrace_thread( tid, trace.data(), trace.size() );
    trace.resize( count );
    return trace;
}
std::vector<void *> StackTrace::backtrace()
{
    std::vector<void *> trace( 1000, nullptr );
    size_t count = backtrace_thread( thisThread(), trace.data(), trace.size() );
    trace.resize( count );
    return trace;
}
std::vector<std::vector<void *>> StackTrace::backtraceAll()
{
    // Get the list of threads
    auto threads = getActiveThreads();
    // Get the backtrace of each thread
    std::vector<std::vector<void *>> trace( threads.size() );
    size_t i = 0;
    for ( auto it = threads.begin(); i < threads.size(); i++, it++ ) {
        trace[i].resize( 1000 );
        size_t count = backtrace_thread( *it, trace[i].data(), trace[i].size() );
        trace[i].resize( count );
    }
    return trace;
}


/****************************************************************************
 *  Function to get the current call stack                                   *
 ****************************************************************************/
std::vector<StackTrace::stack_info> StackTrace::getCallStack()
{
    auto trace = StackTrace::backtrace();
    auto info  = getStackInfo( trace );
    return info;
}
std::vector<StackTrace::stack_info> StackTrace::getCallStack( std::thread::native_handle_type id )
{
    auto trace = StackTrace::backtrace( id );
    auto info  = getStackInfo( trace );
    return info;
}
static std::vector<std::vector<StackTrace::stack_info>> generateStacks(
    const std::vector<std::vector<void *>> &trace )
{
    // Get the stack data for all pointers
    std::vector<void *> addresses;
    addresses.reserve( 1024 );
    for ( const auto &tmp : trace ) {
        for ( auto ptr : tmp )
            insert( addresses, ptr );
    }
    auto stack_data = StackTrace::getStackInfo( addresses );
    std::map<void *, StackTrace::stack_info> map_data;
    for ( size_t i = 0; i < addresses.size(); i++ )
        map_data.insert( std::make_pair( addresses[i], stack_data[i] ) );
    // Create the stack traces
    std::vector<std::vector<StackTrace::stack_info>> stack( trace.size() );
    for ( size_t i = 0; i < trace.size(); i++ ) {
        // Create the stack for the given thread trace
        stack[i].resize( trace[i].size() );
        for ( size_t j = 0; j < trace[i].size(); j++ )
            stack[i][j] = map_data[trace[i][j]];
    }
    return stack;
}
static StackTrace::multi_stack_info generateMultiStack(
    const std::vector<std::vector<void *>> &trace )
{
    // Get the stack data for all pointers
    auto stack = generateStacks( trace );
    // Create the multi-stack trace
    StackTrace::multi_stack_info multistack;
    multistack.N = stack.size();
    for ( const auto &tmp : stack )
        multistack.add( tmp.size(), tmp.data() );
    return multistack;
}
StackTrace::multi_stack_info StackTrace::getAllCallStacks()
{
    // Get the backtrace of each thread
    auto thread_backtrace = backtraceAll();
    // Create the multi-stack strucutre
    auto stack = generateMultiStack( thread_backtrace );
    return stack;
}


/****************************************************************************
 *  Function to get system search paths                                      *
 ****************************************************************************/
std::string StackTrace::getSymPaths()
{
    std::string paths;
#ifdef USE_WINDOWS
    // Create the path list (seperated by ';' )
    paths = std::string( ".;" );
    paths.reserve( 1000 );
    // Add the current directory
    paths += getCurrentDirectory() + ";";
    // Now add the path for the main-module:
    char temp[1024];
    memset( temp, 0, sizeof( temp ) );
    if ( GetModuleFileNameA( nullptr, temp, sizeof( temp ) - 1 ) > 0 ) {
        for ( char *p = ( temp + strlen( temp ) - 1 ); p >= temp; --p ) {
            // locate the rightmost path separator
            if ( ( *p == '\\' ) || ( *p == '/' ) || ( *p == ':' ) ) {
                *p = 0;
                break;
            }
        }
        if ( strlen( temp ) > 0 ) {
            paths += temp;
            paths += ";";
        }
    }
    memset( temp, 0, sizeof( temp ) );
    if ( GetEnvironmentVariableA( "_NT_SYMBOL_PATH", temp, sizeof( temp ) - 1 ) > 0 ) {
        paths += temp;
        paths += ";";
    }
    memset( temp, 0, sizeof( temp ) );
    if ( GetEnvironmentVariableA( "_NT_ALTERNATE_SYMBOL_PATH", temp, sizeof( temp ) - 1 ) > 0 ) {
        paths += temp;
        paths += ";";
    }
    memset( temp, 0, sizeof( temp ) );
    if ( GetEnvironmentVariableA( "SYSTEMROOT", temp, sizeof( temp ) - 1 ) > 0 ) {
        paths += temp;
        paths += ";";
        // also add the "system32"-directory:
        paths += temp;
        paths += "\\system32;";
    }
    memset( temp, 0, sizeof( temp ) );
    if ( GetEnvironmentVariableA( "SYSTEMDRIVE", temp, sizeof( temp ) - 1 ) > 0 ) {
        paths += "SRV*;" + std::string( temp ) +
                 "\\websymbols*http://msdl.microsoft.com/download/symbols;";
    } else {
        paths += "SRV*c:\\websymbols*http://msdl.microsoft.com/download/symbols;";
    }
#endif
    return paths;
}


/****************************************************************************
 *  Load modules for windows                                                 *
 ****************************************************************************/
#ifdef USE_WINDOWS
BOOL StackTrace::GetModuleListTH32( HANDLE hProcess, DWORD pid )
{
    // CreateToolhelp32Snapshot()
    typedef HANDLE( __stdcall * tCT32S )( DWORD dwFlags, DWORD th32ProcessID );
    // Module32First()
    typedef BOOL( __stdcall * tM32F )( HANDLE hSnapshot, LPMODULEENTRY32 lpme );
    // Module32Next()
    typedef BOOL( __stdcall * tM32N )( HANDLE hSnapshot, LPMODULEENTRY32 lpme );

    // try both dlls...
    const TCHAR *dllname[] = { _T("kernel32.dll"), _T("tlhelp32.dll") };
    HINSTANCE hToolhelp    = nullptr;
    tCT32S pCT32S          = nullptr;
    tM32F pM32F            = nullptr;
    tM32N pM32N            = nullptr;

    HANDLE hSnap;
    MODULEENTRY32 me;
    me.dwSize = sizeof( me );

    for ( size_t i = 0; i < ( sizeof( dllname ) / sizeof( dllname[0] ) ); i++ ) {
        hToolhelp = LoadLibrary( dllname[i] );
        if ( hToolhelp == nullptr )
            continue;
        pCT32S = (tCT32S) GetProcAddress( hToolhelp, "CreateToolhelp32Snapshot" );
        pM32F  = (tM32F) GetProcAddress( hToolhelp, "Module32First" );
        pM32N  = (tM32N) GetProcAddress( hToolhelp, "Module32Next" );
        if ( ( pCT32S != nullptr ) && ( pM32F != nullptr ) && ( pM32N != nullptr ) )
            break; // found the functions!
        FreeLibrary( hToolhelp );
        hToolhelp = nullptr;
    }

    if ( hToolhelp == nullptr )
        return FALSE;

    hSnap = pCT32S( TH32CS_SNAPMODULE, pid );
    if ( hSnap == (HANDLE) -1 ) {
        FreeLibrary( hToolhelp );
        return FALSE;
    }

    bool keepGoing = !!pM32F( hSnap, &me );
    int cnt        = 0;
    while ( keepGoing ) {
        LoadModule( hProcess, me.szExePath, me.szModule, (DWORD64) me.modBaseAddr, me.modBaseSize );
        cnt++;
        keepGoing = !!pM32N( hSnap, &me );
    }
    CloseHandle( hSnap );
    FreeLibrary( hToolhelp );
    if ( cnt <= 0 )
        return FALSE;
    return TRUE;
}
DWORD StackTrace::LoadModule(
    HANDLE hProcess, LPCSTR img, LPCSTR mod, DWORD64 baseAddr, DWORD size )
{
    CHAR *szImg  = _strdup( img );
    CHAR *szMod  = _strdup( mod );
    DWORD result = ERROR_SUCCESS;
    if ( ( szImg == nullptr ) || ( szMod == nullptr ) ) {
        result = ERROR_NOT_ENOUGH_MEMORY;
    } else {
        if ( SymLoadModule( hProcess, 0, szImg, szMod, baseAddr, size ) == 0 )
            result = GetLastError();
    }
    ULONGLONG fileVersion = 0;
    if ( szImg != nullptr ) {
        // try to retrive the file-version:
        VS_FIXEDFILEINFO *fInfo = nullptr;
        DWORD dwHandle;
        DWORD dwSize = GetFileVersionInfoSizeA( szImg, &dwHandle );
        if ( dwSize > 0 ) {
            LPVOID vData = malloc( dwSize );
            if ( vData != nullptr ) {
                if ( GetFileVersionInfoA( szImg, dwHandle, dwSize, vData ) != 0 ) {
                    UINT len;
                    TCHAR szSubBlock[] = _T("\\");
                    if ( VerQueryValue( vData, szSubBlock, (LPVOID *) &fInfo, &len ) == 0 ) {
                        fInfo = nullptr;
                    } else {
                        fileVersion = ( (ULONGLONG) fInfo->dwFileVersionLS ) +
                                      ( (ULONGLONG) fInfo->dwFileVersionMS << 32 );
                    }
                }
                free( vData );
            }
        }

        // Retrive some additional-infos about the module
        IMAGEHLP_MODULE64 Module;
        Module.SizeOfStruct = sizeof( IMAGEHLP_MODULE64 );
        SymGetModuleInfo64( hProcess, baseAddr, &Module );
        LPCSTR pdbName = Module.LoadedImageName;
        if ( Module.LoadedPdbName[0] != 0 )
            pdbName = Module.LoadedPdbName;
    }
    if ( szImg != nullptr )
        free( szImg );
    if ( szMod != nullptr )
        free( szMod );
    return result;
}
BOOL StackTrace::GetModuleListPSAPI( HANDLE hProcess )
{
    DWORD cbNeeded;
    HMODULE hMods[1024];
    char tt[8192];
    char tt2[8192];
    if ( !EnumProcessModules( hProcess, hMods, sizeof( hMods ), &cbNeeded ) ) {
        return false;
    }
    if ( cbNeeded > sizeof( hMods ) ) {
        printf( "Insufficient memory allocated in GetModuleListPSAPI\n" );
        return false;
    }
    int cnt = 0;
    for ( DWORD i = 0; i < cbNeeded / sizeof( hMods[0] ); i++ ) {
        // base address, size
        MODULEINFO mi;
        GetModuleInformation( hProcess, hMods[i], &mi, sizeof( mi ) );
        // image file name
        tt[0] = 0;
        GetModuleFileNameExA( hProcess, hMods[i], tt, sizeof( tt ) );
        // module name
        tt2[0] = 0;
        GetModuleBaseNameA( hProcess, hMods[i], tt2, sizeof( tt2 ) );
        DWORD dwRes = LoadModule( hProcess, tt, tt2, (DWORD64) mi.lpBaseOfDll, mi.SizeOfImage );
        if ( dwRes != ERROR_SUCCESS )
            printf( "ERROR: LoadModule (%d)\n", dwRes );
        cnt++;
    }

    return cnt != 0;
}
void StackTrace::LoadModules()
{
    static bool modules_loaded = false;
    if ( !modules_loaded ) {
        modules_loaded = true;

        // Get the search paths for symbols
        std::string paths = StackTrace::getSymPaths();

        // Initialize the symbols
        if ( SymInitialize( GetCurrentProcess(), paths.c_str(), FALSE ) == FALSE )
            printf( "ERROR: SymInitialize (%d)\n", GetLastError() );

        DWORD symOptions = SymGetOptions();
        symOptions |= SYMOPT_LOAD_LINES | SYMOPT_FAIL_CRITICAL_ERRORS;
        symOptions     = SymSetOptions( symOptions );
        char buf[1024] = { 0 };
        if ( SymGetSearchPath( GetCurrentProcess(), buf, sizeof( buf ) ) == FALSE )
            printf( "ERROR: SymGetSearchPath (%d)\n", GetLastError() );

        // First try to load modules from toolhelp32
        BOOL loaded = StackTrace::GetModuleListTH32( GetCurrentProcess(), GetCurrentProcessId() );

        // Try to load from Psapi
        if ( !loaded )
            loaded = StackTrace::GetModuleListPSAPI( GetCurrentProcess() );
    }
}
#endif


/****************************************************************************
 *  Get the signal name                                                      *
 ****************************************************************************/
std::string StackTrace::signalName( int sig )
{
    StackTrace_mutex.lock();
    std::string name( strsignal( sig ) );
    StackTrace_mutex.unlock();
    return name;
}
std::vector<int> StackTrace::allSignalsToCatch()
{
    std::vector<int> signals;
    signals.reserve( SIGRTMAX );
    for ( int i = 1; i < 32; i++ ) {
        if ( i == SIGKILL || i == SIGSTOP )
            continue;
        signals.push_back( i );
    }
    for ( int i = SIGRTMIN; i <= SIGRTMAX; i++ ) {
        if ( i == SIGKILL || i == SIGSTOP )
            continue;
        signals.push_back( i );
    }
    return signals;
}
std::vector<int> StackTrace::defaultSignalsToCatch()
{
    auto signals = allSignalsToCatch();
    erase( signals, SIGWINCH ); // Don't catch window changed by default
    erase( signals, SIGCONT );  // Don't catch continue by default
    erase( signals, SIGCHLD );  // Don't catch child exited by default
    return signals;
}


/****************************************************************************
 *  Set the signal handlers                                                  *
 ****************************************************************************/
static std::function<void( const StackTrace::abort_error &err )> abort_fun;
static StackTrace::abort_error rethrow()
{
    StackTrace::abort_error error;
#ifdef USE_LINUX
    try {
        static int tried_throw = 0;
        if ( tried_throw == 0 ) {
            tried_throw = 1;
            throw;
        }
        // No active exception
    } catch ( const StackTrace::abort_error &err ) {
        // Caught a std::runtime_error
        error = err;
    } catch ( const std::exception &err ) {
        // Caught a std::runtime_error
        error.message = err.what();
    } catch ( ... ) {
        // Caught an unknown exception
        error.message = "Unknown exception";
    }
#else
    error.message = "Unknown exception";
#endif
    if ( error.type == StackTrace::terminateType::unknown )
        error.type = StackTrace::terminateType::exception;
    if ( error.bytes == 0 )
        error.bytes = StackTrace::Utilities::getMemoryUsage();
    if ( error.stack.empty() ) {
        error.stack = StackTrace::getCallStack();
        StackTrace::cleanupStackTrace( error.stack );
    }
    return error;
}
static void term_func_abort( int sig )
{
    StackTrace::abort_error err;
    err.type   = StackTrace::terminateType::signal;
    err.signal = sig;
    err.bytes  = StackTrace::Utilities::getMemoryUsage();
    err.stack  = StackTrace::getGlobalCallStacks();
    StackTrace::cleanupStackTrace( err.stack );
    abort_fun( err );
}
static bool signals_set[256] = { false };
static void term_func()
{
    auto err = rethrow();
    StackTrace::clearSignals();
    abort_fun( err );
}
static void null_term_func() {}
void StackTrace::clearSignal( int sig )
{
    if ( signals_set[sig] ) {
        signal( sig, SIG_DFL );
        signals_set[sig] = false;
    }
}
void StackTrace::clearSignals( const std::vector<int> &signals )
{
    for ( auto sig : signals ) {
        signal( sig, SIG_DFL );
        signals_set[sig] = false;
    }
}
void StackTrace::clearSignals()
{
    for ( size_t i = 0; i < sizeof( signals_set ); i++ ) {
        if ( signals_set[i] ) {
            signal( i, SIG_DFL );
            signals_set[i] = false;
        }
    }
}
void StackTrace::setSignals( const std::vector<int> &signals, void ( *handler )( int ) )
{
    for ( auto sig : signals ) {
        signal( sig, handler );
        signals_set[sig] = true;
    }
    std::this_thread::yield();
}
void StackTrace::raiseSignal( int signal ) { std::raise( signal ); }
void StackTrace::setErrorHandler( std::function<void( const StackTrace::abort_error & )> abort )
{
    abort_fun = abort;
    std::set_terminate( term_func );
    setSignals( defaultSignalsToCatch(), &term_func_abort );
    std::set_unexpected( term_func );
}
void StackTrace::clearErrorHandler()
{
    abort_fun = []( const StackTrace::abort_error & ) {};
    std::set_terminate( null_term_func );
    clearSignals();
    std::set_unexpected( null_term_func );
}


/****************************************************************************
 *  Functions to handle MPI errors                                           *
 ****************************************************************************/
#ifdef USE_MPI
static bool MPI_Initialized()
{
    int initialized = 0, finalized = 0;
    MPI_Initialized( &initialized );
    MPI_Finalized( &finalized );
    return initialized != 0 && finalized == 0;
}
static std::shared_ptr<MPI_Errhandler> mpierr;
static void MPI_error_handler_fun( MPI_Comm *comm, int *err, ... )
{
    if ( *err == MPI_ERR_COMM && *comm == MPI_COMM_WORLD ) {
        // Special error handling for an invalid MPI_COMM_WORLD
        std::cerr << "Error invalid MPI_COMM_WORLD";
        exit( -1 );
    }
    int msg_len        = 0;
    char message[1000] = { 0 };
    MPI_Error_string( *err, message, &msg_len );
    StackTrace::abort_error error;
    error.message = std::string( message );
    error.type    = StackTrace::terminateType::MPI;
    error.bytes   = StackTrace::Utilities::getMemoryUsage();
    error.stack   = StackTrace::getGlobalCallStacks();
    StackTrace::cleanupStackTrace( error.stack );
    throw error;
}
void StackTrace::setMPIErrorHandler( MPI_Comm comm )
{
    if ( !MPI_Initialized() )
        return;
    if ( mpierr.get() == nullptr ) {
        mpierr = std::make_shared<MPI_Errhandler>();
        MPI_Comm_create_errhandler( MPI_error_handler_fun, mpierr.get() );
    }
    MPI_Comm_set_errhandler( comm, *mpierr );
}
void StackTrace::clearMPIErrorHandler( MPI_Comm comm )
{
    if ( !MPI_Initialized() )
        return;
    if ( mpierr.get() != nullptr )
        MPI_Errhandler_free( mpierr.get() ); // Delete the error handler
    mpierr.reset();
    MPI_Comm_set_errhandler( comm, MPI_ERRORS_ARE_FATAL );
}
#else
void StackTrace::setMPIErrorHandler( MPI_Comm ) {}
void StackTrace::clearMPIErrorHandler( MPI_Comm ) {}
#endif


/****************************************************************************
 *  Global call stack functionallity                                         *
 ****************************************************************************/
#ifdef USE_MPI
static MPI_Comm globalCommForGlobalCommStack  = MPI_COMM_NULL;
static volatile int globalMonitorThreadStatus = -1;
static void runGlobalMonitorThread()
{
    int rank = 0;
    int size = 1;
    MPI_Comm_size( globalCommForGlobalCommStack, &size );
    MPI_Comm_rank( globalCommForGlobalCommStack, &rank );
    while ( globalMonitorThreadStatus == 1 ) {
        // Check for any messages
        int flag = 0;
        MPI_Status status;
        int err = MPI_Iprobe( MPI_ANY_SOURCE, 1, globalCommForGlobalCommStack, &flag, &status );
        if ( err != MPI_SUCCESS ) {
            printf( "Internal error in StackTrace::getGlobalCallStacks::runGlobalMonitorThread\n" );
            break;
        } else if ( flag != 0 ) {
            // We received a request
            int src_rank = status.MPI_SOURCE;
            int tag;
            MPI_Recv( &tag, 1, MPI_INT, src_rank, 1, globalCommForGlobalCommStack, &status );
            // Get the list of threads (except this)
            auto threads = StackTrace::activeThreads();
            threads.erase( StackTrace::thisThread() );
            if ( threads.empty() )
                continue;
            // Get the trace of each thread
            std::vector<std::vector<void *>> trace( threads.size() );
            auto it = threads.begin();
            for ( size_t i = 0; i < threads.size(); i++, ++it ) {
                trace[i].resize( 1000, nullptr );
                size_t count = backtrace_thread( *it, trace[i].data(), trace[i].size() );
                trace[i].resize( count );
            }
            // Get the stack info for the threads
            auto stack = generateStacks( trace );
            // Pack and send the data
            auto data = pack( stack );
            int count = data.size();
            MPI_Send( data.data(), count, MPI_CHAR, src_rank, tag, globalCommForGlobalCommStack );
        } else {
            // No requests recieved
            std::this_thread::sleep_for( std::chrono::milliseconds( 50 ) );
        }
    }
}
void StackTrace::globalCallStackInitialize( MPI_Comm comm )
{
    globalMonitorThreadStatus = 3;
    // Check that we have the necessary MPI thread support
    if ( !MPI_Initialized() ) {
        printf( "Warning: MPI not initialized before calling globalCallStackInitialize\n" );
        return;
    }
    int rank = 0;
    MPI_Comm_rank( comm, &rank );
    int provided;
    MPI_Query_thread( &provided );
    if ( provided != MPI_THREAD_MULTIPLE ) {
        if ( rank == 0 )
            printf( "Warning: getGlobalCallStacks requires support for MPI_THREAD_MULTIPLE\n" );
        return;
    }
    // Check that we have support to get call stacks from threads
    int N_threads = 0;
    if ( rank == 0 ) {
        std::thread thread( StackTrace::Utilities::sleep_ms, 200 );
        std::this_thread::yield();
        auto thread_ids = getActiveThreads();
        N_threads       = thread_ids.size();
        thread.join();
    }
    MPI_Bcast( &N_threads, 1, MPI_INT, 0, comm );
    if ( N_threads == 1 ) {
        if ( rank == 0 )
            printf( "Warning: getAllCallStacks not supported on this OS\n" );
        return;
    }
    // Create the communicator and initialize the helper thread
    globalMonitorThreadStatus = 1;
    MPI_Comm_dup( comm, &globalCommForGlobalCommStack );
    globalMonitorThread.reset( new std::thread( runGlobalMonitorThread ) );
    std::this_thread::sleep_for( std::chrono::milliseconds( 50 ) );
}
void StackTrace::globalCallStackFinalize()
{
    if ( globalMonitorThread ) {
        globalMonitorThreadStatus = 2;
        globalMonitorThread->join();
        globalMonitorThread.reset();
    }
    if ( globalCommForGlobalCommStack != MPI_COMM_NULL )
        MPI_Comm_free( &globalCommForGlobalCommStack );
    globalCommForGlobalCommStack = MPI_COMM_NULL;
}
StackTrace::multi_stack_info StackTrace::getGlobalCallStacks()
{
    if ( globalMonitorThreadStatus == -1 ) {
        // User did not call globalCallStackInitialize
        printf( "Warning: getGlobalCallStacks called without call to globalCallStackInitialize\n" );
        return getAllCallStacks();
    } else if ( globalMonitorThreadStatus != 1 ) {
        // globalCallStackInitialize is not supported
        return getAllCallStacks();
    }
    // Signal all processes that we want their stack for all threads
    int rank = 0;
    int size = 1;
    MPI_Comm_size( globalCommForGlobalCommStack, &size );
    MPI_Comm_rank( globalCommForGlobalCommStack, &rank );
    std::random_device rd;
    std::mt19937 gen( rd() );
    std::uniform_int_distribution<> dis( 2, 0x7FFF );
    int tag = dis( gen );
    std::vector<MPI_Request> sendRequest( size );
    for ( int i = 0; i < size; i++ ) {
        if ( i == rank )
            continue;
        MPI_Isend( &tag, 1, MPI_INT, i, 1, globalCommForGlobalCommStack, &sendRequest[i] );
    }
    // Get the trace for the current process
    auto threads = getActiveThreads();
    std::vector<std::vector<void *>> trace( threads.size() );
    auto it = threads.begin();
    for ( size_t i = 0; i < threads.size(); i++, ++it )
        trace[i] = StackTrace::backtrace( *it );
    auto multistack = generateMultiStack( trace );
    // Recieve the backtrace for all processes/threads
    int N_finished        = 1;
    auto start            = std::chrono::steady_clock::now();
    double time           = 0;
    const double max_time = 10.0 + size * 20e-3;
    while ( N_finished < size && time < max_time ) {
        int flag = 0;
        MPI_Status status;
        int err = MPI_Iprobe( MPI_ANY_SOURCE, tag, globalCommForGlobalCommStack, &flag, &status );
        if ( err != MPI_SUCCESS ) {
            printf( "Internal error in StackTrace::getGlobalCallStacks\n" );
            break;
        } else if ( flag != 0 ) {
            // We recieved a response
            int src_rank = status.MPI_SOURCE;
            int count;
            MPI_Get_count( &status, MPI_CHAR, &count );
            std::vector<char> data( count, 0 );
            MPI_Recv( data.data(), count, MPI_CHAR, src_rank, tag, globalCommForGlobalCommStack,
                &status );
            auto stack_list = unpack( data );
            for ( const auto &stack : stack_list )
                multistack.add( stack.size(), stack.data() );
            N_finished++;
        } else {
            auto stop = std::chrono::steady_clock::now();
            time      = std::chrono::duration_cast<std::chrono::seconds>( stop - start ).count();
            std::this_thread::yield();
        }
    }
    for ( int i = 0; i < size; i++ ) {
        if ( i == rank )
            continue;
        MPI_Request_free( &sendRequest[i] );
    }
    return multistack;
}
#else
void StackTrace::globalCallStackInitialize( MPI_Comm ) {}
void StackTrace::globalCallStackFinalize() {}
StackTrace::multi_stack_info StackTrace::getGlobalCallStacks() { return getAllCallStacks(); }
#endif


/****************************************************************************
 *  Cleanup the call stack                                                   *
 ****************************************************************************/
static constexpr size_t findMatching( const char *str, size_t N, size_t pos ) noexcept
{
    size_t pos2 = pos + 1;
    int count   = 1;
    while ( count != 0 && pos2 < N ) {
        if ( str[pos2] == '<' )
            count++;
        if ( str[pos2] == '>' )
            count--;
        pos2++;
    }
    return pos2;
}
template<std::size_t N>
static constexpr size_t findMatching( const std::array<char, N> &str, size_t pos ) noexcept
{
    return findMatching( str.data(), N );
}
static void cleanupFunctionName( char *function )
{
    constexpr size_t npos = std::string::npos;
    // First find the string length
    size_t N = strlen( function );
    // Cleanup template space
    strrep( function, N, " >", ">" );
    strrep( function, N, "< ", "<" );
    // Remove std::__1::
    strrep( function, N, "std::__1::", "std::" );
    // Replace std::chrono::duration with abbriviated version
    if ( find( function, "std::chrono::duration<" ) != npos ) {
        strrep( function, N, "std::chrono::duration<long, std::ratio<1l, 1l> >", "ticks" );
        strrep( function, N, "std::chrono::duration<long, std::ratio<1l, 1000000000l> >",
            "nanoseconds" );
    }
    // Replace std::ratio with abbriviated version.
    if ( find( function, "std::ratio<" ) != npos ) {
        strrep( function, N, "std::ratio<1l, 1000000000000000000000000l>", "std::yocto" );
        strrep( function, N, "std::ratio<1l, 1000000000000000000000l>", "std::zepto" );
        strrep( function, N, "std::ratio<1l, 1000000000000000000l>", "std::atto" );
        strrep( function, N, "std::ratio<1l, 1000000000000000l>", "std::femto" );
        strrep( function, N, "std::ratio<1l, 1000000000000l>", "std::pico" );
        strrep( function, N, "std::ratio<1l, 1000000000l>", "std::nano" );
        strrep( function, N, "std::ratio<1l, 1000000l>", "std::micro" );
        strrep( function, N, "std::ratio<1l, 1000l>", "std::milli" );
        strrep( function, N, "std::ratio<1l, 100l>", "std::centi" );
        strrep( function, N, "std::ratio<1l, 10l>", "std::deci" );
        strrep( function, N, "std::ratio<1l, 1l>", "" );
        strrep( function, N, "std::ratio<10l, 1l>", "std::deca" );
        strrep( function, N, "std::ratio<60l, 1l>", "std::ratio<60>" );
        strrep( function, N, "std::ratio<100l, 1l>", "std::hecto" );
        strrep( function, N, "std::ratio<1000l, 1l>", "std::kilo" );
        strrep( function, N, "std::ratio<3600l, 1l>", "std::ratio<3600>" );
        strrep( function, N, "std::ratio<1000000l, 1l>", "std::mega" );
        strrep( function, N, "std::ratio<1000000000l, 1l>", "std::giga" );
        strrep( function, N, "std::ratio<1000000000000l, 1l>", "std::tera" );
        strrep( function, N, "std::ratio<1000000000000000l, 1l>", "std::peta" );
        strrep( function, N, "std::ratio<1000000000000000000l, 1l>", "std::exa" );
        strrep( function, N, "std::ratio<1000000000000000000000l, 1l>", "std::zetta" );
        strrep( function, N, "std::ratio<1000000000000000000000000l, 1l>", "std::yotta" );
        strrep( function, N, " >", ">" );
        strrep( function, N, "< ", "<" );
    }
    // Replace std::chrono::duration with abbriviated version.
    if ( find( function, "std::chrono::duration<" ) != npos ) {
        // clang-format off
        strrep( function, N, "std::chrono::duration<long, std::nano>", "std::chrono::nanoseconds" );
        strrep( function, N, "std::chrono::duration<long, std::micro>", "std::chrono::microseconds" );
        strrep( function, N, "std::chrono::duration<long, std::milli>", "std::chrono::milliseconds" );
        strrep( function, N, "std::chrono::duration<long>", "std::chrono::seconds" );
        strrep( function, N, "std::chrono::duration<long,>", "std::chrono::seconds" );
        strrep( function, N, "std::chrono::duration<long, std::ratio<60>>", "std::chrono::minutes" );
        strrep( function, N, "std::chrono::duration<long, std::ratio<3600>>", "std::chrono::hours" );
        strrep( function, N, " >", ">" );
        strrep( function, N, "< ", "<" );
        // clang-format on
    }
    // Replace std::this_thread::sleep_for with abbriviated version.
    if ( find( function, "::sleep_for<" ) != npos ) {
        strrep( function, N, "::sleep_for<long, std::nano>", "::sleep_for<nanoseconds>" );
        strrep( function, N, "::sleep_for<long, std::micro>", "::sleep_for<microseconds>" );
        strrep( function, N, "::sleep_for<long, std::milli>", "::sleep_for<milliseconds>" );
        strrep( function, N, "::sleep_for<long>", "::sleep_for<seconds>" );
        strrep( function, N, "::sleep_for<long,>", "::sleep_for<seconds>" );
        strrep( function, N, "::sleep_for<long, std::ratio<60>>", "::sleep_for<minutes>" );
        strrep( function, N, "::sleep_for<long, std::ratio<3600>>", "::sleep_for<hours>" );
        strrep( function, N, "::sleep_for<nanoseconds>(std::chrono::nanoseconds",
            "::sleep_for(std::chrono::nanoseconds" );
        strrep( function, N, "::sleep_for<microseconds>(std::chrono::microseconds",
            "::sleep_for(std::chrono::microseconds" );
        strrep( function, N, "::sleep_for<milliseconds>(std::chrono::milliseconds",
            "::sleep_for(std::chrono::milliseconds" );
        strrep( function, N, "::sleep_for<seconds>(std::chrono::seconds",
            "::sleep_for(std::chrono::seconds" );
        strrep( function, N, "::sleep_for<milliseconds>(std::chrono::minutes",
            "::sleep_for(std::chrono::milliseconds" );
        strrep( function, N, "::sleep_for<milliseconds>(std::chrono::hours",
            "::sleep_for(std::chrono::hours" );
    }
    // Replace std::basic_string with abbriviated version
    strrep( function, N, "std::__cxx11::basic_string<", "std::basic_string<" );
    size_t pos = 0;
    while ( pos < N ) {
        // Find next instance of std::basic_string
        pos = find( function, "std::basic_string<", pos );
        if ( pos == npos )
            break;
        // Find the matching >
        size_t pos1 = pos + 17;
        size_t pos2 = findMatching( function, N, pos1 );
        if ( pos2 == pos1 )
            break;
        if ( strncmp( &function[pos1 + 1], "char", 4 ) == 0 )
            N = replace( function, N, pos, pos2 - pos, "std::string" );
        else if ( strncmp( &function[pos1 + 1], "wchar_t", 7 ) == 0 )
            N = replace( function, N, pos, pos2 - pos, "std::wstring" );
        else if ( strncmp( &function[pos1 + 1], "char16_t", 8 ) == 0 )
            N = replace( function, N, pos, pos2 - pos, "std::u16string" );
        else if ( strncmp( &function[pos1 + 1], "char32_t", 8 ) == 0 )
            N = replace( function, N, pos, pos2 - pos, "std::u32string" );
        pos++;
    }
    // Replace std::make_shared with abbriviated version
    if ( find( function, "std::make_shared<" ) != npos ) {
        size_t pos1 = find( function, "std::make_shared<" );
        size_t pos2 = find( function, ",", pos1 );
        size_t pos3 = find( function, "(", pos1 );
        N           = replace( function, N, pos2, pos3 - pos2, ">" );
    }
}
void StackTrace::cleanupStackTrace( multi_stack_info &stack )
{
    auto it           = stack.children.begin();
    const size_t npos = std::string::npos;
    while ( it != stack.children.end() ) {
        string_view object( it->stack.object.data(), it->stack.object.size() );
        string_view function( it->stack.function.data(), it->stack.function.size() );
        string_view filename( it->stack.filename.data(), it->stack.filename.size() );
        bool remove_entry = false;
        // Remove callstack (and all children) for threads that are just contributing
        if ( filename.find( "StackTrace.cpp" ) != npos ) {
            bool test = function.find( "_callstack_signal_handler" ) != npos ||
                        function.find( "getGlobalCallStacks" ) != npos ||
                        function.find( "(" ) == npos;
            if ( test ) {
                it = stack.children.erase( it );
                continue;
            }
        }
        // Remove __libc_start_main
        if ( function.find( "__libc_start_main" ) != npos &&
             filename.find( "libc-start.c" ) != npos )
            remove_entry = true;
        // Remove backtrace_thread
        if ( function.find( "backtrace_thread" ) != npos &&
             filename.find( "StackTrace.cpp" ) != npos )
            remove_entry = true;
        // Remove __restore_rt
        if ( function.find( "__restore_rt" ) != npos && object.find( "libpthread" ) != npos )
            remove_entry = true;
        // Remove std::condition_variable::__wait_until_impl
        if ( function.find( "std::condition_variable::__wait_until_impl" ) != npos &&
             filename == "condition_variable" )
            remove_entry = true;
        // Remove std::function references
        if ( filename == "functional" ) {
            remove_entry = remove_entry || function.find( "std::_Function_handler<" ) != npos;
            remove_entry = remove_entry || function.find( "std::_Bind_simple<" ) != npos;
            remove_entry = remove_entry || function.find( "_M_invoke" ) != npos;
        }
        // Remove std::this_thread::__sleep_for
        if ( function.find( "std::this_thread::__sleep_for(" ) != npos &&
             object.find( "libstdc++" ) != npos )
            remove_entry = true;
        // Remove std::thread::_Impl
        if ( filename == "thread" ) {
            if ( function.find( "std::thread::_Impl<" ) != npos ||
                 function.find( "std::thread::_Invoker<" ) != npos )
                remove_entry = true;
        }
        if ( filename == "invoke.h" ) {
            remove_entry = remove_entry || function.find( "std::__invoke_impl" ) != npos;
            remove_entry = remove_entry || function.find( "std::__invoke_result" ) != npos;
        }
        // Remove pthread internals
        if ( function == "__GI___pthread_timedjoin_ex" )
            remove_entry = true;
        // Remove MPI internal routines
        if ( function == "MPIR_Barrier_impl" || function == "MPIR_Barrier_intra" ||
             function == "MPIC_Sendrecv" )
            remove_entry = true;
        // Remove OpenMPI specific internal routines
        if ( function == "opal_libevent2022_event_set_log_callback" ||
             function == "opal_libevent2022_event_base_loop" )
            remove_entry = true;
        // Remove MATLAB internal routines
        if ( object == "libmwmcr.so" || object == "libmwm_lxe.so" || object == "libmwbridge.so" ||
             object == "libmwiqm.so" )
            remove_entry = true;
        // Remove std::shared_ptr functions
        if ( filename == "shared_ptr.h" ) {
            if ( function.find( "> std::allocate_shared<" ) != npos ||
                 function.find( "std::_Sp_make_shared_tag," ) != npos )
                remove_entry = true;
        }
        if ( filename == "shared_ptr_base.h" )
            remove_entry = true;
        // Remove new_allocator functions
        if ( filename == "new_allocator.h" )
            remove_entry = true;
        // Remove alloc_traits functions
        if ( filename == "alloc_traits.h" )
            remove_entry = true;
        // Remove gthr-default functions
        if ( filename == "gthr-default.h" )
            remove_entry = true;
        // Remove entries with no useful information
        if ( function == "" && filename == "" )
            remove_entry = true;
        // Remove the desired entry
        if ( remove_entry ) {
            if ( it->children.empty() ) {
                it = stack.children.erase( it );
                continue;
            } else if ( it->children.size() == 1 ) {
                *it = it->children[0];
                continue;
            }
        }
        // Cleanup the children
        cleanupStackTrace( *it );
        ++it;
    }
}

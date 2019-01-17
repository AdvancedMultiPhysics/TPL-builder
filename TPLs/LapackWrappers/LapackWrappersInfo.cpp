#include "LapackWrappers.h"
#include "blas_lapack.h"

#include <algorithm>
#include <chrono>
#include <cmath>
#include <complex>
#include <cstdio>
#include <iostream>
#include <limits>
#include <mutex>
#include <random>
#include <string.h>
#include <string>
#include <thread>


// Choose the OS
#if defined( WIN32 ) || defined( _WIN32 ) || defined( WIN64 ) || defined( _WIN64 )
#define WINDOWS
#include <process.h>
#include <stdlib.h>
#include <windows.h>
#else
#define LINUX
#include <pthread.h>
#include <unistd.h>
#endif


// Define macro to handle name mangling
#ifndef FORTRAN_WRAPPER
#if defined( USE_ACML )
#define FORTRAN_WRAPPER( x ) x##_
#elif defined( _WIN32 ) || defined( __hpux ) || defined( USE_MKL )
#define FORTRAN_WRAPPER( x ) x
#elif defined( USE_VECLIB )
#define FORTRAN_WRAPPER( x ) x##_
#elif defined( USE_OPENBLAS )
#define FORTRAN_WRAPPER( x ) x##_
#else
#define FORTRAN_WRAPPER( x ) x##_
#endif
#endif


/*! \def NULL_USE(variable)
 *  \brief    A null use of a variable
 *  \details  A null use of a variable, use to avoid GNU compiler warnings about
 * unused variables.
 *  \param variable  Variable to pretend to use
 */
#define NULL_USE( variable )                 \
    do {                                     \
        if ( 0 ) {                           \
            char *temp = (char *) &variable; \
            temp++;                          \
        }                                    \
    } while ( 0 )


// Function to replace all instances of a string with another
static inline std::string strrep(
    const std::string &in, const std::string &s, const std::string &r )
{
    std::string str( in );
    size_t i = 0;
    while ( i < str.length() ) {
        i = str.find( s, i );
        if ( i == std::string::npos ) {
            break;
        }
        str.replace( i, s.length(), r );
        i += r.length();
    }
    return str;
}


/****************************************************************************
 *  Function to set an environemental variable                               *
 ****************************************************************************/
static void setenv( const char *name, const char *value )
{
    static std::mutex lock;
    lock.lock();
#if defined( WIN32 ) || defined( _WIN32 ) || defined( WIN64 ) || defined( _WIN64 ) || \
    defined( _MSC_VER )
    SetEnvironmentVariable( name, value ) != 0;
#else
    if ( value != nullptr )
        ::setenv( name, value, 1 );
    else
        ::unsetenv( name );
#endif
    lock.unlock();
}


/******************************************************************
 * Set the number of threads to use                                *
 ******************************************************************/
static int setThreads( int N )
{
    int N2 = 0;
#if defined( USE_MKL )
    setenv( "MKL_NUM_THREADS", std::to_string( N ).c_str() );
    N2 = N;
#elif defined( USE_OPENBLAS )
    openblas_set_num_threads( N );
    N2 = openblas_get_num_threads();
#elif defined( USE_MATLAB_LAPACK )
    setenv( "OMP_NUM_THREADS", std::to_string( N ).c_str() );
    setenv( "MKL_NUM_THREADS", std::to_string( N ).c_str() );
    N2 = N;
#endif
    return N2;
}
template<>
int Lapack<float>::set_num_threads( int N )
{
    return setThreads( N );
}
template<>
int Lapack<double>::set_num_threads( int N )
{
    return setThreads( N );
}
static bool disable_threads()
{
    setThreads( 1 );
    return true;
}
bool global_lapack_threads_disabled = disable_threads();


/******************************************************************
 * Get the machine parameters by lamch                             *
 ******************************************************************/
#undef dlamch
template<>
float Lapack<float>::lamch( char cmach )
{
#ifdef USE_ATLAS
    return clapack_dlamch( cmach );
#elif defined( USE_ACML )
    return ::dlamch( cmach );
#elif defined( USE_VECLIB )
    return FORTRAN_WRAPPER(::dlamch )( &cmach );
#elif defined( USE_OPENBLAS )
    return FORTRAN_WRAPPER(::dlamch )( &cmach );
#else
    return FORTRAN_WRAPPER(::dlamch )( &cmach );
#endif
}
template<>
double Lapack<double>::lamch( char cmach )
{
#ifdef USE_ATLAS
    return clapack_dlamch( cmach );
#elif defined( USE_ACML )
    return ::dlamch( cmach );
#elif defined( USE_VECLIB )
    return FORTRAN_WRAPPER(::dlamch )( &cmach );
#elif defined( USE_OPENBLAS )
    return FORTRAN_WRAPPER(::dlamch )( &cmach );
#else
    return FORTRAN_WRAPPER(::dlamch )( &cmach );
#endif
}

/******************************************************************
 * Get the machine parameters by lamch                             *
 ******************************************************************/
template<typename TYPE>
LapackMachineParams Lapack<TYPE>::machineParams()
{
    LapackMachineParams data;
    data.eps   = Lapack<TYPE>::lamch( 'E' );
    data.sfmin = Lapack<TYPE>::lamch( 'S' );
    data.base  = Lapack<TYPE>::lamch( 'B' );
    data.prec  = Lapack<TYPE>::lamch( 'P' );
    data.t     = Lapack<TYPE>::lamch( 'N' );
    data.rnd   = Lapack<TYPE>::lamch( 'R' );
    data.emin  = Lapack<TYPE>::lamch( 'M' );
    data.rmin  = Lapack<TYPE>::lamch( 'U' );
    data.emax  = Lapack<TYPE>::lamch( 'L' );
    data.rmax  = Lapack<TYPE>::lamch( 'O' );
    return data;
}
template LapackMachineParams Lapack<double>::machineParams();
template LapackMachineParams Lapack<float>::machineParams();
std::string LapackMachineParams::print() const
{
    char msg[1000];
    char *tmp = msg;
    tmp += sprintf( tmp, "  eps   = %-13.6e    relative machine precision\n", eps );
    tmp += sprintf( tmp, "  sfmin = %-13.6e    safe minimum\n", sfmin );
    tmp += sprintf( tmp, "  base  = %-11i      base of the machine\n", base );
    tmp += sprintf( tmp, "  prec  = %-13.6e    eps*base\n", prec );
    tmp += sprintf( tmp, "  t     = %-11i      number of digits in the mantissa\n", t );
    tmp += sprintf( tmp, "  rnd   = %-11i      1 when rounding occurs in addition, 0 otherwise\n",
        rnd ? 1 : 0 );
    tmp += sprintf( tmp, "  emin  = %-11i      minimum exponent before underflow\n", emin );
    tmp += sprintf( tmp, "  rmin  = %-13.6e    underflow threshold - base**(emin-1)\n", rmin );
    tmp += sprintf( tmp, "  emax  = %-11i      largest exponent before overflow\n", emax );
    tmp += sprintf( tmp, "  rmax  = %-13.6e    overflow threshold - (base**emax)*(1-eps)\n", rmax );
    return std::string( msg );
}


/******************************************************************
 * Set the vendor string                                           *
 ******************************************************************/
// clang-format off
#ifdef USE_ATLAS
    static constexpr char LapackVendor[] = "ATLAS";
#elif defined( USE_ACML )
    static constexpr char LapackVendor[] = "ACML";
#elif defined( USE_MKL )
    static constexpr char LapackVendor[] = "MKL";
#elif defined( USE_MATLAB_LAPACK )
    static constexpr char LapackVendor[] = "MATLAB LAPACK";
#elif defined( USE_VECLIB )
    static constexpr char LapackVendor[] = "VECLIB";
#elif defined( USE_OPENBLAS )
    static constexpr char LapackVendor[] = "OpenBLAS";
#else
    static constexpr char LapackVendor[] = "Unknown";
#endif
// clang-format on


/******************************************************************
 * Print the lapack information                                    *
 ******************************************************************/
template<typename TYPE>
std::string Lapack<TYPE>::info()
{
    // Print the vendor info
    std::string msg( LapackVendor );
    msg += "\n";
    // Use vendor-specific utility functions
#ifdef USE_OPENBLAS
    msg += "  " + std::string( openblas_get_config() );
#endif
    // Get vendor specific output (capture stdout)
    fflush( stdout ); // clean everything first
    char buffer[2048];
    memset( buffer, 0, sizeof( buffer ) );
    auto out = dup( STDOUT_FILENO );
    auto tmp = freopen( "NUL", "a", stdout );
    NULL_USE( tmp );
    setvbuf( stdout, buffer, _IOFBF, 2048 );
#ifdef USE_ACML
    acmlinfo();
#endif
    tmp = freopen( "NUL", "a", stdout );
    NULL_USE( tmp );
    dup2( out, STDOUT_FILENO );
    setvbuf( stdout, NULL, _IONBF, 2048 );
    msg += "  " + strrep( buffer, "\n", "\n  " );
    while ( !msg.empty() ) {
        char tmp = msg.back();
        if ( tmp > 32 && tmp != ' ' )
            break;
        msg.pop_back();
    }
    msg += "\n";
    // Print the machine specific parameters
    msg += "Double precision machine parameters\n";
    msg += Lapack<double>::machineParams().print();
    msg += "Single precision machine parameters\n";
    msg += Lapack<float>::machineParams().print();
    return msg;
}
template std::string Lapack<double>::info();
template std::string Lapack<float>::info();

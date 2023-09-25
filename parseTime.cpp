#include <algorithm>
#include <fstream>
#include <iostream>
#include <stdio.h>
#include <stdlib.h>
#include <vector>


std::string deblank( const std::string &str )
{
    if ( str.empty() )
        return std::string();
    int i1 = 0, i2 = str.size() - 1;
    for ( ; i1 < (int) str.size() && ( str[i1] == ' ' || str[i1] == '\t' || str[i1] == '"' );
          i1++ ) {}
    for ( ; i2 > 0 && ( str[i2] == ' ' || str[i2] == '\t' || str[i2] == '\r' || str[i2] == '"' );
          i2-- ) {}
    if ( i2 == 0 && ( str[i2] == ' ' || str[i2] == '\t' || str[i2] == '\r' || str[i2] == '"' ) )
        return std::string();
    return str.substr( i1, i2 - i1 + 1 );
}


struct DataStruct {
    std::string target;
    std::string command;
    float user            = 0;  // User time in s
    float system          = 0;  // System time in s
    float CPU             = 0;  // Percent of CPU this job got
    std::string wall      = ""; // Elapsed (wall clock) time (h:mm:ss or m:ss)
    int textSize          = 0;  // Average shared text size (kbytes)
    int unsharedSize      = 0;  // Average unshared data size (kbytes)
    int stackSize         = 0;  // Average stack size (kbytes)
    int totalSize         = 0;  // Average total size (kbytes)
    int maxResigentSize   = 0;  // Maximum resident set size (kbytes)
    int avgResigentSize   = 0;  // Average resident set size (kbytes)
    int majorPageFaults   = 0;  // Major (requiring I/O) page faults
    int minorPageFaults   = 0;  // Minor (reclaiming a frame) page faults
    int voluntarySwitch   = 0;  // Voluntary context switches
    int involuntarySwitch = 0;  // Involuntary context switches
    int swaps             = 0;  // Swaps
    int fileSystemInputs  = 0;  // File system inputs
    int fileSystemOutputs = 0;  // File system outputs
    int messagesSent      = 0;  // Socket messages sent
    int messagesRecieved  = 0;  // Socket messages received
    int signals           = 0;  // Signals delivered
    int pageSize          = 0;  // Page size (bytes)
    int exit              = 0;  // Exit status
    bool operator<( const DataStruct &rhs ) { return command < rhs.command; }
    bool operator>( const DataStruct &rhs ) { return command > rhs.command; }
    bool operator<=( const DataStruct &rhs ) { return command <= rhs.command; }
    bool operator>=( const DataStruct &rhs ) { return command >= rhs.command; }
    bool operator==( const DataStruct &rhs ) { return command == rhs.command; }
    bool operator!=( const DataStruct &rhs ) { return command != rhs.command; }
    DataStruct( const std::string cmd ) : command( cmd )
    {
        if ( cmd.find( " -c " ) != std::string::npos ) {
            target = deblank( cmd.substr( cmd.rfind( " -c " ) + 4 ) );
        } else if ( cmd.find( " -o " ) != std::string::npos ) {
            target = deblank( cmd.substr( cmd.rfind( " -o " ) + 4 ) );
            target = deblank( target.substr( 0, target.find( ' ' ) ) );
        } else {
            target = command;
        }
    }
};


template<class TYPE>
void store( const std::string &line, const std::string &field, TYPE &data )
{
    size_t pos = line.find( field );
    if ( pos != std::string::npos ) {
        pos += field.size();
        auto tmp = deblank( line.substr( pos ) );
        if constexpr ( std::is_same_v<TYPE, int> ) {
            data = atoi( tmp.data() );
        } else if constexpr ( std::is_same_v<TYPE, float> ) {
            data = atof( tmp.data() );
        } else if constexpr ( std::is_same_v<TYPE, std::string> ) {
            data = tmp;
        }
    }
}


int main( int argc, const char *argv[] )
{
    if ( argc < 2 ) {
        std::cerr << "parseTime <logfile> <paths>\n";
        return 1;
    }

    // Open input file
    std::ifstream input( argv[1] );
    if ( !input ) {
        std::cerr << "Error opening logfile\n";
        return 1;
    }

    // Read data
    std::string line;
    std::vector<DataStruct> data;
    DataStruct *current = nullptr;
    while ( getline( input, line ) ) {
        line = deblank( line );
        if ( line.empty() )
            continue;
        if ( line.find( "Command being timed:" ) != std::string::npos ) {
            auto command = deblank( line.substr( line.find( ':' ) + 1 ) );
            auto it      = std::find_if( data.begin(), data.end(),
                [command]( const DataStruct &x ) { return x.command == command; } );
            if ( it == data.end() )
                it = data.insert( data.end(), DataStruct( command ) );
            current = &( *it );
        } else {
            store( line, "User time (seconds):", current->user );
            store( line, "System time (seconds):", current->system );
            store( line, "Percent of CPU this job got:", current->CPU );
            store( line, "Elapsed (wall clock) time (h:mm:ss or m:ss):", current->wall );
            store( line, "Average shared text size (kbytes):", current->textSize );
            store( line, "Average unshared data size (kbytes):", current->unsharedSize );
            store( line, "Average stack size (kbytes):", current->stackSize );
            store( line, "Average total size (kbytes):", current->totalSize );
            store( line, "Maximum resident set size (kbytes):", current->maxResigentSize );
            store( line, "Average resident set size (kbytes):", current->avgResigentSize );
            store( line, "Major (requiring I/O) page faults:", current->majorPageFaults );
            store( line, "Minor (reclaiming a frame) page faults:", current->minorPageFaults );
            store( line, "Voluntary context switches:", current->voluntarySwitch );
            store( line, "Involuntary context switches:", current->involuntarySwitch );
            store( line, "Swaps:", current->swaps );
            store( line, "File system inputs:", current->fileSystemInputs );
            store( line, "File system outputs:", current->fileSystemOutputs );
            store( line, "Socket messages sent:", current->messagesSent );
            store( line, "Socket messages received:", current->messagesRecieved );
            store( line, "Signals delivered:", current->signals );
            store( line, "Page size (bytes):", current->pageSize );
            store( line, "Exit status:", current->exit );
        }
    }
    input.close();

    // Remove path from target
    for ( size_t k = 2; k < argc; k++ ) {
        std::string path = argv[k];
        if ( path.back() == '/' )
            path.resize( path.size() - 1 );
        for ( auto &tmp : data ) {
            if ( tmp.target.find( path ) == 0 )
                tmp.target = tmp.target.substr( path.size() + 1 );
        }
    }

    // Sort the data by time (longest first)
    std::sort( data.begin(), data.end(), []( auto x, auto y ) { return y.user < x.user; } );
    std::cout << data.size() << " items loaded\n";
    for ( int i = 0; i < std::min<int>( 100, data.size() ); i++ ) {
        printf( "%6.1f - %s\n", data[i].user, data[i].target.data() );
    }

    // Finished
    return 0;
}

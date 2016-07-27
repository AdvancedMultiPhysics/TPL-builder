#include "LapackWrappers.h"

#include <thread>
#include <iostream>
#include <stdio.h>
#include <stdlib.h>
#include <time.h>


// Detect the OS and include system dependent headers
#if defined( WIN32 ) || defined( _WIN32 ) || defined( WIN64 ) || defined( _WIN64 ) || defined( _MSC_VER )
#define USE_WINDOWS
#define NOMINMAX
// clang-format off
#include <windows.h>
#include <process.h>
#include <psapi.h>
#include <tchar.h>
// clang-format on
#elif defined( __APPLE__ )
#define USE_MAC
#include <cxxabi.h>
#include <dlfcn.h>
#include <execinfo.h>
#include <mach/mach.h>
#include <stdint.h>
#include <sys/sysctl.h>
#include <sys/time.h>
#include <sys/types.h>
#include <unistd.h>
#elif defined( __linux ) || defined( __unix ) || defined( __posix )
#define USE_LINUX
#define USE_NM
#include <dlfcn.h>
#include <execinfo.h>
#include <malloc.h>
#include <sys/time.h>
#include <unistd.h>
#else
#error Unknown OS
#endif


// Get the current time for timming the code
double time()
{
    #if defined( USE_WINDOWS )
        LARGE_INTEGER end, f;
        QueryPerformanceFrequency( &f );
        QueryPerformanceCounter( &end );
        double time = ( (double) end.QuadPart ) / ( (double) f.QuadPart );
        return time;
    #elif defined( USE_LINUX ) || defined( USE_MAC )
        timeval current_time;
        gettimeofday( &current_time, nullptr );
        double time = ( (double) current_time.tv_sec ) + 1e-6 * ( (double) current_time.tv_usec );
        return time;
    #else
    #error Unknown OS
    #endif
}


// Call Lapack::run_test
void run_test( const char *routine, int N, int& N_errors, double &error )
{
    N_errors = Lapack::run_test( routine, N, error );
}


// The main function
int main( int, char *[] )
{
    int N_errors = 0;

    // Print the machine specifics
    Lapack::print_machine_parameters();

    // Run the basic tests
    printf( "\nRunning basic tests\n" );
    N_errors += Lapack::run_all_test();
    if ( N_errors == 0 ) {
        printf( "  passed\n" );
    }

    // Get the times for the tests
    printf( "\nGetting test times\n" );
    const char *tests[] = { "dcopy", "dscal", "dnrm2", "dasum", "ddot", "daxpy", "dgemv", "dgemm",
        "dgesv", "dgtsv", "dgbsv", "dgetrf", "dgttrf", "dgbtrf", "dgetrs", "dgttrs", "dgbtrs",
        "dgetri" };
    const int N[] = { 500, 500, 500, 500, 500, 100, 100, 100, 100, 500, 500, 100, 500, 500, 100,
        500, 500, 100 };
    for ( size_t i = 0; i < sizeof( tests ) / sizeof( char * ); i++ ) {
        double t1    = time();
        double error = 0;
        int err      = Lapack::run_test( tests[i], N[i], error );
        double t2    = time();
        int us       = static_cast<int>( 1e6 * ( t2 - t1 ) / N[i] );
        printf( "%7s:  %s:  %5i us  (%e)\n", tests[i], err == 0 ? "passed" : "failed", us, error );
        N_errors += err;
    }

    // Run the tests in parallel to check for parallel bugs
    printf( "\nRunning parallel tests\n" );
    int N_threads = 8;
    for ( size_t i = 0; i < sizeof( tests ) / sizeof( char * ); i++ ) {
        double t1 = time();
        std::thread threads[128];
        int N_errors_thread[128];
        double error_thread[128];
        for ( int j = 0; j < N_threads; j++ )
            threads[j] = std::thread( run_test, tests[i], N[i], std::ref(N_errors_thread[j]), std::ref(error_thread[j]) );
        for ( int j = 0; j < N_threads; j++ )
            threads[j].join();
        double t2 = time();
        bool pass = true;
        for ( int j = 0; j < N_threads; j++ )
            pass = pass && N_errors_thread[j] == 0;
        int us   = static_cast<int>( 1e6 * ( t2 - t1 ) / ( N[i] * N_threads ) );
        printf( "%7s:  %s:  %5i us\n", tests[i], pass ? "passed" : "failed", us );
        N_errors += ( pass ? 0 : 1 );
    }


    // Finished
    if ( N_errors == 0 )
        std::cout << "\nAll tests passed\n";
    else
        std::cout << "\nSome tests failed\n";
    return N_errors == 0 ? 0 : 1;
}

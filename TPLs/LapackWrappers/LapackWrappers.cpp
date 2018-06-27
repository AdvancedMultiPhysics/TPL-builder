#define NOMINMAX
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


// Define some sizes of the problems (try to normalize the time/test)
#define TEST_SIZE_VEC 50000    // Vector tests O(N)
#define TEST_SIZE_MATVEC 500   // Matrix-vector tests O(N^2)
#define TEST_SIZE_MAT 100      // Matrix-matrix / Dense solves tests O(N^3)
#define TEST_SIZE_TRI 2000     // Tridiagonal/banded tests
#define TEST_SIZE_TRI_MAT 1000 // Tridiagonal/banded solve tests


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


// Disable BLAS/LAPACK threads
static bool disable_threads()
{
    char MKL_ENV[] = "MKL_NUM_THREADS=1";
    putenv( MKL_ENV );
#ifdef USE_OPENBLAS
    openblas_set_num_threads( 1 );
#endif
    return true;
}
bool global_lapack_threads_disabled = disable_threads();


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


// Choose precision to perfom calculations
template<class TYPE>
class extended
{
};
template<>
class extended<float>
{
public:
    typedef double TYPE2;
};
template<>
class extended<double>
{
public:
    typedef long double TYPE2;
};
template<>
class extended<std::complex<float>>
{
public:
    typedef std::complex<double> TYPE2;
};
template<>
class extended<std::complex<double>>
{
public:
    typedef std::complex<long double> TYPE2;
};


// Lists the tests availible to run
template<>
std::vector<std::string> Lapack<double>::list_all_tests()
{
    return { "dcopy", "dscal", "dnrm2", "daxpy", "dgemv", "dgemm", "dasum", "ddot", "dgesv",
        "dgtsv", "dgbsv", "dgetrf", "dgttrf", "dgbtrf", "dgetrs", "dgttrs", "dgetri", "drand" };
}
template<>
std::vector<std::string> Lapack<float>::list_all_tests()
{
    return { "scopy", "sscal", "snrm2", "saxpy", "sgemv", "sgemm", "sasum", "sdot", "sgesv",
        "sgtsv", "sgbsv", "sgetrf", "sgttrf", "sgbtrf", "sgetrs", "sgttrs", "sgetri", "srand" };
}


// Run all the tests
template<typename TYPE>
int Lapack<TYPE>::run_all_test()
{
    int N_errors = 0;
    int N        = 2; // We want two iterations to enure the test works for N>1
    auto tests   = Lapack<TYPE>::list_all_tests();
    for ( auto test : tests ) {
        TYPE error;
        int err = Lapack<TYPE>::run_test( test, N, error );
        if ( err != 0 ) {
            printf( "test_%s failed (%e)\n", test.c_str(), error );
            N_errors++;
        }
    }
    return N_errors;
}
template int Lapack<double>::run_all_test();
template int Lapack<float>::run_all_test();


// Fill a vector with random TYPE precision data
template<>
void Lapack<float>::random( int N, float *data )
{
    static std::mutex lock;
    static std::random_device rd;
    static std::mt19937 gen( rd() );
    static std::uniform_real_distribution<float> dis( 0, 1 );
    lock.lock();
    for ( int i = 0; i < N; i++ )
        data[i] = dis( gen );
    lock.unlock();
}
template<>
void Lapack<double>::random( int N, double *data )
{
    static std::mutex lock;
    static std::random_device rd;
    static std::mt19937_64 gen( rd() );
    static std::uniform_real_distribution<double> dis( 0, 1 );
    lock.lock();
    for ( int i = 0; i < N; i++ )
        data[i] = dis( gen );
    lock.unlock();
}


// Check if two vectors are approximately equal
template<typename TYPE>
static inline bool approx_equal( int N, const TYPE *x1, const TYPE *x2, const TYPE tol = 1e-12 )
{
    bool pass = true;
    for ( int i = 0; i < N; i++ )
        pass = pass && fabs( x1[i] - x2[i] ) <= tol * 0.5 * fabs( x1[i] + x2[i] );
    return pass;
}


// Return the L2 error
template<typename TYPE>
static inline TYPE L2Error( int N, const TYPE *x1, const TYPE *x2 )
{
    TYPE norm = 0.0;
    for ( int i = 0; i < N; i++ )
        norm += ( x1[i] - x2[i] ) * ( x1[i] - x2[i] );
    return sqrt( norm );
}


// Generate a matrix/rhs
template<typename TYPE>
void generateRhs( int N, TYPE *x )
{
    Lapack<TYPE>::random( N, x );
}
template<typename TYPE>
void generateMatrix( int N, TYPE *A )
{
    Lapack<TYPE>::random( N * N, A );
    for ( int i = 0; i < N; i++ ) {
        double d     = A[i + i * N];
        A[i + i * N] = 0;
        A[i + i * N] = d - Lapack<TYPE>::asum( N, &A[i * N], 1 );
    }
}
template<typename TYPE>
void generateMatrixBanded( int N, int KL, int KU, TYPE *A )
{
    for ( int i = 0; i < N * N; i++ )
        A[i] = 0;
    for ( int i = 0; i < N; i++ ) {
        int K1 = std::max( i - KL, 0 );
        int K2 = std::min( i + KU, N - 1 );
        Lapack<TYPE>::random( K2 - K1 + 1, &A[K1 + i * N] );
        double d     = A[i + i * N];
        A[i + i * N] = 0;
        A[i + i * N] = d - Lapack<TYPE>::asum( K2 - K1 + 1, &A[K1 + i * N], 1 );
    }
}
template<typename TYPE>
void generateTriDiag( int N, TYPE *DL, TYPE *D, TYPE *DU )
{
    Lapack<TYPE>::random( N - 1, DL );
    Lapack<TYPE>::random( N - 1, DU );
    Lapack<TYPE>::random( N, D );
    D[0] -= DL[0];
    for ( int i = 1; i < N - 1; i++ )
        D[i] -= DL[i] + DU[i - 1];
    D[N - 1] -= DU[N - 2];
}
template<typename TYPE>
void extractBanded( int N, int KL, int KU, const TYPE *A, TYPE *AB )
{
    const int K2 = 2 * KL + KU + 1;
    for ( int k = 0; k < N; k++ ) {
        for ( int k2 = -KL; k2 <= KU; k2++ ) {
            if ( k + k2 < 0 || k + k2 >= N )
                continue;
            AB[k2 + 2 * KL + k * K2] = A[k + k2 + k * N];
        }
    }
}
template<typename TYPE>
void extractTriDiag( int N, const TYPE *A, TYPE *DL, TYPE *D, TYPE *DU )
{
    D[0] = A[0];
    for ( int k = 1; k < N; k++ ) {
        D[k]      = A[k + k * N];
        DU[k - 1] = A[( k - 1 ) + k * N];
        DL[k - 1] = A[k + ( k - 1 ) * N];
    }
}


// Test random
template<typename TYPE>
static bool test_random( int N, TYPE &error )
{
    constexpr int Nb = 25; // NUmber of bins
    int K            = TEST_SIZE_VEC / 8;
    TYPE *x          = new TYPE[K];
    int count[Nb]    = { 0 };
    error            = 0;
    for ( int it = 0; it < N; it++ ) {
        Lapack<TYPE>::random( K, x );
        TYPE sum = 0;
        for ( int i = 0; i < K; i++ ) {
            error = ( error == 0 && x[i] < 0 ) ? -1 : error;
            error = ( error == 0 && x[i] > 1 ) ? -2 : error;
            sum += x[i];
            int j = static_cast<int>( floor( x[i] * Nb ) );
            count[j]++;
        }
        TYPE avg = sum / K;
        if ( error == 0 && ( avg < 0.35 || avg > 0.65 ) )
            error = -3;
    }
    delete[] x;
    if ( error != 0 )
        return true;
    // If we did not encounter an error, check the Chi-Square Distribution
    double E  = ( K * N ) / static_cast<double>( Nb );
    double X2 = 0.0;
    for ( int i = 0; i < Nb; i++ )
        X2 += ( count[i] - E ) * ( count[i] - E ) / E;
    double X2c = 52.6; // Critical value for 0.999 (we will fail 0.1% of the time)
    error      = X2 / X2c;
    return error > 1.0;
}


// Test copy
template<typename TYPE>
static bool test_copy( int N, TYPE &error )
{
    const int K = TEST_SIZE_VEC;
    TYPE *x1    = new TYPE[K];
    TYPE *x2    = new TYPE[K];
    Lapack<TYPE>::random( K, x1 );
    int N_errors = 0;
    error        = 0;
    for ( int i = 0; i < N; i++ ) {
        memset( x2, 0xB6, K * sizeof( TYPE ) );
        Lapack<TYPE>::copy( K, x1, 1, x2, 1 );
        if ( !approx_equal( K, x1, x2 ) )
            N_errors++;
    }
    delete[] x1;
    delete[] x2;
    return N_errors > 0;
}


// Test scal
template<typename TYPE>
static bool test_scal( int N, TYPE &error )
{
    const int K = TEST_SIZE_VEC;
    TYPE *x0    = new TYPE[K];
    TYPE *x1    = new TYPE[K];
    TYPE *x2    = new TYPE[K];
    Lapack<TYPE>::random( K, x0 );
    const TYPE pi = static_cast<TYPE>( 3.141592653589793 );
    for ( int j = 0; j < K; j++ )
        x1[j] = pi * x0[j];
    int N_errors = 0;
    error        = 0;
    for ( int i = 0; i < N; i++ ) {
        memcpy( x2, x1, K * sizeof( TYPE ) );
        Lapack<TYPE>::scal( K, pi, x0, 1 );
        if ( !approx_equal( K, x1, x2, 10 * std::numeric_limits<TYPE>::epsilon() ) )
            N_errors++;
    }
    delete[] x0;
    delete[] x1;
    delete[] x2;
    return N_errors > 0;
}

// Test nrm2
template<typename TYPE>
static bool test_nrm2( int N, TYPE &error )
{
    typedef typename extended<TYPE>::TYPE2 TYPE2;
    const int K = TEST_SIZE_VEC;
    TYPE *x     = new TYPE[K];
    Lapack<TYPE>::random( K, x );
    TYPE2 ans1 = 0.0;
    for ( int j = 0; j < K; j++ )
        ans1 += static_cast<TYPE>( x[j] ) * static_cast<TYPE>( x[j] );
    ans1         = sqrt( ans1 );
    int N_errors = 0;
    error        = 0;
    for ( int i = 0; i < N; i++ ) {
        TYPE ans2  = Lapack<TYPE>::nrm2( K, x, 1 );
        double err = std::abs( ans1 - ans2 ) / sqrt( K );
        error      = std::max<TYPE>( error, err );
        if ( err > 50 * std::numeric_limits<TYPE>::epsilon() )
            N_errors++;
    }
    delete[] x;
    return N_errors > 0;
}

// Test asum
template<typename TYPE>
static bool test_asum( int N, TYPE &error )
{
    typedef typename extended<TYPE>::TYPE2 TYPE2;
    const int K = 2 * TEST_SIZE_VEC;
    // Create a random set of numbers and the sum (simple method)
    TYPE *x = new TYPE[K];
    Lapack<TYPE>::random( K, x );
    TYPE2 sum = 0.0;
    for ( int j = 0; j < K; j++ )
        sum += std::abs( x[j] );
    TYPE ans1 = sum;
    // Check asum
    int N_errors = 0;
    error        = 0;
    for ( int i = 0; i < N; i++ ) {
        TYPE ans2  = Lapack<TYPE>::asum( K, x, 1 );
        double err = std::abs( ans1 - ans2 ) / K;
        error      = std::max<TYPE>( error, err );
        if ( err > 100 * std::numeric_limits<TYPE>::epsilon() )
            N_errors++;
    }
    delete[] x;
    return N_errors > 0;
}

// Test dot
template<typename TYPE>
static bool test_dot( int N, TYPE &error )
{
    typedef typename extended<TYPE>::TYPE2 TYPE2;
    const int K = TEST_SIZE_VEC;
    TYPE *x1    = new TYPE[K];
    TYPE *x2    = new TYPE[K];
    Lapack<TYPE>::random( K, x1 );
    Lapack<TYPE>::random( K, x2 );
    TYPE2 ans1 = 0.0;
    for ( int j = 0; j < K; j++ )
        ans1 += static_cast<TYPE2>( x1[j] ) * static_cast<TYPE2>( x2[j] );
    int N_errors = 0;
    error        = 0;
    for ( int i = 0; i < N; i++ ) {
        TYPE ans2  = Lapack<TYPE>::dot( K, x1, 1, x2, 1 );
        double err = std::abs( ans1 - ans2 ) / K;
        error      = std::max<TYPE>( error, err );
        if ( err > 50 * std::numeric_limits<TYPE>::epsilon() )
            N_errors++;
    }
    delete[] x1;
    delete[] x2;
    return N_errors > 0;
}

// Test axpy
template<typename TYPE>
static bool test_axpy( int N, TYPE &error )
{
    const int K = TEST_SIZE_VEC;
    TYPE *x     = new TYPE[K];
    TYPE *y0    = new TYPE[K];
    TYPE *y1    = new TYPE[K];
    TYPE *y2    = new TYPE[K];
    Lapack<TYPE>::random( K, x );
    Lapack<TYPE>::random( K, y0 );
    const TYPE pi = static_cast<TYPE>( 3.141592653589793 );
    for ( int j = 0; j < K; j++ )
        y1[j] = y0[j] + pi * x[j];
    error = 0;
    for ( int i = 0; i < N; i++ ) {
        memcpy( y2, y0, K * sizeof( TYPE ) );
        Lapack<TYPE>::axpy( K, pi, x, 1, y2, 1 );
        TYPE err = L2Error( K, y1, y2 );
        error    = std::max( error, err );
    }
    bool fail = error > 200 * std::numeric_limits<TYPE>::epsilon();
    NULL_USE( y1 );
    delete[] x;
    delete[] y0;
    delete[] y1;
    delete[] y2;
    return fail;
}

// Test gemv
template<typename TYPE>
static bool test_gemv( int N, TYPE &error )
{
    const int K = TEST_SIZE_MATVEC;
    TYPE *A     = new TYPE[K * K];
    TYPE *x     = new TYPE[K];
    TYPE *y     = new TYPE[K];
    TYPE *y1    = new TYPE[K];
    TYPE *y2    = new TYPE[K];
    Lapack<TYPE>::random( K * K, A );
    Lapack<TYPE>::random( K, x );
    Lapack<TYPE>::random( K, y );
    const TYPE alpha = static_cast<TYPE>( 3.141592653589793 );
    const TYPE beta  = static_cast<TYPE>( 1.414213562373095 );
    for ( int j = 0; j < K; j++ ) {
        y1[j] = beta * y[j];
        for ( int k = 0; k < K; k++ )
            y1[j] += alpha * A[j + k * K] * x[k];
    }
    int N_errors = 0;
    error        = 0;
    TYPE norm    = Lapack<TYPE>::nrm2( K, y1, 1 );
    for ( int i = 0; i < N; i++ ) {
        memcpy( y2, y, K * sizeof( TYPE ) );
        Lapack<TYPE>::gemv( 'N', K, K, alpha, A, K, x, 1, beta, y2, 1 );
        error = std::max( error, L2Error( K, y1, y2 ) / norm );
        if ( !approx_equal( K, y1, y2, K * std::numeric_limits<TYPE>::epsilon() ) )
            N_errors++;
    }
    delete[] A;
    delete[] x;
    delete[] y;
    delete[] y1;
    delete[] y2;
    return N_errors > 0;
}

// Test gemm
template<typename TYPE>
static bool test_gemm( int N, TYPE &error )
{
    const int K = TEST_SIZE_MAT;
    TYPE *A     = new TYPE[K * K];
    TYPE *B     = new TYPE[K * K];
    TYPE *C     = new TYPE[K * K];
    TYPE *C1    = new TYPE[K * K];
    TYPE *C2    = new TYPE[K * K];
    Lapack<TYPE>::random( K * K, A );
    Lapack<TYPE>::random( K * K, B );
    Lapack<TYPE>::random( K * K, C );
    const TYPE alpha = static_cast<TYPE>( 3.141592653589793 );
    const TYPE beta  = static_cast<TYPE>( 1.414213562373095 );
    for ( int i = 0; i < K; i++ ) {
        for ( int j = 0; j < K; j++ ) {
            C1[i + j * K] = beta * C[i + j * K];
            for ( int k = 0; k < K; k++ )
                C1[i + j * K] += alpha * A[i + k * K] * B[k + j * K];
        }
    }
    int N_errors = 0;
    error        = 0;
    TYPE norm    = Lapack<TYPE>::nrm2( K * K, C1, 1 );
    for ( int i = 0; i < N; i++ ) {
        memcpy( C2, C, K * K * sizeof( TYPE ) );
        Lapack<TYPE>::gemm( 'N', 'N', K, K, K, alpha, A, K, B, K, beta, C2, K );
        error = std::max( error, L2Error( K * K, C1, C2 ) / norm );
        if ( !approx_equal( K * K, C1, C2, K * 10 * std::numeric_limits<TYPE>::epsilon() ) )
            N_errors++;
    }
    delete[] A;
    delete[] B;
    delete[] C;
    delete[] C1;
    delete[] C2;
    return N_errors > 0;
}

// Test gesv
template<typename TYPE>
static bool test_gesv( int N, TYPE &error )
{
    // Test solving a diagonal matrix
    const int K = TEST_SIZE_MAT;
    TYPE *A     = new TYPE[K * K];
    TYPE *x1    = new TYPE[K];
    TYPE *x2    = new TYPE[K];
    TYPE *b     = new TYPE[K];
    int *IPIV   = new int[K];
    memset( A, 0, K * K * sizeof( TYPE ) );
    Lapack<TYPE>::random( K, x2 );
    Lapack<TYPE>::random( K, b );
    for ( int k = 0; k < K; k++ ) {
        A[k + k * K] = x2[k] + std::numeric_limits<TYPE>::epsilon();
        x1[k]        = b[k] / ( x2[k] + std::numeric_limits<TYPE>::epsilon() );
    }
    int N_errors = 0;
    error        = 0;
    TYPE norm    = Lapack<TYPE>::nrm2( K, x1, 1 );
    for ( int i = 0; i < N; i++ ) {
        memcpy( x2, b, K * sizeof( TYPE ) );
        int err = 0;
        Lapack<TYPE>::gesv( K, 1, A, K, IPIV, x2, K, err );
        N_errors += err == 0 ? 0 : 1;
        error = std::max( error, L2Error( K, x1, x2 ) / norm );
        if ( !approx_equal( K, x1, x2, K * 10 * std::numeric_limits<TYPE>::epsilon() ) )
            N_errors++;
    }
    delete[] A;
    delete[] x1;
    delete[] x2;
    delete[] b;
    delete[] IPIV;
    return N_errors > 0;
}

// Test gtsv
template<typename TYPE>
static bool test_gtsv( int N, TYPE &error )
{
    // Test solving a tri-diagonal matrix by comparing to dgtsv
    const int K = TEST_SIZE_TRI_MAT / 2;
    TYPE *A     = new TYPE[K * K];
    TYPE *D     = new TYPE[K];
    TYPE *D2    = new TYPE[K];
    TYPE *DL    = new TYPE[K - 1];
    TYPE *DL2   = new TYPE[K - 1];
    TYPE *DU    = new TYPE[K - 1];
    TYPE *DU2   = new TYPE[K - 1];
    TYPE *x1    = new TYPE[K];
    TYPE *x2    = new TYPE[K];
    TYPE *b     = new TYPE[K];
    int *IPIV   = new int[K];
    generateRhs( K, b );
    generateMatrixBanded( K, 1, 1, A );
    extractTriDiag( K, A, DL, D, DU );
    memcpy( x1, b, K * sizeof( TYPE ) );
    int err = 0;
    Lapack<TYPE>::gesv( K, 1, A, K, IPIV, x1, K, err );
    int N_errors = 0;
    error        = 0;
    for ( int i = 0; i < N; i++ ) {
        memcpy( x2, b, K * sizeof( TYPE ) );
        memcpy( D2, D, K * sizeof( TYPE ) );
        memcpy( DL2, DL, ( K - 1 ) * sizeof( TYPE ) );
        memcpy( DU2, DU, ( K - 1 ) * sizeof( TYPE ) );
        Lapack<TYPE>::gtsv( K, 1, DL2, D2, DU2, x2, K, err );
        N_errors += err == 0 ? 0 : 1;
        if ( err != 0 )
            printf( "Error calling gtsv (%i)\n", err );
        TYPE err2 = L2Error( N, x1, x2 );
        TYPE norm = Lapack<TYPE>::nrm2( N, x1, 1 );
        error     = std::max( error, err2 / norm );
    }
    const TYPE tol = static_cast<TYPE>( 2e4 ) * std::numeric_limits<TYPE>::epsilon();
    if ( error > tol ) {
        printf( "test_gtsv error (%e) exceeded tolerance (%e)\n", error, tol );
        N_errors++;
    }
    delete[] A;
    delete[] D;
    delete[] D2;
    delete[] DL;
    delete[] DL2;
    delete[] DU;
    delete[] DU2;
    delete[] x1;
    delete[] x2;
    delete[] b;
    delete[] IPIV;
    return N_errors > 0;
}
// Test gbsv
template<typename TYPE>
static bool test_gbsv( int N, TYPE &error )
{
    // Test solving a banded-diagonal matrix by comparing to dgtsv
    //    N = 6, KL = 2, KU = 1:
    //        *    *    *    +    +    +
    //        *    *    +    +    +    +
    //        *   a12  a23  a34  a45  a56
    //       a11  a22  a33  a44  a55  a66
    //       a21  a32  a43  a54  a65   *
    //       a31  a42  a53  a64   *    *
    const int K  = TEST_SIZE_TRI_MAT / 2;
    const int KL = 2;
    const int KU = 2;
    const int K2 = 2 * KL + KU + 1;
    TYPE *A      = new TYPE[K * K];
    TYPE *AB     = new TYPE[K * K2];
    TYPE *AB2    = new TYPE[K * K2];
    TYPE *x1     = new TYPE[K];
    TYPE *x2     = new TYPE[K];
    TYPE *b      = new TYPE[K];
    int *IPIV    = new int[K];
    generateRhs( K, b );
    generateMatrixBanded( K, KL, KU, A );
    extractBanded( K, KL, KU, A, AB );
    memcpy( x1, b, K * sizeof( TYPE ) );
    int err = 0;
    error   = 0;
    Lapack<TYPE>::gesv( K, 1, A, K, IPIV, x1, K, err );
    int N_errors = 0;
    for ( int i = 0; i < N; i++ ) {
        memcpy( x2, b, K * sizeof( TYPE ) );
        memcpy( AB2, AB, K * K2 * sizeof( TYPE ) );
        Lapack<TYPE>::gbsv( K, KL, KU, 1, AB2, K2, IPIV, x2, K, err );
        N_errors += err == 0 ? 0 : 1;
        TYPE norm = Lapack<TYPE>::nrm2( K, x1, 1 );
        TYPE err2 = L2Error( K, x1, x2 );
        error     = std::max( error, err2 / norm );
    }
    const double tol = 500 * sqrt( K ) * std::numeric_limits<TYPE>::epsilon();
    if ( error > tol ) {
        printf( "test_gbsv error (%e) exceeded tolerance (%e)\n", error, tol );
        N_errors++;
    }
    delete[] A;
    delete[] AB;
    delete[] AB2;
    delete[] x1;
    delete[] x2;
    delete[] b;
    delete[] IPIV;
    return N_errors > 0;
}

// Test getrf
template<typename TYPE>
static bool test_getrf( int N, TYPE &error )
{
    // Check dgetrf by performing a factorization and solve and comparing to dgesv
    const int K = TEST_SIZE_MAT;
    TYPE *A     = new TYPE[K * K];
    TYPE *A2    = new TYPE[K * K];
    TYPE *x1    = new TYPE[K];
    TYPE *x2    = new TYPE[K];
    TYPE *b     = new TYPE[K];
    int *IPIV   = new int[K];
    generateRhs( K, b );
    generateMatrix( K, A );
    memcpy( A2, A, K * K * sizeof( TYPE ) );
    memcpy( x1, b, K * sizeof( TYPE ) );
    int err = 0;
    Lapack<TYPE>::gesv( K, 1, A2, K, IPIV, x1, K, err );
    int N_errors = 0;
    for ( int i = 0; i < N; i++ ) {
        memcpy( A2, A, K * K * sizeof( TYPE ) );
        Lapack<TYPE>::getrf( K, K, A2, K, IPIV, err );
        N_errors += err == 0 ? 0 : 1;
    }
    memcpy( x2, b, K * sizeof( TYPE ) );
    Lapack<TYPE>::getrs( 'N', K, 1, A2, K, IPIV, x2, K, err );
    TYPE norm = Lapack<TYPE>::nrm2( K, x1, 1 );
    TYPE err2 = L2Error( K, x1, x2 );
    if ( err2 > 10.0 * norm * std::numeric_limits<TYPE>::epsilon() )
        N_errors++;
    error = err2 / norm;
    delete[] A;
    delete[] A2;
    delete[] x1;
    delete[] x2;
    delete[] b;
    delete[] IPIV;
    return N_errors > 0;
}

// Test gttrf
template<typename TYPE>
static bool test_gttrf( int N, TYPE &error )
{
    // Check dgttrf by performing a factorization and solve and comparing to dgtsv
    const int K = 5 * TEST_SIZE_TRI;
    TYPE *D     = new TYPE[K];
    TYPE *D2    = new TYPE[K];
    TYPE *DL    = new TYPE[K - 1];
    TYPE *DL2   = new TYPE[K - 1];
    TYPE *DU    = new TYPE[K - 1];
    TYPE *DU2   = new TYPE[K - 1];
    TYPE *DU3   = new TYPE[K - 2];
    TYPE *x1    = new TYPE[K];
    TYPE *x2    = new TYPE[K];
    TYPE *b     = new TYPE[K];
    int *IPIV   = new int[K];
    generateRhs( K, b );
    generateTriDiag( K, DL, D, DU );
    memcpy( x1, b, K * sizeof( TYPE ) );
    memcpy( D2, D, K * sizeof( TYPE ) );
    memcpy( DL2, DL, ( K - 1 ) * sizeof( TYPE ) );
    memcpy( DU2, DU, ( K - 1 ) * sizeof( TYPE ) );
    int err = 0;
    Lapack<TYPE>::gtsv( K, 1, DL2, D2, DU2, x1, K, err );
    int N_errors = 0;
    for ( int i = 0; i < N; i++ ) {
        memcpy( D2, D, K * sizeof( TYPE ) );
        memcpy( DL2, DL, ( K - 1 ) * sizeof( TYPE ) );
        memcpy( DU2, DU, ( K - 1 ) * sizeof( TYPE ) );
        Lapack<TYPE>::gttrf( K, DL2, D2, DU2, DU3, IPIV, err );
        N_errors += err == 0 ? 0 : 1;
    }
    memcpy( x2, b, K * sizeof( TYPE ) );
    Lapack<TYPE>::gttrs( 'N', K, 1, DL2, D2, DU2, DU3, IPIV, x2, K, err );
    TYPE norm = Lapack<TYPE>::nrm2( K, x1, 1 );
    TYPE err2 = L2Error( K, x1, x2 );
    if ( err2 > 5 * K * norm * std::numeric_limits<TYPE>::epsilon() )
        N_errors++;
    error = err2 / norm;
    delete[] D;
    delete[] D2;
    delete[] DL;
    delete[] DL2;
    delete[] DU;
    delete[] DU2;
    delete[] DU3;
    delete[] x1;
    delete[] x2;
    delete[] b;
    delete[] IPIV;
    return N_errors > 0;
}

// Test gbtrf
template<typename TYPE>
static bool test_gbtrf( int N, TYPE &error )
{
    // Check dgbtrf by performing a factorization and solve and comparing to dgbsv
    const int K  = TEST_SIZE_TRI;
    const int KL = 2;
    const int KU = 2;
    const int K2 = 2 * KL + KU + 1;
    TYPE *AB     = new TYPE[K * K2];
    TYPE *AB2    = new TYPE[K * K2];
    TYPE *x1     = new TYPE[K];
    TYPE *x2     = new TYPE[K];
    TYPE *b      = new TYPE[K];
    int *IPIV    = new int[K];
    Lapack<TYPE>::random( K * K2, AB );
    Lapack<TYPE>::random( K, b );
    int err = 0;
    memcpy( x1, b, K * sizeof( TYPE ) );
    memcpy( AB2, AB, K * K2 * sizeof( TYPE ) );
    Lapack<TYPE>::gbsv( K, KL, KU, 1, AB2, K2, IPIV, x1, K, err );
    int N_errors = 0;
    for ( int i = 0; i < N; i++ ) {
        memcpy( AB2, AB, K * K2 * sizeof( TYPE ) );
        Lapack<TYPE>::gbtrf( K, K, KL, KU, AB2, K2, IPIV, err );
        N_errors += err == 0 ? 0 : 1;
    }
    memcpy( x2, b, K * sizeof( TYPE ) );
    Lapack<TYPE>::gbtrs( 'N', K, KL, KU, 1, AB2, K2, IPIV, x2, K, err );
    TYPE norm = Lapack<TYPE>::nrm2( K, x1, 1 );
    TYPE err2 = L2Error( K, x1, x2 );
    if ( err2 > 10.0 * norm * std::numeric_limits<TYPE>::epsilon() )
        N_errors++;
    error = err2 / norm;
    delete[] AB;
    delete[] AB2;
    delete[] x1;
    delete[] x2;
    delete[] b;
    delete[] IPIV;
    return N_errors > 0;
}

// Test getrs
template<typename TYPE>
static bool test_getrs( int N, TYPE &error )
{
    // Check dgetrs by performing a factorization and solve and comparing to dgesv
    const int K = 2 * TEST_SIZE_MAT;
    TYPE *A     = new TYPE[K * K];
    TYPE *A2    = new TYPE[K * K];
    TYPE *x1    = new TYPE[K];
    TYPE *x2    = new TYPE[K];
    TYPE *b     = new TYPE[K];
    int *IPIV   = new int[K];
    Lapack<TYPE>::random( K * K, A );
    Lapack<TYPE>::random( K, b );
    int err = 0;
    error   = 0;
    memcpy( A2, A, K * K * sizeof( TYPE ) );
    memcpy( x1, b, K * sizeof( TYPE ) );
    Lapack<TYPE>::gesv( K, 1, A2, K, IPIV, x1, K, err );
    int N_errors = 0;
    Lapack<TYPE>::getrf( K, K, A, K, IPIV, err );
    for ( int i = 0; i < N; i++ ) {
        memcpy( A2, A, K * K * sizeof( TYPE ) );
        memcpy( x2, b, K * sizeof( TYPE ) );
        Lapack<TYPE>::getrs( 'N', K, 1, A2, K, IPIV, x2, K, err );
        N_errors += err == 0 ? 0 : 1;
        TYPE norm = Lapack<TYPE>::nrm2( K, x1, 1 );
        TYPE err2 = L2Error( K, x1, x2 );
        if ( err > 10.0 * norm * std::numeric_limits<TYPE>::epsilon() )
            N_errors++;
        error = std::max( error, err2 / norm );
    }
    delete[] A;
    delete[] A2;
    delete[] x1;
    delete[] x2;
    delete[] b;
    delete[] IPIV;
    return N_errors > 0;
}

// Test gttrs
template<typename TYPE>
static bool test_gttrs( int N, TYPE &error )
{
    // Check dgttrs by performing a factorization and solve and comparing to dgtsv
    const int K = 5 * TEST_SIZE_TRI;
    TYPE *D     = new TYPE[K];
    TYPE *D2    = new TYPE[K];
    TYPE *DL    = new TYPE[K - 1];
    TYPE *DL2   = new TYPE[K - 1];
    TYPE *DU    = new TYPE[K - 1];
    TYPE *DU2   = new TYPE[K - 1];
    TYPE *DU3   = new TYPE[K - 2];
    TYPE *DU4   = new TYPE[K - 2];
    TYPE *x1    = new TYPE[K];
    TYPE *x2    = new TYPE[K];
    TYPE *b     = new TYPE[K];
    int *IPIV   = new int[K];
    generateRhs( K, b );
    generateTriDiag( K, DL, D, DU );
    int err = 0;
    error   = 0;
    memcpy( x1, b, K * sizeof( TYPE ) );
    memcpy( D2, D, K * sizeof( TYPE ) );
    memcpy( DL2, DL, ( K - 1 ) * sizeof( TYPE ) );
    memcpy( DU2, DU, ( K - 1 ) * sizeof( TYPE ) );
    Lapack<TYPE>::gtsv( K, 1, DL2, D2, DU2, x1, K, err );
    Lapack<TYPE>::gttrf( K, DL, D, DU, DU3, IPIV, err );
    int N_errors = 0;
    for ( int i = 0; i < N; i++ ) {
        memcpy( D2, D, K * sizeof( TYPE ) );
        memcpy( DL2, DL, ( K - 1 ) * sizeof( TYPE ) );
        memcpy( DU2, DU, ( K - 1 ) * sizeof( TYPE ) );
        memcpy( DU4, DU3, ( K - 2 ) * sizeof( TYPE ) );
        memcpy( x2, b, K * sizeof( TYPE ) );
        Lapack<TYPE>::gttrs( 'N', K, 1, DL2, D2, DU2, DU4, IPIV, x2, K, err );
        N_errors += err == 0 ? 0 : 1;
        TYPE norm = Lapack<TYPE>::nrm2( K, x1, 1 );
        TYPE err2 = L2Error( K, x1, x2 );
        if ( err2 > 5 * K * norm * std::numeric_limits<TYPE>::epsilon() )
            N_errors++;
        error = std::max( error, err2 / norm );
    }
    delete[] D;
    delete[] D2;
    delete[] DL;
    delete[] DL2;
    delete[] DU;
    delete[] DU2;
    delete[] DU3;
    delete[] DU4;
    delete[] x1;
    delete[] x2;
    delete[] b;
    delete[] IPIV;
    return N_errors > 0;
}

// Test gbtrs
template<typename TYPE>
static bool test_gbtrs( int N, TYPE &error )
{
    // Check dgbtrs by performing a factorization and solve and comparing to dgbsv
    const int K  = TEST_SIZE_TRI;
    const int KL = 2;
    const int KU = 2;
    const int K2 = 2 * KL + KU + 1;
    TYPE *AB     = new TYPE[K * K2];
    TYPE *AB2    = new TYPE[K * K2];
    TYPE *x1     = new TYPE[K];
    TYPE *x2     = new TYPE[K];
    TYPE *b      = new TYPE[K];
    int *IPIV    = new int[K];
    Lapack<TYPE>::random( K * K2, AB );
    Lapack<TYPE>::random( K, b );
    int err = 0;
    error   = 0;
    memcpy( x1, b, K * sizeof( TYPE ) );
    memcpy( AB2, AB, K * K2 * sizeof( TYPE ) );
    Lapack<TYPE>::gbsv( K, KL, KU, 1, AB2, K2, IPIV, x1, K, err );
    Lapack<TYPE>::gbtrf( K, K, KL, KU, AB, K2, IPIV, err );
    int N_errors = 0;
    for ( int i = 0; i < N; i++ ) {
        memcpy( AB2, AB, K * K2 * sizeof( TYPE ) );
        memcpy( x2, b, K * sizeof( TYPE ) );
        Lapack<TYPE>::gbtrs( 'N', K, KL, KU, 1, AB2, K2, IPIV, x2, K, err );
        N_errors += err == 0 ? 0 : 1;
        TYPE norm = Lapack<TYPE>::nrm2( K, x1, 1 );
        TYPE err2 = L2Error( K, x1, x2 );
        if ( err2 > 10.0 * norm * std::numeric_limits<TYPE>::epsilon() )
            N_errors++;
        error = std::max( error, err2 / norm );
    }
    delete[] AB;
    delete[] AB2;
    delete[] x1;
    delete[] x2;
    delete[] b;
    delete[] IPIV;
    return N_errors > 0;
}

// Test getri
template<typename TYPE>
static bool test_getri( int N, TYPE &error )
{
    // Check getri by performing a factorization, calculating the inverse,
    //   multiplying the rhs, and comparing to gesv
    const int K     = TEST_SIZE_MAT;
    const int LWORK = 8 * K;
    TYPE *A         = new TYPE[K * K];
    TYPE *A2        = new TYPE[K * K];
    TYPE *x1        = new TYPE[K];
    TYPE *x2        = new TYPE[K];
    TYPE *b         = new TYPE[K];
    int *IPIV       = new int[K];
    TYPE *WORK      = new TYPE[LWORK];
    TYPE eps        = std::numeric_limits<TYPE>::epsilon();
    Lapack<TYPE>::random( K * K, A );
    Lapack<TYPE>::random( K, b );
    int err      = 0;
    error        = 0;
    int N_errors = 0;
    memcpy( A2, A, K * K * sizeof( TYPE ) );
    memcpy( x1, b, K * sizeof( TYPE ) );
    Lapack<TYPE>::gesv( K, 1, A2, K, IPIV, x1, K, err );
    if ( err != 0 )
        printf( "Error in gesv within test_getri\n" );
    TYPE norm = Lapack<TYPE>::nrm2( K, x1, 1 );
    // Compute LU factorization
    Lapack<TYPE>::getrf( K, K, A, K, IPIV, err );
    if ( err != 0 )
        printf( "Error in getrf within test_getri\n" );
    for ( int i = 0; i < N; i++ ) {
        // Compute the inverse
        memcpy( A2, A, K * K * sizeof( TYPE ) );
        Lapack<TYPE>::getri( K, A2, K, IPIV, WORK, LWORK, err );
        if ( err != 0 ) {
            printf( "Error in getri within test_getri\n" );
            N_errors++;
        }
        // Perform the mat-vec
        memset( x2, 0xB6, K * sizeof( TYPE ) );
        Lapack<TYPE>::gemv( 'N', K, K, 1, A2, K, b, 1, 0, x2, 1 );
        TYPE err2 = L2Error( K, x1, x2 ) / norm;
        error     = std::max( error, err2 );
    }
    // Check the result
    if ( error > 500 * eps ) {
        printf( "getri exceeded tolerance: error = %e, tol = %e\n", error, 500 * eps );
        N_errors++;
    }
    delete[] A;
    delete[] A2;
    delete[] x1;
    delete[] x2;
    delete[] b;
    delete[] IPIV;
    delete[] WORK;
    return N_errors > 0;
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


/******************************************************************
 * Run a given test                                                *
 ******************************************************************/
template<class TYPE>
int Lapack<TYPE>::run_test( const std::string &routine, int N, TYPE &error )
{
    auto name = routine.substr( 1 );
    std::transform( name.begin(), name.end(), name.begin(), ::tolower );
    int N_errors = 0;
    if ( name == "copy" ) {
        N_errors += test_copy<TYPE>( N, error ) ? 1 : 0;
    } else if ( name == "scal" ) {
        N_errors += test_scal<TYPE>( N, error ) ? 1 : 0;
    } else if ( name == "nrm2" ) {
        N_errors += test_nrm2<TYPE>( N, error ) ? 1 : 0;
    } else if ( name == "axpy" ) {
        N_errors += test_axpy<TYPE>( N, error ) ? 1 : 0;
    } else if ( name == "gemv" ) {
        N_errors += test_gemv<TYPE>( N, error ) ? 1 : 0;
    } else if ( name == "gemm" ) {
        N_errors += test_gemm<TYPE>( N, error ) ? 1 : 0;
    } else if ( name == "asum" ) {
        N_errors += test_asum<TYPE>( N, error ) ? 1 : 0;
    } else if ( name == "dot" ) {
        N_errors += test_dot<TYPE>( N, error ) ? 1 : 0;
    } else if ( name == "gesv" ) {
        N_errors += test_gesv<TYPE>( N, error ) ? 1 : 0;
    } else if ( name == "gtsv" ) {
        N_errors += test_gtsv<TYPE>( N, error ) ? 1 : 0;
    } else if ( name == "gbsv" ) {
        N_errors += test_gbsv<TYPE>( N, error ) ? 1 : 0;
    } else if ( name == "getrf" ) {
        N_errors += test_getrf<TYPE>( N, error ) ? 1 : 0;
    } else if ( name == "gttrf" ) {
        N_errors += test_gttrf<TYPE>( N, error ) ? 1 : 0;
    } else if ( name == "gbtrf" ) {
        N_errors += test_gbtrf<TYPE>( N, error ) ? 1 : 0;
    } else if ( name == "getrs" ) {
        N_errors += test_getrs<TYPE>( N, error ) ? 1 : 0;
    } else if ( name == "gttrs" ) {
        N_errors += test_gttrs<TYPE>( N, error ) ? 1 : 0;
    } else if ( name == "gbtrs" ) {
        N_errors += test_gbtrs<TYPE>( N, error ) ? 1 : 0;
    } else if ( name == "getri" ) {
        N_errors += test_getri<TYPE>( N, error ) ? 1 : 0;
    } else if ( name == "rand" ) {
        N_errors += test_random<TYPE>( N, error ) ? 1 : 0;
    } else {
        std::cerr << "Unknown test: " << name << std::endl;
        return -1;
    }
    return N_errors;
}
template int Lapack<double>::run_test( const std::string &, int, double & );
template int Lapack<float>::run_test( const std::string &, int, float & );

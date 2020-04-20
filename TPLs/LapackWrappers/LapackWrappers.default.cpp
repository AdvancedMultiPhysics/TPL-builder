#include "LapackWrappers.h"

#include <stdexcept>


#define NULL_USE( variable )                 \
    do {                                     \
        if ( 0 ) {                           \
            char *temp = (char *) &variable; \
            temp++;                          \
        }                                    \
    } while ( 0 )


// Define the member functions
template<class TYPE>
void Lapack<TYPE>::copy( int N, const TYPE *DX, int INCX, TYPE *DY, int INCY )
{
    auto X = DX;
    auto Y = DY;
    for ( int i = 0; i < N; i++, X += INCX, Y += INCY )
        *Y = *X;
}
// Define the member functions
template<class TYPE>
void Lapack<TYPE>::swap( int N, TYPE *DX, int INCX, TYPE *DY, int INCY )
{
    auto X = DX;
    auto Y = DY;
    for ( int i = 0; i < N; i++, X += INCX, Y += INCY )
        *Y = *X;
}
template<class TYPE>
void Lapack<TYPE>::scal( int N, TYPE DA, TYPE *DX, int INCX )
{
    auto X = DX;
    for ( int i = 0; i < N; i++, X += INCX )
        *X *= DA;
}
template<class TYPE>
TYPE Lapack<TYPE>::nrm2( int N, const TYPE *DX, int INCX )
{
    NULL_USE( N );
    NULL_USE( DX );
    NULL_USE( INCX );
    throw std::logic_error( "nrm2 is not currently supported without blas/lapack" );
}
template<class TYPE>
int Lapack<TYPE>::iamax( int N, const TYPE *DX, int INCX )
{
    NULL_USE( N );
    NULL_USE( DX );
    NULL_USE( INCX );
    throw std::logic_error( "iamax is not currently supported without blas/lapack" );
}
template<class TYPE>
void Lapack<TYPE>::axpy( int N, TYPE DA, const TYPE *DX, int INCX, TYPE *DY, int INCY )
{
    NULL_USE( N );
    NULL_USE( DA );
    NULL_USE( DX );
    NULL_USE( DY );
    NULL_USE( INCX );
    NULL_USE( INCY );
    throw std::logic_error( "axpy is not currently supported without blas/lapack" );
}
template<class TYPE>
void Lapack<TYPE>::gemv( char TRANS, int M, int N, TYPE ALPHA, const TYPE *A, int LDA,
    const TYPE *DX, int INCX, TYPE BETA, TYPE *DY, int INCY )
{
    NULL_USE( TRANS );
    NULL_USE( M );
    NULL_USE( N );
    NULL_USE( ALPHA );
    NULL_USE( A );
    NULL_USE( LDA );
    NULL_USE( DX );
    NULL_USE( INCX );
    NULL_USE( BETA );
    NULL_USE( DY );
    NULL_USE( INCY );
    throw std::logic_error( "gemv is not currently supported without blas/lapack" );
}
template<class TYPE>
void Lapack<TYPE>::gemm( char TRANSA, char TRANSB, int M, int N, int K, TYPE ALPHA, const TYPE *A,
    int LDA, const TYPE *B, int LDB, TYPE BETA, TYPE *C, int LDC )
{
    NULL_USE( TRANSA );
    NULL_USE( TRANSB );
    NULL_USE( M );
    NULL_USE( N );
    NULL_USE( K );
    NULL_USE( ALPHA );
    NULL_USE( A );
    NULL_USE( LDA );
    NULL_USE( B );
    NULL_USE( LDB );
    NULL_USE( BETA );
    NULL_USE( C );
    NULL_USE( LDC );
    throw std::logic_error( "gemm is not currently supported without blas/lapack" );
}
template<class TYPE>
TYPE Lapack<TYPE>::asum( int N, const TYPE *DX, int INCX )
{
    NULL_USE( N );
    NULL_USE( DX );
    NULL_USE( INCX );
    throw std::logic_error( "asum is not currently supported without blas/lapack" );
}
template<class TYPE>
TYPE Lapack<TYPE>::dot( int N, const TYPE *DX, int INCX, const TYPE *DY, int INCY )
{
    NULL_USE( N );
    NULL_USE( DX );
    NULL_USE( INCX );
    NULL_USE( DY );
    NULL_USE( INCY );
    throw std::logic_error( "dot is not currently supported without blas/lapack" );
}
template<class TYPE>
void Lapack<TYPE>::ger(
    int N, int M, TYPE alpha, const TYPE *x, int INCX, const TYPE *y, int INCY, TYPE *A, int LDA )
{
    NULL_USE( N );
    NULL_USE( M );
    NULL_USE( alpha );
    NULL_USE( x );
    NULL_USE( INCX );
    NULL_USE( y );
    NULL_USE( INCY );
    NULL_USE( A );
    NULL_USE( LDA );
    throw std::logic_error( "ger is not currently supported without blas/lapack" );
}
template<class TYPE>
void Lapack<TYPE>::gesv( int N, int NRHS, TYPE *A, int LDA, int *IPIV, TYPE *B, int LDB, int &INFO )
{
    NULL_USE( N );
    NULL_USE( NRHS );
    NULL_USE( A );
    NULL_USE( LDA );
    NULL_USE( IPIV );
    NULL_USE( B );
    NULL_USE( LDB );
    NULL_USE( INFO );
    throw std::logic_error( "gesv is not currently supported without blas/lapack" );
}
template<class TYPE>
void Lapack<TYPE>::gtsv( int N, int NRHS, TYPE *DL, TYPE *D, TYPE *DU, TYPE *B, int LDB, int &INFO )
{
    NULL_USE( N );
    NULL_USE( NRHS );
    NULL_USE( DL );
    NULL_USE( D );
    NULL_USE( DU );
    NULL_USE( B );
    NULL_USE( LDB );
    NULL_USE( INFO );
    throw std::logic_error( "gtsv is not currently supported without blas/lapack" );
}
template<class TYPE>
void Lapack<TYPE>::gbsv(
    int N, int KL, int KU, int NRHS, TYPE *AB, int LDAB, int *IPIV, TYPE *B, int LDB, int &INFO )
{
    NULL_USE( N );
    NULL_USE( KL );
    NULL_USE( KU );
    NULL_USE( NRHS );
    NULL_USE( AB );
    NULL_USE( LDAB );
    NULL_USE( IPIV );
    NULL_USE( B );
    NULL_USE( LDB );
    NULL_USE( INFO );
    throw std::logic_error( "gbsv is not currently supported without blas/lapack" );
}
template<class TYPE>
void Lapack<TYPE>::getrf( int M, int N, TYPE *A, int LDA, int *IPIV, int &INFO )
{
    NULL_USE( M );
    NULL_USE( N );
    NULL_USE( A );
    NULL_USE( LDA );
    NULL_USE( IPIV );
    NULL_USE( INFO );
    throw std::logic_error( "getrf is not currently supported without blas/lapack" );
}
template<class TYPE>
void Lapack<TYPE>::gttrf( int N, TYPE *DL, TYPE *D, TYPE *DU, TYPE *DU2, int *IPIV, int &INFO )
{
    NULL_USE( N );
    NULL_USE( DL );
    NULL_USE( D );
    NULL_USE( DU );
    NULL_USE( DU2 );
    NULL_USE( IPIV );
    NULL_USE( INFO );
    throw std::logic_error( "gttrf is not currently supported without blas/lapack" );
}
template<class TYPE>
void Lapack<TYPE>::gbtrf( int M, int N, int KL, int KU, TYPE *AB, int LDAB, int *IPIV, int &INFO )
{
    NULL_USE( M );
    NULL_USE( N );
    NULL_USE( KL );
    NULL_USE( KU );
    NULL_USE( AB );
    NULL_USE( LDAB );
    NULL_USE( IPIV );
    NULL_USE( INFO );
    throw std::logic_error( "gbtrf is not currently supported without blas/lapack" );
}
template<class TYPE>
void Lapack<TYPE>::getrs( char TRANS, int N, int NRHS, const TYPE *A, int LDA, const int *IPIV,
    TYPE *B, int LDB, int &INFO )
{
    NULL_USE( TRANS );
    NULL_USE( N );
    NULL_USE( NRHS );
    NULL_USE( A );
    NULL_USE( LDA );
    NULL_USE( IPIV );
    NULL_USE( B );
    NULL_USE( LDB );
    NULL_USE( INFO );
    throw std::logic_error( "getrs is not currently supported without blas/lapack" );
}
template<class TYPE>
void Lapack<TYPE>::gttrs( char TRANS, int N, int NRHS, const TYPE *DL, const TYPE *D,
    const TYPE *DU, const TYPE *DU2, const int *IPIV, TYPE *B, int LDB, int &INFO )
{
    NULL_USE( TRANS );
    NULL_USE( N );
    NULL_USE( NRHS );
    NULL_USE( DL );
    NULL_USE( D );
    NULL_USE( DU );
    NULL_USE( DU2 );
    NULL_USE( IPIV );
    NULL_USE( B );
    NULL_USE( LDB );
    NULL_USE( INFO );
    throw std::logic_error( "gttrs is not currently supported without blas/lapack" );
}
template<class TYPE>
void Lapack<TYPE>::gbtrs( char TRANS, int N, int KL, int KU, int NRHS, const TYPE *AB, int LDAB,
    const int *IPIV, TYPE *B, int LDB, int &INFO )
{
    NULL_USE( TRANS );
    NULL_USE( N );
    NULL_USE( KL );
    NULL_USE( KU );
    NULL_USE( NRHS );
    NULL_USE( AB );
    NULL_USE( LDAB );
    NULL_USE( IPIV );
    NULL_USE( B );
    NULL_USE( LDB );
    NULL_USE( INFO );
    throw std::logic_error( "gbtrs is not currently supported without blas/lapack" );
}
template<class TYPE>
void Lapack<TYPE>::getri(
    int N, TYPE *A, int LDA, const int *IPIV, TYPE *WORK, int LWORK, int &INFO )
{
    NULL_USE( N );
    NULL_USE( A );
    NULL_USE( LDA );
    NULL_USE( IPIV );
    NULL_USE( WORK );
    NULL_USE( LWORK );
    NULL_USE( INFO );
    throw std::logic_error( "getri is not currently supported without blas/lapack" );
}
template<class TYPE>
void Lapack<TYPE>::trsm( char SIDE, char UPLO, char TRANS, char DIAG, int M, int N, TYPE ALPHA,
    const TYPE *A, int LDA, TYPE *B, int LDB )
{
    NULL_USE( SIDE );
    NULL_USE( UPLO );
    NULL_USE( TRANS );
    NULL_USE( DIAG );
    NULL_USE( M );
    NULL_USE( N );
    NULL_USE( ALPHA );
    NULL_USE( A );
    NULL_USE( LDA );
    NULL_USE( B );
    NULL_USE( LDB );
    throw std::logic_error( "trsm is not currently supported without blas/lapack" );
}


// Explicit instatiations
#define INSTANTIATE( TYPE )                                                                       \
    template void Lapack<TYPE>::copy( int, const TYPE *, int, TYPE *, int );                      \
    template void Lapack<TYPE>::swap( int, TYPE *, int, TYPE *, int );                            \
    template void Lapack<TYPE>::scal( int, TYPE, TYPE *, int );                                   \
    template TYPE Lapack<TYPE>::nrm2( int, const TYPE *, int );                                   \
    template int Lapack<TYPE>::iamax( int, const TYPE *, int );                                   \
    template void Lapack<TYPE>::axpy( int, TYPE, const TYPE *, int, TYPE *, int );                \
    template void Lapack<TYPE>::gemv(                                                             \
        char, int, int, TYPE, const TYPE *, int, const TYPE *, int, TYPE, TYPE *, int );          \
    template void Lapack<TYPE>::gemm( char, char, int, int, int K, TYPE ALPHA, const TYPE *, int, \
        const TYPE *, int, TYPE, TYPE *, int );                                                   \
    template TYPE Lapack<TYPE>::asum( int, const TYPE *, int );                                   \
    template TYPE Lapack<TYPE>::dot( int, const TYPE *, int, const TYPE *, int );                 \
    template void Lapack<TYPE>::ger(                                                              \
        int, int, TYPE, const TYPE *, int, const TYPE *, int, TYPE *, int );                      \
    template void Lapack<TYPE>::gesv( int, int, TYPE *, int, int *, TYPE *, int, int & );         \
    template void Lapack<TYPE>::gtsv( int, int, TYPE *, TYPE *, TYPE *, TYPE *, int, int & );     \
    template void Lapack<TYPE>::gbsv(                                                             \
        int, int, int, int, TYPE *, int, int *, TYPE *, int, int & );                             \
    template void Lapack<TYPE>::getrf( int, int, TYPE *, int, int *, int & );                     \
    template void Lapack<TYPE>::gttrf( int, TYPE *, TYPE *, TYPE *, TYPE *, int *, int & );       \
    template void Lapack<TYPE>::gbtrf( int, int, int, int, TYPE *, int, int *, int & );           \
    template void Lapack<TYPE>::getrs(                                                            \
        char, int, int, const TYPE *, int, const int *, TYPE *, int, int & );                     \
    template void Lapack<TYPE>::gttrs( char, int, int, const TYPE *, const TYPE *, const TYPE *,  \
        const TYPE *, const int *, TYPE *, int, int & );                                          \
    template void Lapack<TYPE>::gbtrs(                                                            \
        char, int, int, int, int, const TYPE *, int, const int *, TYPE *, int, int & );           \
    template void Lapack<TYPE>::getri( int, TYPE *, int, const int *, TYPE *, int, int & );       \
    template void Lapack<TYPE>::trsm(                                                             \
        char, char, char, char, int, int, TYPE, const TYPE *, int, TYPE *, int );

INSTANTIATE( float )
INSTANTIATE( double )

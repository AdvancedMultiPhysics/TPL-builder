// This is a simple test that uses one or more features from each library
// to ensure that we can build and link an application with all libraries

#include <stdio.h>
#include <iostream>
#include <sstream>
#include <string>
#include <vector>

#include "TPLs.h"

#ifdef USE_BOOST
    #include "boost/shared_ptr.hpp"
#endif
#ifdef USE_LAPACK_WRAPPERS
    #include "LapackWrappers.h"
#endif
#ifdef USE_PETSC
    #define __MPIUNI_H
    #include "petsc.h"
#endif
#ifdef USE_HDF5
    #include "hdf5.h"
#endif



// Split the TPL list
std::vector<std::string> split( const std::string& str )
{
    std::vector<std::string> internal;
    std::stringstream ss(str);
    std::string tok;
    while ( getline(ss,tok,';') )
        internal.push_back(tok);
    return internal;
}


// Test BOOST
int testBOOST( )
{
    int N_errors = 0;
#ifdef USE_BOOST
    boost::shared_ptr<int> x( new int );
    *x = 3;
    if ( *x != 3 )
        N_errors++;
#else
    std::cout << "   -- USE_BOOST not defined\n";
    N_errors++;
#endif
    return N_errors;
}


// Test LAPACK
int testLAPACK( )
{
    int N_errors = 0;
#if defined(USE_LAPACK) && defined(USE_LAPACK_WRAPPERS)
    std::cout << "   -- Using LAPACK_WRAPPERS to test LAPACK\n";
#elif defined(USE_LAPACK)
    std::cout << "   -- No tests defined for LAPACK\n";
#else
    std::cout << "   -- USE_LAPACK not defined\n";
    N_errors++;
#endif
    return N_errors;
}


// Test LAPACK_WRAPPERS
int testLAPACK_WRAPPERS( )
{
    int N_errors = 0;
#ifdef USE_LAPACK_WRAPPERS
    N_errors = Lapack::run_all_test();
#else
    std::cout << "   -- USE_LAPACK_WRAPPERS not defined\n";
    N_errors++;
#endif
    return N_errors;
}


// Test ZLIB
int testZLIB( )
{
    int N_errors = 0;
#ifdef USE_ZLIB
    std::cout << "   -- No tests defined for zlib\n";
#else
    std::cout << "   -- USE_ZLIB not defined\n";
    N_errors++;
#endif
    return N_errors;
}


// Test HDF5
int testHDF5( )
{
    int N_errors = 0;
#ifdef USE_HDF5
    hid_t H5Fcreate( const char *name, unsigned flags, hid_t fcpl_id, hid_t fapl_id );
#else
    std::cout << "   -- USE_HDF5 not defined\n";
    N_errors++;
#endif
    return N_errors;
}


// Test PETSC
int testPETSC( )
{
    int N_errors = 0;
#ifdef USE_PETSC
    PetscBool initialized;
    PetscErrorCode err = PetscInitialized( &initialized );
    if ( initialized || err!=0 ) {
        std::cout << "   Error calling PetscInitialized\n";
        N_errors++;
    }
#else
    std::cout << "   -- USE_PETSC not defined\n";
    N_errors++;
#endif
    return N_errors;
}


// Test SILO
int testSILO( )
{
    int N_errors = 0;
#ifdef USE_SILO
    std::cout << "   -- No tests defined for silo\n";
#else
    std::cout << "   -- USE_SILO not defined\n";
    N_errors++;
#endif
    return N_errors;
}


// Test NETCDF
int testNETCDF( )
{
    int N_errors = 0;
#ifdef USE_NETCDF
    std::cout << "   -- No tests defined for netcdf\n";
#else
    std::cout << "   -- USE_NETCDF not defined\n";
    N_errors++;
#endif
    return N_errors;
}


// Test HYPRE
int testHYPRE( )
{
    int N_errors = 0;
#ifdef USE_HYPRE
    std::cout << "   -- No tests defined for hypre\n";
#else
    std::cout << "   -- USE_HYPRE not defined\n";
    N_errors++;
#endif
    return N_errors;
}


// Test LIBMESH
int testLIBMESH( )
{
    int N_errors = 0;
#ifdef USE_LIBMESH
    std::cout << "   -- No tests defined for libmesh\n";
#else
    std::cout << "   -- USE_LIBMESH not defined\n";
    N_errors++;
#endif
    return N_errors;
}


// Test TRILINOS
int testTRILINOS( )
{
    int N_errors = 0;
#ifdef USE_TRILINOS
    std::cout << "   -- No tests defined for trilinos\n";
#else
    std::cout << "   -- USE_TRILINOS not defined\n";
    N_errors++;
#endif
    return N_errors;
}


// Test SUNDIALS
int testSUNDIALS( )
{
    int N_errors = 0;
#ifdef USE_SUNDIALS
    std::cout << "   -- No tests defined for sundials\n";
#else
    std::cout << "   -- USE_SUNDIALS not defined\n";
    N_errors++;
#endif
    return N_errors;
}


// Test TIMER
int testTIMER( )
{
    int N_errors = 0;
#ifdef USE_TIMER
    std::cout << "   -- No tests defined for timer\n";
#else
    std::cout << "   -- USE_TIMER not defined\n";
    N_errors++;
#endif
    return N_errors;
}


// Test SAMRAI
int testSAMRAI( )
{
    int N_errors = 0;
#ifdef USE_SAMRAI
    std::cout << "   -- No tests defined for samrai\n";
#else
    std::cout << "   -- USE_SAMRAI not defined\n";
    N_errors++;
#endif
    return N_errors;
}


// Test KOKKOS
int testKOKKOS( )
{
    int N_errors = 0;
#ifdef USE_KOKKOS
    std::cout << "   -- No tests defined for kokkos\n";
#else
    std::cout << "   -- USE_KOKKOS not defined\n";
    N_errors++;
#endif
    return N_errors;
}


// Test OGRE
int testOGRE( )
{
    int N_errors = 0;
#ifdef USE_OGRE
    std::cout << "   -- No tests defined for ogre\n";
#else
    std::cout << "   -- USE_OGRE not defined\n";
    N_errors++;
#endif
    return N_errors;
}



// Main
int main()
{
    // Get the TPL list
    std::vector<std::string> tpls = split( TPL_LIST );
    if ( tpls.empty() ) {
        std::cout << "No TPLs found\n";
        return 0;
    }

    // Print the TPLs
    std::cout << "TPLS: " << tpls[0];
    for (size_t i=1; i<tpls.size(); i++)
        std::cout << ", " << tpls[i];
    std::cout << std::endl;
    
    // Test each of the TPLs
    int N_errors_global = 0;
    for (size_t i=0; i<tpls.size(); i++) {
        std::cout << "Testing " << tpls[i] << std::endl;
        int N_errors = 0;
        if ( tpls[i] == "BOOST" ) {
            // Test BOOST
            N_errors = testBOOST( );
        } else if ( tpls[i] == "LAPACK" ) {
            // Test LAPACK wrappers
            N_errors = testLAPACK( );
        } else if ( tpls[i] == "LAPACK_WRAPPERS" ) {
            // Test LAPACK_WRAPPERS
            N_errors = testLAPACK_WRAPPERS( );
        } else if ( tpls[i] == "ZLIB" ) {
            // Test ZLIB
            N_errors = testZLIB( );
        } else if ( tpls[i] == "HDF5" ) {
            // Test HDF5
            N_errors = testHDF5( );
        } else if ( tpls[i] == "PETSC" ) {
            // Test PETSC
            N_errors = testPETSC( );
        } else if ( tpls[i] == "SILO" ) {
            // Test SILO
            N_errors = testSILO( );
        } else if ( tpls[i] == "NETCDF" ) {
            // Test NETCDF
            N_errors = testNETCDF( );
        } else if ( tpls[i] == "HYPRE" ) {
            // Test HYPRE
            N_errors = testHYPRE( );
        } else if ( tpls[i] == "LIBMESH" ) {
            // Test LIBMESH
            N_errors = testLIBMESH( );
        } else if ( tpls[i] == "TRILINOS" ) {
            // Test TRILINOS
            N_errors = testTRILINOS( );
        } else if ( tpls[i] == "SUNDIALS" ) {
            // Test SUNDIALS
            N_errors = testSUNDIALS( );
        } else if ( tpls[i] == "TIMER" ) {
            // Test TIMER
            N_errors = testTIMER( );
        } else if ( tpls[i] == "SAMRAI" ) {
            // Test SAMRAI
            N_errors = testSAMRAI( );
        } else if ( tpls[i] == "KOKKOS" ) {
            // Test KOKKOS
            N_errors = testKOKKOS( );
        } else if ( tpls[i] == "OGRE" ) {
            // Test OGRE
            N_errors = testOGRE( );
        } else {
            // TPL not found
            std::cerr << tpls[i] << " not programmed\n";
            N_errors++;
        }
        if ( N_errors==0 ) {
            std::cout << "   -- Passed\n";
        } else {
            std::cout << "   -- Failed\n";
            N_errors_global++;
        }
    }

    if ( N_errors_global==0 )
        std::cout << "All tests passed\n";
    else
        std::cout << "Some tests failed\n";
    return N_errors_global;
}


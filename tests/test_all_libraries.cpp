// This is a simple test that uses one or more features from each library
// to ensure that we can build and link an application with all libraries

#include <stdio.h>
#include <iostream>
#include <sstream>
#include <string>
#include <vector>

#include "TPLs.h"
#include "TPL_helpers.h"


// Include appropriate TPL headers
#ifdef USE_BOOST
    #include "boost/shared_ptr.hpp"
#endif
#ifdef USE_HDF5
    #include "hdf5.h"
#endif
#ifdef USE_LAPACK_WRAPPERS
    #include "LapackWrappers.h"
#endif
#ifdef USE_PETSC
    #include "petsc.h"
#endif
#ifdef USE_STACKTRACE
    #include "StackTrace/StackTrace.h"
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


// Define test interface
template<TPL_Enum TPL> bool test( );


// Test BOOST
#ifdef USE_BOOST
template<> bool test<TPL_Enum::BOOST>( )
{
    bool pass = true;
    boost::shared_ptr<int> x( new int );
    *x = 3;
    if ( *x != 3 )
        pass = false;
    return pass;
}
#endif


// Test FFTW
#ifdef USE_FFTW
template<> bool test<TPL_Enum::FFTW>( )
{
    std::cout << "   -- No tests defined for fftw\n";
    return true;
}
#endif


// Test HDF5
#ifdef USE_HDF5
template<> bool test<TPL_Enum::HDF5>( )
{
    hid_t H5Fcreate( const char *name, unsigned flags, hid_t fcpl_id, hid_t fapl_id );
    return true;
}
#endif


// Test HYPRE
#ifdef USE_HYPRE
template<> bool test<TPL_Enum::HYPRE>( )
{
    std::cout << "   -- No tests defined for hypre\n";
    return true;
}
#endif


// Test KOKKOS
#ifdef USE_KOKKOS
template<> bool test<TPL_Enum::KOKKOS>( )
{
    std::cout << "   -- No tests defined for kokkos\n";
    return true;
}
#endif


// Test LAPACK
#ifdef USE_LAPACK
template<> bool test<TPL_Enum::LAPACK>( )
{
#if defined(USE_LAPACK_WRAPPERS)
    std::cout << "   -- Using LAPACK_WRAPPERS to test LAPACK\n";
#else
    std::cout << "   -- No tests defined for LAPACK\n";
#endif
    return true;
}
#endif


// Test LAPACK_WRAPPERS
#ifdef USE_LAPACK_WRAPPERS
template<> bool test<TPL_Enum::LAPACK_WRAPPERS>( )
{
    int N_errors = 0;
    N_errors = Lapack<double>::run_all_test();
    N_errors += Lapack<float>::run_all_test();
    return N_errors==0;
}
#endif


// Test LIBMESH
#ifdef USE_LIBMESH
template<> bool test<TPL_Enum::LIBMESH>( )
{
    std::cout << "   -- No tests defined for libmesh\n";
    return true;
}
#endif


// Test NETCDF
#ifdef USE_NETCDF
template<> bool test<TPL_Enum::NETCDF>( )
{
    std::cout << "   -- No tests defined for netcdf\n";
    return true;
}
#endif


// Test OGRE
#ifdef USE_OGRE
template<> bool test<TPL_Enum::OGRE>( )
{
    std::cout << "   -- No tests defined for ogre\n";
    return true;
}
#endif


// Test PETSC
#ifdef USE_PETSC
template<> bool test<TPL_Enum::PETSC>( )
{
    bool pass = true;
    PetscBool initialized;
    PetscErrorCode err = PetscInitialized( &initialized );
    if ( initialized || err!=0 ) {
        std::cout << "   Error calling PetscInitialized\n";
        pass = false;
    }
    return pass;
}
#endif


// Test SAMRAI
#ifdef USE_SAMRAI
template<> bool test<TPL_Enum::SAMRAI>( )
{
    std::cout << "   -- No tests defined for samrai\n";
    return true;
}
#endif


// Test SILO
#ifdef USE_SILO
template<> bool test<TPL_Enum::SILO>( )
{
    std::cout << "   -- No tests defined for silo\n";
    return true;
}
#endif


// Test STACKTRACE
#ifdef USE_STACKTRACE
template<> bool test<TPL_Enum::STACKTRACE>( )
{
    return !StackTrace::getCallStack().empty();
}
#endif


// Test SUNDIALS
#ifdef USE_SUNDIALS
template<> bool test<TPL_Enum::SUNDIALS>( )
{
    std::cout << "   -- No tests defined for sundials\n";
    return true;
}
#endif


// Test TIMER
#ifdef USE_TIMER
template<> bool test<TPL_Enum::TIMER>( )
{
    std::cout << "   -- No tests defined for timer\n";
    return true;
}
#endif


// Test TRILINOS
#ifdef USE_TRILINOS
template<> bool test<TPL_Enum::TRILINOS>( )
{
    std::cout << "   -- No tests defined for trilinos\n";
    return true;
}
#endif


// Test ZLIB
#ifdef USE_ZLIB
template<> bool test<TPL_Enum::ZLIB>( )
{
    std::cout << "   -- No tests defined for zlib\n";
    return true;
}
#endif


// Default implimentation
template<TPL_Enum TPL> bool test( )
{
    std::cerr << "   -- Implimentation of " << getName(TPL) << " not defined\n";
    return false;
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
    auto list = enabledTPls();
    for ( auto tmp : list) {
        auto tpl = getName(tmp);
        std::cout << "Testing " << tpl << std::endl;
        bool pass = true;
        if ( tpl == "BOOST" ) {
            // Test BOOST
            pass = test<TPL_Enum::BOOST>( );
        } else if ( tpl == "FFTW" ) {
            // Test FFTW
        } else if ( tpl == "OPENBLAS" ) {
            // Test OpenBLAS is tested through the lapack wrappers
        } else if ( tpl == "LAPACK" ) {
            // Test LAPACK wrappers
            pass = test<TPL_Enum::LAPACK>( );
        } else if ( tpl == "LAPACK_WRAPPERS" ) {
            // Test LAPACK_WRAPPERS
            pass = test<TPL_Enum::LAPACK_WRAPPERS>( );
        } else if ( tpl == "HDF5" ) {
            // Test HDF5
            pass = test<TPL_Enum::HDF5>( );
        } else if ( tpl == "HYPRE" ) {
            // Test HYPRE
            pass = test<TPL_Enum::HYPRE>( );
        } else if ( tpl == "KOKKOS" ) {
            // Test KOKKOS
            pass = test<TPL_Enum::KOKKOS>( );
        } else if ( tpl == "LIBMESH" ) {
            // Test LIBMESH
            pass = test<TPL_Enum::LIBMESH>( );
        } else if ( tpl == "MATLAB" ) {
            // No MATLAB linkin tests
        } else if ( tpl == "NETCDF" ) {
            // Test NETCDF
            pass = test<TPL_Enum::NETCDF>( );
        } else if ( tpl == "OGRE" ) {
            // Test OGRE
            pass = test<TPL_Enum::OGRE>( );
        } else if ( tpl == "PETSC" ) {
            // Test PETSC
            pass = test<TPL_Enum::PETSC>( );
        } else if ( tpl == "SAMRAI" ) {
            // Test SAMRAI
            pass = test<TPL_Enum::SAMRAI>( );
        } else if ( tpl == "SILO" ) {
            // Test SILO
            pass = test<TPL_Enum::SILO>( );
        } else if ( tpl == "STACKTRACE" ) {
            // Test STACKTRACE
            pass = test<TPL_Enum::STACKTRACE>( );
        } else if ( tpl == "SUNDIALS" ) {
            // Test SUNDIALS
            pass = test<TPL_Enum::SUNDIALS>( );
        } else if ( tpl == "TIMER" ) {
            // Test TIMER
            pass = test<TPL_Enum::TIMER>( );
        } else if ( tpl == "TRILINOS" ) {
            // Test TRILINOS
            pass = test<TPL_Enum::TRILINOS>( );
        } else if ( tpl == "ZLIB" ) {
            // Test ZLIB
            pass = test<TPL_Enum::ZLIB>( );
        } else {
            // TPL not found
            std::cerr << tpl << " not programmed\n";
            pass = false;
        }
        if ( pass ) {
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


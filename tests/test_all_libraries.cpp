// This is a simple test that uses one or more features from each library
// to ensure that we can build and link an application with all libraries

#include <iostream>
#include <sstream>
#include <stdio.h>
#include <string>
#include <vector>

#include "TPLS_Tests_TPLs.h"
#include "TPL_helpers.h"


// Include appropriate TPL headers
#ifdef TPLS_Tests_USE_BOOST
#include "boost/shared_ptr.hpp"
#endif
#ifdef TPLS_Tests_USE_HDF5
#include "hdf5.h"
#endif
#ifdef TPLS_Tests_USE_LAPACK_WRAPPERS
#include "LapackWrappers.h"
#endif
#ifdef TPLS_Tests_USE_PETSC
#include "petsc.h"
#endif
#ifdef TPLS_Tests_USE_STACKTRACE
#include "StackTrace/StackTrace.h"
#endif
#ifdef TPLS_Tests_USE_KOKKOS
#include <Kokkos_Core.hpp>
#endif


// Split the TPL list
std::vector<std::string> split( const std::string& str )
{
    std::vector<std::string> internal;
    std::stringstream ss( str );
    std::string tok;
    while ( getline( ss, tok, ';' ) )
        internal.push_back( tok );
    return internal;
}


// Define test interface
template<TPL_Enum TPL>
bool test();


// Test MPI
#ifdef TPLS_Tests_USE_MPI
template<>
bool test<TPL_Enum::MPI>()
{
    // Not implemented yet
    return true;
}
#endif


// Test BOOST
#ifdef TPLS_Tests_USE_BOOST
template<>
bool test<TPL_Enum::BOOST>()
{
    bool pass = true;
    boost::shared_ptr<int> x( new int );
    *x = 3;
    if ( *x != 3 ) pass = false;
    return pass;
}
#endif


// Test THRUST
#ifdef TPLS_Tests_USE_THRUST
template<>
bool test<TPL_Enum::THRUST>()
{
    std::cout << "   -- No tests defined for thrust\n";
    return true;
}
#endif


// Test FFTW
#ifdef TPLS_Tests_USE_FFTW
template<>
bool test<TPL_Enum::FFTW>()
{
    std::cout << "   -- No tests defined for fftw\n";
    return true;
}
#endif


// Test HDF5
#ifdef TPLS_Tests_USE_HDF5
template<>
bool test<TPL_Enum::HDF5>()
{
    hid_t H5Fcreate( const char* name, unsigned flags, hid_t fcpl_id, hid_t fapl_id );
    return true;
}
#endif


// Test HYPRE
#ifdef TPLS_Tests_USE_HYPRE
template<>
bool test<TPL_Enum::HYPRE>()
{
    std::cout << "   -- No tests defined for hypre\n";
    return true;
}
#endif

// Test UMPIRE
#ifdef TPLS_Tests_USE_UMPIRE
template<>
bool test<TPL_Enum::UMPIRE>()
{
    std::cout << "   -- No tests defined for Umpire\n";
    return true;
}
#endif

// Test RAJA
#ifdef TPLS_Tests_USE_RAJA
template<>
bool test<TPL_Enum::RAJA>()
{
    std::cout << "   -- No tests defined for Raja\n";
    return true;
}
#endif


// Test KOKKOS
#ifdef TPLS_Tests_USE_KOKKOS
template<>
bool test<TPL_Enum::KOKKOS>()
{
    auto settings = Kokkos::InitializationSettings();
    Kokkos::initialize( settings );
    Kokkos::finalize();
    return true;
}
#endif


// Test CABANA
#ifdef TPLS_Tests_USE_CABANA
template<>
bool test<TPL_Enum::CABANA>()
{
    std::cout << "   -- No tests defined for Cabana\n";
    return true;
}
#endif


// Test LAPACK
#ifdef TPLS_Tests_USE_LAPACK
template<>
bool test<TPL_Enum::LAPACK>()
{
#if defined( USE_LAPACK_WRAPPERS )
    std::cout << "   -- Using LAPACK_WRAPPERS to test LAPACK\n";
#else
    std::cout << "   -- No tests defined for LAPACK\n";
#endif
    return true;
}
#endif


// Test LAPACK_WRAPPERS
#ifdef TPLS_Tests_USE_LAPACK_WRAPPERS
template<>
bool test<TPL_Enum::LAPACK_WRAPPERS>()
{
    int N_errors = 0;
    N_errors     = Lapack<double>::run_all_test();
    N_errors += Lapack<float>::run_all_test();
    return N_errors == 0;
}
#endif


// Test LIBMESH
#ifdef TPLS_Tests_USE_LIBMESH
template<>
bool test<TPL_Enum::LIBMESH>()
{
    std::cout << "   -- No tests defined for libmesh\n";
    return true;
}
#endif


// Test MATLAB
#ifdef TPLS_Tests_USE_MATLAB
template<>
bool test<TPL_Enum::MATLAB>()
{
    std::cout << "   -- No tests defined for MATLAB\n";
    return true;
}
#endif


// Test NETCDF
#ifdef TPLS_Tests_USE_NETCDF
template<>
bool test<TPL_Enum::NETCDF>()
{
    std::cout << "   -- No tests defined for netcdf\n";
    return true;
}
#endif


// Test OGRE
#ifdef TPLS_Tests_USE_OGRE
template<>
bool test<TPL_Enum::OGRE>()
{
    std::cout << "   -- No tests defined for ogre\n";
    return true;
}
#endif


// Test OpenBLAS
#ifdef TPLS_Tests_USE_OPENBLAS
template<>
bool test<TPL_Enum::OPENBLAS>()
{
    std::cout << "   -- OpenBLAS tested through test_LapackWrappers\n";
    return true;
}
#endif


// Test PETSC
#ifdef TPLS_Tests_USE_PETSC
template<>
bool test<TPL_Enum::PETSC>()
{
    bool pass = true;
    PetscBool initialized;
    PetscErrorCode err = PetscInitialized( &initialized );
    if ( initialized || err != 0 ) {
        std::cout << "   Error calling PetscInitialized\n";
        pass = false;
    }
    return pass;
}
#endif


// Test Qt
#ifdef TPLS_Tests_USE_QT
template<>
bool test<TPL_Enum::QT>()
{
    std::cout << "   -- No tests defined for Qt\n";
    return true;
}
#endif


// Test QWT
#ifdef TPLS_Tests_USE_QWT
template<>
bool test<TPL_Enum::QWT>()
{
    std::cout << "   -- No tests defined for qwt\n";
    return true;
}
#endif


// Test SAMRAI
#ifdef TPLS_Tests_USE_SAMRAI
template<>
bool test<TPL_Enum::SAMRAI>()
{
    std::cout << "   -- No tests defined for samrai\n";
    return true;
}
#endif


// Test SILO
#ifdef TPLS_Tests_USE_SILO
template<>
bool test<TPL_Enum::SILO>()
{
    std::cout << "   -- No tests defined for silo\n";
    return true;
}
#endif


// Test STACKTRACE
#ifdef TPLS_Tests_USE_STACKTRACE
template<>
bool test<TPL_Enum::STACKTRACE>()
{
    return !StackTrace::getCallStack().empty();
}
#endif


// Test SUNDIALS
#ifdef TPLS_Tests_USE_SUNDIALS
template<>
bool test<TPL_Enum::SUNDIALS>()
{
    std::cout << "   -- No tests defined for suTPL_Enumndials\n";
    return true;
}
#endif


// Test TIMER
#ifdef TPLS_Tests_USE_TIMER
template<>
bool test<TPL_Enum::TIMER>()
{
    std::cout << "   -- No tests defined for timer\n";
    return true;
}
#endif


// Test TRILINOS
#ifdef TPLS_Tests_USE_TRILINOS
template<>
bool test<TPL_Enum::TRILINOS>()
{
    std::cout << "   -- No tests defined for trilinos\n";
    return true;
}
#endif


// Test ZLIB
#ifdef TPLS_Tests_USE_ZLIB
template<>
bool test<TPL_Enum::ZLIB>()
{
    std::cout << "   -- No tests defined for zlib\n";
    return true;
}
#endif


// Test CATCH2
#ifdef TPLS_Tests_USE_CATCH2
template<>
bool test<TPL_Enum::CATCH2>()
{
    std::cout << "   -- No tests defined for Catch2\n";
    return true;
}
#endif


// Test XBRAID
#ifdef TPLS_Tests_USE_XBRAID
template<>
bool test<TPL_Enum::XBRAID>()
{
    std::cout << "   -- No tests defined for xbraid\n";
    return true;
}
#endif


// Default implementation
template<TPL_Enum TPL>
bool test()
{
    std::cerr << "   -- Implementation of " << getName( TPL ) << " not defined\n";
    return false;
}


// Call the test
bool callTest( TPL_Enum tpl )
{
    switch ( tpl ) {
    case TPL_Enum::AMP: return test<TPL_Enum::AMP>();
    case TPL_Enum::BOOST: return test<TPL_Enum::BOOST>();
    case TPL_Enum::CABANA: return test<TPL_Enum::CABANA>();
    case TPL_Enum::CATCH2: return test<TPL_Enum::CATCH2>();
    case TPL_Enum::FFTW: return test<TPL_Enum::FFTW>();
    case TPL_Enum::HDF5: return test<TPL_Enum::HDF5>();
    case TPL_Enum::HYPRE: return test<TPL_Enum::HYPRE>();
    case TPL_Enum::KOKKOS: return test<TPL_Enum::KOKKOS>();
    case TPL_Enum::LAPACK: return test<TPL_Enum::LAPACK>();
    case TPL_Enum::LAPACK_WRAPPERS: return test<TPL_Enum::LAPACK_WRAPPERS>();
    case TPL_Enum::LIBMESH: return test<TPL_Enum::LIBMESH>();
    case TPL_Enum::MATLAB: return test<TPL_Enum::MATLAB>();
    case TPL_Enum::MPI: return test<TPL_Enum::MPI>();
    case TPL_Enum::NETCDF: return test<TPL_Enum::NETCDF>();
    case TPL_Enum::OGRE: return test<TPL_Enum::OGRE>();
    case TPL_Enum::OPENBLAS: return test<TPL_Enum::OPENBLAS>();
    case TPL_Enum::PETSC: return test<TPL_Enum::PETSC>();
    case TPL_Enum::QT: return test<TPL_Enum::QT>();
    case TPL_Enum::QWT: return test<TPL_Enum::QWT>();
    case TPL_Enum::RAJA: return test<TPL_Enum::RAJA>();
    case TPL_Enum::SAMRAI: return test<TPL_Enum::SAMRAI>();
    case TPL_Enum::SAMRSOLVERS: return test<TPL_Enum::SAMRSOLVERS>();
    case TPL_Enum::SAMRUTILS: return test<TPL_Enum::SAMRUTILS>();
    case TPL_Enum::SILO: return test<TPL_Enum::SILO>();
    case TPL_Enum::STACKTRACE: return test<TPL_Enum::STACKTRACE>();
    case TPL_Enum::SUNDIALS: return test<TPL_Enum::SUNDIALS>();
    case TPL_Enum::THRUST: return test<TPL_Enum::THRUST>();
    case TPL_Enum::TIMER: return test<TPL_Enum::TIMER>();
    case TPL_Enum::TRILINOS: return test<TPL_Enum::TRILINOS>();
    case TPL_Enum::UMPIRE: return test<TPL_Enum::UMPIRE>();
    case TPL_Enum::XBRAID: return test<TPL_Enum::XBRAID>();
    case TPL_Enum::ZLIB: return test<TPL_Enum::ZLIB>();
    case TPL_Enum::NULL_TPL: std::cerr << "Null TPL detected\n"; return false;
    case TPL_Enum::UNKNOWN: std::cerr << "Unknown TPL detected\n"; return false;
    }
    std::cerr << getName( tpl ) << " not programmed\n";
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
    for ( size_t i = 1; i < tpls.size(); i++ )
        std::cout << ", " << tpls[i];
    std::cout << std::endl;

    // Test each of the TPLs
    int N_errors_global = 0;
    auto list           = enabledTPls();
    for ( auto tpl : list ) {
        std::cout << "Testing " << getName( tpl ) << std::endl;
        bool pass = callTest( tpl );
        if ( pass ) {
            std::cout << "   -- Passed\n";
        } else {
            std::cout << "   -- Failed\n";
            N_errors_global++;
        }
    }

    if ( N_errors_global == 0 )
        std::cout << "All tests passed\n";
    else
        std::cout << "Some tests failed\n";
    return N_errors_global;
}

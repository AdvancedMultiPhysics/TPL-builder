#ifndef included_TPL_headers
#define included_TPL_headers

#include "TPLS_Tests_TPLs.h"

#include <string>
#include <stdexcept>


// List of valid TPLs that we can test
enum class TPL_Enum { MPI, BOOST, FFTW, HDF5, UMPIRE, RAJA, HYPRE, KOKKOS, CABANA, LAPACK, LAPACK_WRAPPERS, 
    OPENBLAS, LIBMESH, MATLAB, NETCDF, OGRE, PETSC, SAMRAI, SILO, STACKTRACE, 
		      SUNDIALS, TIMER, TRILINOS, XBRAID, ZLIB, CATCH2, AMP, SAMRUTILS, SAMRSOLVERS, NULL_TPL, UNKNOWN };


// List of TPLs that are not used for compiling/linking (e.g. cppcheck)
const char* nullTPLs[] = { "CPPCHECK" };


// Get the string for an TPL enum
inline std::string getName( TPL_Enum tpl )
{
    if ( tpl == TPL_Enum::MPI )
        return "MPI";
    if ( tpl == TPL_Enum::BOOST )
        return "BOOST";
    if ( tpl == TPL_Enum::FFTW )
        return "FFTW";
    if ( tpl == TPL_Enum::HDF5 )
        return "HDF5";
    if ( tpl == TPL_Enum::UMPIRE )
        return "UMPIRE";
    if ( tpl == TPL_Enum::RAJA )
        return "RAJA";
    if ( tpl == TPL_Enum::HYPRE )
        return "HYPRE";
    if ( tpl == TPL_Enum::KOKKOS )
        return "KOKKOS";
    if ( tpl == TPL_Enum::CABANA )
        return "CABANA";
    if ( tpl == TPL_Enum::LAPACK )
        return "LAPACK";
    if ( tpl == TPL_Enum::LAPACK_WRAPPERS )
        return "LAPACK_WRAPPERS";
    if ( tpl == TPL_Enum::OPENBLAS )
        return "OPENBLAS";
    if ( tpl == TPL_Enum::LIBMESH )
        return "LIBMESH";
    if ( tpl == TPL_Enum::MATLAB )
        return "MATLAB";
    if ( tpl == TPL_Enum::NETCDF )
        return "NETCDF";
    if ( tpl == TPL_Enum::OGRE )
        return "OGRE";
    if ( tpl == TPL_Enum::PETSC )
        return "PETSC";
    if ( tpl == TPL_Enum::SAMRAI )
        return "SAMRAI";
    if ( tpl == TPL_Enum::SILO )
        return "SILO";
    if ( tpl == TPL_Enum::STACKTRACE )
        return "STACKTRACE";
    if ( tpl == TPL_Enum::SUNDIALS )
        return "SUNDIALS";
    if ( tpl == TPL_Enum::TIMER )
        return "TIMER";
    if ( tpl == TPL_Enum::TRILINOS )
        return "TRILINOS";
    if ( tpl == TPL_Enum::XBRAID )
        return "XBRAID";
    if ( tpl == TPL_Enum::ZLIB )
        return "ZLIB";
    if ( tpl == TPL_Enum::CATCH2 )
        return "CATCH2";
    if ( tpl == TPL_Enum::AMP )
        return "AMP";
    if ( tpl == TPL_Enum::SAMRUTILS )
        return "SAMRUTILS";
    if ( tpl == TPL_Enum::SAMRSOLVERS )
        return "SAMRSOLVERS";
    if ( tpl == TPL_Enum::NULL_TPL )
        return "NULL_TPL";
    return "UNKNOWN";
}


// Get the TPL enum from the name
inline TPL_Enum getTPL( const std::string &tpl )
{
    if ( tpl == "MPI" )
        return TPL_Enum::MPI;
    if ( tpl == "BOOST" )
        return TPL_Enum::BOOST;
    if ( tpl == "THRUST" )
        return TPL_Enum::THRUST;
    if ( tpl == "FFTW" )
        return TPL_Enum::FFTW;
    if ( tpl == "HDF5" )
        return TPL_Enum::HDF5;
    if ( tpl == "UMPIRE" )
        return TPL_Enum::UMPIRE;
    if ( tpl == "RAJA" )
        return TPL_Enum::RAJA;
    if ( tpl == "HYPRE" )
        return TPL_Enum::HYPRE;
    if ( tpl == "KOKKOS" )
        return TPL_Enum::KOKKOS;
    if ( tpl == "CABANA" )
        return TPL_Enum::CABANA;
    if ( tpl == "LAPACK" )
        return TPL_Enum::LAPACK;
    if ( tpl == "LAPACK_WRAPPERS" )
        return TPL_Enum::LAPACK_WRAPPERS;
    if ( tpl == "OPENBLAS" )
        return TPL_Enum::OPENBLAS;
    if ( tpl == "LIBMESH" )
        return TPL_Enum::LIBMESH;
    if ( tpl == "MATLAB" )
        return TPL_Enum::MATLAB;
    if ( tpl == "NETCDF" )
        return TPL_Enum::NETCDF;
    if ( tpl == "OGRE" )
        return TPL_Enum::OGRE;
    if ( tpl == "PETSC" )
        return TPL_Enum::PETSC;
    if ( tpl == "SAMRAI" )
        return TPL_Enum::SAMRAI;
    if ( tpl == "SILO" )
        return TPL_Enum::SILO;
    if ( tpl == "SUNDIALS" )
        return TPL_Enum::SUNDIALS;
    if ( tpl == "STACKTRACE" )
        return TPL_Enum::STACKTRACE;
    if ( tpl == "TIMER" )
        return TPL_Enum::TIMER;
    if ( tpl == "TRILINOS" )
        return TPL_Enum::TRILINOS;
    if ( tpl == "XBRAID" )
        return TPL_Enum::XBRAID;
    if ( tpl == "ZLIB" )
        return TPL_Enum::ZLIB;
    if ( tpl == "CATCH2" )
        return TPL_Enum::CATCH2;
    if ( tpl == "AMP" )
        return TPL_Enum::AMP;
    if ( tpl == "SAMRUTILS" )
        return TPL_Enum::SAMRUTILS;
    if ( tpl == "SAMRSOLVERS" )
        return TPL_Enum::SAMRSOLVERS;
    for ( const auto& tmp : nullTPLs ) {
        if ( tpl == tmp )
            return TPL_Enum::NULL_TPL;
    }
    return TPL_Enum::UNKNOWN;
}


// Get the enabled TPLs
std::vector<TPL_Enum> enabledTPls( )
{
    std::vector<TPL_Enum> tpls;
    std::stringstream ss(TPL_LIST);
    std::string tok;
    while ( getline(ss,tok,';') ) {
        auto tmp = getTPL(tok);
        if ( tmp == TPL_Enum::NULL_TPL )
            continue;
        if ( tmp == TPL_Enum::UNKNOWN ) {
            std::string msg = "Unkown TPL: " + tok;
            throw std::logic_error(msg);
        }
        tpls.push_back( tmp );
    }
    return tpls;
}


// Check if a given TPL was enabled
bool enabled( TPL_Enum tpl )
{
    auto list = enabledTPls( );
    bool found = false;
    for ( auto tmp : list )
        found = found || tmp==tpl;
    return found;
}


#endif

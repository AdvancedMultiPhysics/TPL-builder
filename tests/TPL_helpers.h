#ifndef included_TPL_headers
#define included_TPL_headers

#include "TPLs.h"

#include <string>
#include <stdexcept>


// List of valid TPLs that we can test
enum class TPL_Enum { BOOST, HDF5, HYPRE, KOKKOS, LAPACK, LAPACK_WRAPPERS, 
    LIBMESH, MATLAB, NETCDF, OGRE, PETSC, SAMRAI, SILO, STACKTRACE, 
    SUNDIALS, TIMER, TRILINOS, ZLIB, UNKNOWN };


// Get the string for an TPL enum
inline std::string getName( TPL_Enum tpl )
{
    if ( tpl == TPL_Enum::BOOST )
        return "BOOST";
    if ( tpl == TPL_Enum::HDF5 )
        return "HDF5";
    if ( tpl == TPL_Enum::HYPRE )
        return "HYPRE";
    if ( tpl == TPL_Enum::KOKKOS )
        return "KOKKOS";
    if ( tpl == TPL_Enum::LAPACK )
        return "LAPACK";
    if ( tpl == TPL_Enum::LAPACK_WRAPPERS )
        return "LAPACK_WRAPPERS";
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
    if ( tpl == TPL_Enum::ZLIB )
        return "ZLIB";
    return "UNKNOWN";
}


// Get the TPL enum from the name
inline TPL_Enum getTPL( const std::string &tpl )
{
    if ( tpl == "BOOST" )
        return TPL_Enum::BOOST;
    if ( tpl == "HDF5" )
        return TPL_Enum::HDF5;
    if ( tpl == "HYPRE" )
        return TPL_Enum::HYPRE;
    if ( tpl == "KOKKOS" )
        return TPL_Enum::KOKKOS;
    if ( tpl == "LAPACK" )
        return TPL_Enum::LAPACK;
    if ( tpl == "LAPACK_WRAPPERS" )
        return TPL_Enum::LAPACK_WRAPPERS;
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
    if ( tpl == "ZLIB" )
        return TPL_Enum::ZLIB;
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

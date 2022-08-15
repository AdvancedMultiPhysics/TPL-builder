#ifndef included_TPL_headers
#define included_TPL_headers

#include "TPLS_Tests_TPLs.h"

#include <stdexcept>
#include <string>


// List of valid TPLs that we can test
enum class TPL_Enum {
    AMP,
    BOOST,
    CABANA,
    CATCH2,
    FFTW,
    HDF5,
    HYPRE,
    KOKKOS,
    LAPACK,
    LAPACK_WRAPPERS,
    LIBMESH,
    MATLAB,
    MPI,
    NETCDF,
    OGRE,
    OPENBLAS,
    PETSC,
    QT,
    QWT,
    RAJA,
    SAMRAI,
    SAMRSOLVERS,
    SAMRUTILS,
    SILO,
    STACKTRACE,
    SUNDIALS,
    THRUST,
    TIMER,
    TRILINOS,
    UMPIRE,
    XBRAID,
    ZLIB,
    NULL_TPL,
    UNKNOWN
};


// List of TPLs that are not used for compiling/linking (e.g. cppcheck)
const char* nullTPLs[] = { "CPPCHECK" };


// Get the string for an TPL enum
inline std::string getName( TPL_Enum tpl )
{
    switch ( tpl ) {
    case TPL_Enum::AMP: return "AMP";
    case TPL_Enum::BOOST: return "BOOST";
    case TPL_Enum::CABANA: return "CABANA";
    case TPL_Enum::CATCH2: return "CATCH2";
    case TPL_Enum::FFTW: return "FFTW";
    case TPL_Enum::HDF5: return "HDF5";
    case TPL_Enum::HYPRE: return "HYPRE";
    case TPL_Enum::KOKKOS: return "KOKKOS";
    case TPL_Enum::LAPACK: return "LAPACK";
    case TPL_Enum::LAPACK_WRAPPERS: return "LAPACK_WRAPPERS";
    case TPL_Enum::LIBMESH: return "LIBMESH";
    case TPL_Enum::MATLAB: return "MATLAB";
    case TPL_Enum::MPI: return "MPI";
    case TPL_Enum::NETCDF: return "NETCDF";
    case TPL_Enum::OGRE: return "OGRE";
    case TPL_Enum::OPENBLAS: return "OPENBLAS";
    case TPL_Enum::PETSC: return "PETSC";
    case TPL_Enum::QT: return "QT";
    case TPL_Enum::QWT: return "QWT";
    case TPL_Enum::RAJA: return "RAJA";
    case TPL_Enum::SAMRAI: return "SAMRAI";
    case TPL_Enum::SAMRSOLVERS: return "SAMRSOLVERS";
    case TPL_Enum::SAMRUTILS: return "SAMRUTILS";
    case TPL_Enum::SILO: return "SILO";
    case TPL_Enum::STACKTRACE: return "STACKTRACE";
    case TPL_Enum::SUNDIALS: return "SUNDIALS";
    case TPL_Enum::THRUST: return "THRUST";
    case TPL_Enum::TIMER: return "TIMER";
    case TPL_Enum::TRILINOS: return "TRILINOS";
    case TPL_Enum::UMPIRE: return "UMPIRE";
    case TPL_Enum::XBRAID: return "XBRAID";
    case TPL_Enum::ZLIB: return "ZLIB";
    case TPL_Enum::NULL_TPL: return "NULL_TPL";
    default: return "UNKNOWN";
    }
}


// Get the TPL enum from the name
inline TPL_Enum getTPL( const std::string& tpl )
{
    if ( tpl == "AMP" ) { return TPL_Enum::AMP; }
    if ( tpl == "BOOST" ) { return TPL_Enum::BOOST; }
    if ( tpl == "CABANA" ) { return TPL_Enum::CABANA; }
    if ( tpl == "CATCH2" ) { return TPL_Enum::CATCH2; }
    if ( tpl == "FFTW" ) { return TPL_Enum::FFTW; }
    if ( tpl == "HDF5" ) { return TPL_Enum::HDF5; }
    if ( tpl == "HYPRE" ) { return TPL_Enum::HYPRE; }
    if ( tpl == "KOKKOS" ) { return TPL_Enum::KOKKOS; }
    if ( tpl == "LAPACK" ) { return TPL_Enum::LAPACK; }
    if ( tpl == "LAPACK_WRAPPERS" ) { return TPL_Enum::LAPACK_WRAPPERS; }
    if ( tpl == "LIBMESH" ) { return TPL_Enum::LIBMESH; }
    if ( tpl == "MATLAB" ) { return TPL_Enum::MATLAB; }
    if ( tpl == "MPI" ) { return TPL_Enum::MPI; }
    if ( tpl == "NETCDF" ) { return TPL_Enum::NETCDF; }
    if ( tpl == "OGRE" ) { return TPL_Enum::OGRE; }
    if ( tpl == "PETSC" ) { return TPL_Enum::PETSC; }
    if ( tpl == "QT" ) { return TPL_Enum::QT; }
    if ( tpl == "QWT" ) { return TPL_Enum::QWT; }
    if ( tpl == "RAJA" ) { return TPL_Enum::RAJA; }
    if ( tpl == "OPENBLAS" ) { return TPL_Enum::OPENBLAS; }
    if ( tpl == "SAMRAI" ) { return TPL_Enum::SAMRAI; }
    if ( tpl == "SAMRSOLVERS" ) { return TPL_Enum::SAMRSOLVERS; }
    if ( tpl == "SAMRUTILS" ) { return TPL_Enum::SAMRUTILS; }
    if ( tpl == "SILO" ) { return TPL_Enum::SILO; }
    if ( tpl == "STACKTRACE" ) { return TPL_Enum::STACKTRACE; }
    if ( tpl == "SUNDIALS" ) { return TPL_Enum::SUNDIALS; }
    if ( tpl == "THRUST" ) { return TPL_Enum::THRUST; }
    if ( tpl == "TIMER" ) { return TPL_Enum::TIMER; }
    if ( tpl == "TRILINOS" ) { return TPL_Enum::TRILINOS; }
    if ( tpl == "UMPIRE" ) { return TPL_Enum::UMPIRE; }
    if ( tpl == "XBRAID" ) { return TPL_Enum::XBRAID; }
    if ( tpl == "ZLIB" ) { return TPL_Enum::ZLIB; }

    for ( const auto& tmp : nullTPLs ) {
        if ( tpl == tmp ) { return TPL_Enum::NULL_TPL; }
    }
    return TPL_Enum::UNKNOWN;
}


// Get the enabled TPLs
std::vector<TPL_Enum> enabledTPls()
{
    std::vector<TPL_Enum> tpls;
    std::stringstream ss( TPL_LIST );
    std::string tok;
    while ( getline( ss, tok, ';' ) ) {
        auto tmp = getTPL( tok );
        if ( tmp == TPL_Enum::NULL_TPL ) continue;
        if ( tmp == TPL_Enum::UNKNOWN ) {
            std::string msg = "Unkown TPL: " + tok;
            throw std::logic_error( msg );
        }
        tpls.push_back( tmp );
    }
    return tpls;
}


// Check if a given TPL was enabled
bool enabled( TPL_Enum tpl )
{
    auto list  = enabledTPls();
    bool found = false;
    for ( auto tmp : list )
        found = found || tmp == tpl;
    return found;
}


#endif

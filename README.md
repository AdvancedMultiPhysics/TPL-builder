This project is a CMake wrapper that will download and build the
dependencies for SAMRApps and AMP.  
This may include AMP or SAMRAI and it's dependencies.
Note: the user can choose to build or not build AMP/SAMRUtils in addition to the TPLs.

This help file can be viewed by any text editor or by passing "-D HELP=1"
to CMake as one of the arguments in the configure scripts (discussed later).

This assumes the users is familiar with basic builds on their system and
CMake is already installed.  If CMake is required it can be obtained from
   http://www.cmake.org/cmake/resources/software.html
Note that we require CMake 3.10 or higher. 

If the recommended versions of the TPLs are required they can be obtained from
https://bitbucket.org/AdvancedMultiPhysics/tpl-builder/downloads

To begin there are 3 download/install paths for each third party library (TPL).
The TPL can be downloaded from bitbucket as part of the configure/build 
process (default), a source path to the TPL source tree can be provided,
or an existing build can be used (advanced users only).  It is strongly
recommended that new users build all TPLs from source using the provided TPLs,
either pre-downloaded or using the download option from the configure script.

Note:  The automatic download of TPLs from bitbucket is still being developed.  
Users should pre-download all TPLs into a common folder and then specify their
locate using TPL_URL.  

The current TPL list and tested versions are:
    BLAS/LAPACK (any version, NOTE: only netlib versions <= 3.5.0 work with Trilinos 12.10.1)
    ZLIB
    HDF5 (1.12.0)
    UMPIRE (6.0.0)
    RAJA (0.8.0)
    KOKKOS (3.5.00)
    CABANA (0.4.0)
    HYPRE (2.24.0)
    PETSc (3.16.4)
    TRILINOS (13.2.1)
    SAMRAI (4.1.0-modified)
    LIBMESH (1.5.1)
    SUNDIALS (2.6.2)
    SCALAPACK (2.0.2)
    MUMPS (5.0.1)
    METIS (5.1.0)
    PARMETIS (4.0.3)
    SUPERLU_DIST (5.0.0)
    LMDB

Note:  For the purposes of the TPL builder BLAS/LAPACK are configured as one TPL (LAPACK).
A user may still provided their own libraries to use for blas/lapack which may
be installed in different locations.  In this case the user would provide the 
additional flags (BLAS_INSTALL_DIR, LAPACK_INSTALL_DIR, BLAS_LIB, LAPACK_LIB) 
specified in the LAPACK section of this document.  Installations such as ACML and MKL 
are supported by specifying their installed location through LAPACK_INSTALL_DIR.  


To begin the configure/build process there are 4 paths that we will refer to in this document:
1) TPL_BUILDER - The source tree for the TPL_BUILDER project (path to this file)
2) TPL_SRC_DIR - The source tree for each TPL if provided.  If we are using the automatic
                 download, this will be created by the builder.  
                 There are 3 variations on this variable (TPL_SRC_DIR, TPL_URL, TPL_INSTALL_DIR)
                 that will be described later. 
                 Note: replace TPL with the TPL name (e.g. BOOST_SRC_DIR). 
3) BUILD_DIR   - The build directory where we will execute the cmake command and 
                 build all TPLs.  This should NOT be in any of the source directories
                 including the TPL_BUILDER directory.  
                 Note: this is always the current directory where we call the cmake command.
                 It is NOT set in the configure script, but is the directory from which 
                 we call the script.  It is also the directory where we will call make.
4) INSTALL_DIR - The install path for the TPLs.  If this is not provided, it will default
                 to the current build tree.

An example folder layout is:
root_dir
    | -- TPL_BUILDER
    | -- TPL_ROOT
    |       | -- petsc-3.16.4.tar.gz
    |       | -- SAMRAI_v4.1.0
    |       | -- AMP
    |       | ...
    | -- build
    |       | -- debug
    |       | -- opt
    | -- install
            | -- debug
            | -- opt

In this example layout if we are creating an opt installation where
TPL_BUILDER=root_dir/TPL_BUILDER,
TPL_SRC_DIR=root_dir/TPL_BUILDER, 
PETSC_URL=root_dir/TPL_ROOT/petsc-3.16.4.tar.gz,
SAMRAI_SRC_DIR=root_dir/TPL_ROOT/SAMRAI_v4.1.0, 
AMP_SRC_DIR=root_dir/TPL_ROOT/AMP, 
BUILD_DIR=root_dir/build/opt, 
and INSTALL_DIR=root_dir/install/opt.  

We would be operating from root_dir/build/opt.

A sample configure script for SAMRAI is:
    cmake                                               \
        -D CMAKE_BUILD_TYPE=Release                     \
        -D C_COMPILER=mpicc                             \
        -D CXX_COMPILER=mpic++                          \
        -D Fortran_COMPILER=mpif90                      \
        -D CFLAGS="-fPIC"                               \
        -D CXXFLAGS="-fPIC"                             \
        -D FFLAGS="-fPIC"                               \
        -D LDFLAGS=""                                   \
        -D ENABLE_STATIC:BOOL=ON                        \
        -D ENABLE_SHARED:BOOL=OFF                       \
        -D INSTALL_DIR:PATH=${INSTALL_DIR}              \
        -D PROCS_INSTALL=4                              \
        -D TPL_LIST:STRING="LAPACK;ZLIB;PETSC;HDF5;HYPRE;TIMER;SAMRAI" \
        -D LAPACK_INSTALL_DIR="${TPL_ROOT}/lapack"      \
        -D ZLIB_INSTALL_DIR="/usr/local/lib"            \
        -D PETSC_URL="${TPL_ROOT}/petsc-3.16.4.tar.gz"  \
        -D HDF5_URL="${TPL_ROOT}/hdf5-1.12.0.tar.gz"    \
	-D HDF_VERSION="1.12.0"                         \
        -D HYPRE_URL="${TPL_ROOT}/hypre-2.24.0.tar.gz"  \
        -D SAMRAI_SRC_DIR="${TPL_ROOT}/SAMRAI-v4.1.0"   \
        -D TIMER_SRC_DIR="${TPL_ROOT}/timerutility"     \
        ${TPL_BUILDER}


A sample debug configure script for AMP is:
    export TPL_BUILDER=/projects/AMP/TPLs/TPL-builder
    export TPL_ROOT=/packages/TPLs/src
    export INSTALL_DIR=/projects/AMP/TPLs/install/debug

    cmake                                                              \
        -D CMAKE_BUILD_TYPE=Debug                                      \
        -D C_COMPILER=mpicc                                            \
        -D CFLAGS="-fPIC"                                              \
        -D CXX_COMPILER=mpic++                                         \
        -D CXXFLAGS="-fPIC"                                            \
        -D CXX_STD=11                                                  \
        -D Fortran_COMPILER=mpif90                                     \
        -D FFLAGS="-fPIC"                                              \
        -D LDFLAGS=""                                                  \
        -D ENABLE_STATIC:BOOL=ON                                       \
        -D ENABLE_SHARED:BOOL=OFF                                      \
        -D INSTALL_DIR:PATH=${INSTALL_DIR}                             \
        -D PROCS_INSTALL=4                                             \
        -D TPL_LIST:STRING="TIMER;LAPACK;ZLIB;PETSC;HDF5;SILO;HYPRE;LIBMESH;TRILINOS;SUNDIALS" \
        -D LAPACK_URL="http://www.netlib.org/lapack/lapack-3.5.0.tgz"  \
        -D ZLIB_INSTALL_DIR="/usr/local/lib"                           \
        -D PETSC_URL="${TPL_ROOT}/petsc-3.16.4.tar.gz"                 \
        -D HDF5_URL="${TPL_ROOT}/hdf5-1.12.0.tar.gz"                   \
	-D HDF_VERSION="1.12.0"                                        \
        -D SILO_URL="${TPL_ROOT}/silo-4.9.1.tar.gz"                    \
        -D HYPRE_URL="${TPL_ROOT}/hypre-2.24.0.tar.gz"                 \
        -D LIBMESH_URL="${TPL_ROOT}/libmesh.tar.gz"                    \
        -D TRILINOS_URL="${TPL_ROOT}/trilinos-13.2.0-Source.tar.gz"    \
        -D TRILINOS_PACKAGES="Epetra;EpetraExt;Thyra;Tpetra;ML;MueLu;Kokkos;Amesos;Ifpack;Ifpack2;Belos;NOX;Stratimikos" \
        -D SUNDIALS_URL="${TPL_ROOT}/sundials-2.6.2.tar.gz"            \
        -D AMP_SRC_DIR="/projects/AMP/AMP"                             \
        -D AMP_DATA:PATH=/projects/AMP/AMP-Data                        \
        -D TIMER_SRC_DIR="${TPL_ROOT}/timerutility"                    \
        ${TPL_BUILDER}


More sample script may be found in the scripts subdirectory.


There are a number of variables that can be passed to the configure process.
Unless otherwise noted, all variables are optional.  
The important variables are:
    CMAKE_BUILD_TYPE - The type of build we are performing (Debug,Release,...) (Required)
                       Note that we will automatically set default flags based on 
                       the build type.
    C_COMPILER       - The compiler to use for compiling C code
    CXX_COMPILER     - The compiler to use for compiling C++ code
    Fortran_COMPILER - The compiler to use for compiling Fortran code
    CFLAGS           - Any user-defined flags for C code
    CXXFLAGS         - Any user-defined flags for C++ code
    CXX_STD          - Specify the C++ standard to use (98, 11, 14, 17, NONE)
    FFLAGS           - Any user-defined flags for Fortran code
    LDFLAGS          - Any user-defined flags for linking
    ENABLE_STATIC    - Do we want to compile static libraries (default)
    ENABLE_SHARED    - Do we want to compile shared libraries
                       Note: we can only build one type of library (shared or static) at this time
    ENABLE_GXX_DEBUG - Do we want to enable GLIBCXX_DEBUG flags (disabled by default)
    USE_OPENMP       - Turn on OpenMP
    USE_CUDA         - Turn on CUDA
    CMAKE_SYSTEM_NAME - The system type: Linux, Generic, etc.
    CMAKE_SHARED_LINKER_FLAGS - Linker flags for shared libraries
    INSTALL_DIR      - The install path where we want to install the libraries
    PROCS_INSTALL    - The number of processors to use to compile each TPL.
                       Note: we specify the number of processors to use for parallel build
                       through this flag which will be passed to the subsequent build systems.
                       specifying "make -j N" at the top level will build N TPLs in parallel,
                       each with ${PROCS_INSTALL} procs.  
                       If this is not specified the builds will default to serial builds.  
    TPL_LIST         - The list of TPLs to build.  By default all required TPLs will be built. 
                       Note: if provided the TPL_LIST must be in order of the required dependencies.
                       Failure to do so will result in a cmake error at configure time:
                           CMake Error at ExternalProject.cmake (get_property):
                           get_property could not find TARGET LAPACK.  Perhaps it has not yet been created.
                       The order of the subsequent TPL_VARIABLES does not matter.

The final argument must always point to the TPL_BUILDER directory.  


For each TPL, there are additional arguments that may be provided.  These arguments control
how that that TPL is built.  
    TPL_URL          - URL specifying the location to download the TPL.  
                       This URL may be a URL of the form 
                          http://zlib.net/zlib-1.2.8.tar.gz
                       or may point to a local .tar.gz file or directory where the files have been 
                       untared.  By default all TPLs will be downloaded from bitbucket.
    TPL_SRC_DIR      - User specified directory for the TPL.  This is useful if the user
                       wants to use a different version, or pre-download the TPL for 
                       performance or firewall reasons.  
    TPL_INSTALL_DIR  - Directory where an existing TPL is located.  This should
                       be used by advanced users who wish to reuse libraries.
                       It is the responsibility of the user to ensure the TPL was installed
                       properly with the correct complier and compiler options to be 
                       compatible with the other software that will be installed.  
    TPL_TEST         - Run the TPL tests as part of the build (if they exist).  Default is false. 



Special TPL FLAGS:
DISABLE_CLEAN - If set this will disable individual TPLs from running their "make clean"
    as part of the regular build process.  This can save time building the TPLs at the cost
    of additional storage.  Commonly set for nightly builds.  Default value is FALSE (do not disable clean)
BOOST:
    BOOST_ONLY_COPY_HEADERS - Only copy the headers from the URL/SRC/INSTALL location.
                       If this flag is set, we will copy the include directory and will not 
                       configure or compile boost.  Note that the headers must exist in the 
                       include directory for this to work, and should not be used if boost
                       libraries are needed.
ZLIB:
    ZLIB_INCLUDE_DIR - If ZLIB_INSTALL_DIR is specified, this indicates an alternative path for zlib.h
    ZLIB_LIB_DIR     - If ZLIB_INSTALL_DIR is specified, this indicates an alternative path for libz
LAPACK:
    LAPACK_INSTALL_DIR - This specifies the directory to search for blas/lapack/acml/mkl/etc.  
    BLAS_INSTALL_DIR - If LAPACK_INSTALL_DIR is specified, this indicates an alternative path for blas
    BLAS_LIB         - If LAPACK_INSTALL_DIR is specified, this indicates the library to use (e.g. libblas.a)
    LAPACK_LIB       - If LAPACK_INSTALL_DIR is specified, this indicates the library to use (e.g. liblapack.a)
HDF5:
    HDF5_ENABLE_CXX - Enable cxx support in hdf5 (default is disabled)
    HDF5_ENABLE_UNSUPPORTED - Enable unsupported options in hdf5
    HDF5_VERSION    - Specify HDF5 version being used (required)
KOKKOS:
    KOKKOS_ARCH_FLAGS - Specify CUDA architecture to use
    KOKKOS_CXX_STD -- specify what C++ standard to use (11, 14,17) etc
CABANA:
    CABANA_VERSION - Specify Cabana version
RAJA
    RAJA_CUDA_ARCH_FLAGS - Specify CUDA architecture to use
TRILINOS:
    TRILINOS_PACKAGES - List of packages to add (will default to Trilinos_ENABLE_ALL if not specified)
    TRILINOS_EXTRA_PACKAGES - List of extra pacakges (e.g. EPETRA)
    TRILINOS_EXTRA_REPOSITORIES - List of extra repositories
    TRILINOS_EXTRA_FLAGS - List of extra flags (e.g. "-DBUILD_SHARED_LIBS=OFF;-DTPL_ENABLE_MPI=ON" )
    TRILINOS_EXTRA_LAPACK_LIBRARIES - Semicolon separated list of extra libraries required for eg with Intel ifcore, ifport etc
SAMRAI:
    SAMRAI_TEST - Enable samrai tests (may take a while to complete)
    SAMRAI_DOCS - Enable/disable building and installing the SAMRAI doxygen documentation (enabled by default)
    SAMRAI_USE_UMPIRE - Enable use of Umpire with SAMRAI
    SAMRAI_USE_RAJA   - Enable use of Raja with SAMRAI
SAMRUTILS:
    DISABLE_THREAD_CHANGES - Disable all threading support
    TEST_MAX_PROCS   - Disables all tests that require more than TEST_MAX_PROCS processors
AMP:
    AMP_Data         - Path to the data directory for AMP
LIBMESH:
    LIBMESH_MPI_PATH - path to mpi that needs to be explicitly specified for libmesh

To build:
    cd to the build directory
    run the configure script
    run "make"
Note that "make" will build all TPLs.  
To build a specific TPL the command "make TPL" can be used.  This will build the specified 
    TPL and any required dependencies. 
"make clean" will clean all TPLs
"make distclean" will remove all build files, CMake files, and installed files.
"make TPL-clean" will clean a specific TPL
To rebuild a TPL, use "make TPL-clean" followed by "make TPL"

Additionally all TPLs are setup to perform out of source builds.  If a given TPL does not
support out of source builds (e.g. boost), then the source directory will be copied to a
temporary directory for building.  This insures that we can perform multiple builds in 
parallel (e.g. Debug and Release) without corrupting the build or src trees.

Once the TPLs are successfully built it is time to build 
AMP: https://bitbucket.org/AdvancedMultiPhysics/amp/wiki/AMP_Build_Instructions
or 
SAMRUtils: https://bitbucket.org/SAMRApps/samrutils

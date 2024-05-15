#!/bin/bash

export PKG_ROOT=~/src/xcap/solvers/packages
export TPL_BUILDER=~/src/xcap/solvers/tpl-builder
export ARCHIVE_DIR=${PKG_ROOT}/archives
export MPI_VER=cray-mpich
export COMPILER_VER=hipcc

export BUILD_TYPE=Debug
export BUILD_SUFFIX=debug

# export CC=mpicc
# export CXX=mpicxx
# export FC=mpif90

# export OMPI_CC=hipcc
# export OMPI_CXX=hipcc
# export OMPI_FC=gfortran
export MPICH_CC=hipcc
export MPICH_CXX=hipcc
# export MPICH_CCC=hipcc
# export MPICH_F77=gfortran
# export MPICH_F90=gfortran

export BUILD_DIR=/tmp/buildtpl/
export INSTALL_DIR=${PKG_ROOT}/install/amp-tpls-${COMPILER_VER}-${BUILD_SUFFIX}
# export INSTALL_DIR=${PKG_ROOT}/install/amp-tpls-${MPI_VER}-${COMPILER_VER}-${BUILD_SUFFIX}
# export MPI_INSTALL_DIR=${PKG_ROOT}/install/${MPI_VER}-${COMPILER_VER}-opt

echo "TPLS will be installed in " $INSTALL_DIR

# for darwin 
    #    -D CXXFLAGS="--gcc-toolchain=/projects/opt/rhel8/x86_64/gcc/12.2.0"                                          \

if [ ! -d ${BUILD_DIR} ] ; then
    mkdir ${BUILD_DIR}
fi

rm -Irf ${BUILD_DIR}

cmake -S ~/src/xcap/solvers/tpl-builder             \
    -B ${BUILD_DIR}  \
    -D CMAKE_BUILD_TYPE=${BUILD_TYPE}                            \
    -D CXX_STD=17                                                \
    -D LDFLAGS=""                                                \
    -D MPIEXEC=mpirun                                            \
    -D C_COMPILER=mpicc \
    -D CXX_COMPILER=mpicxx \
    -D Fortran_COMPILER=mpif90 \
    -D CFLAGS="-fPIC"                                            \
    -D CXXFLAGS="-fPIC" \
    -D FFLAGS="-fPIC"                                            \
    -D USE_MPI::BOOL=ON \
    -D USE_HIP::BOOL=ON \
    -D USE_OPENMP::BOOL=OFF                                      \
    -D ENABLE_STATIC:BOOL=ON                                     \
    -D ENABLE_SHARED:BOOL=OFF                                    \
    -D INSTALL_DIR:PATH=${INSTALL_DIR}                           \
    -D TPL_LIST:STRING="CATCH2;BOOST;LAPACK;ZLIB;CPPCHECK;KOKKOS;CABANA;HDF5;FFTW;PETSC;HYPRE;UMPIRE;RAJA;LIBMESH;SUNDIALS;XBRAID" \
    -D THRUST_URL="${ARCHIVE_DIR}/thrust-2.1.0.tar.gz"                 \
    -D BOOST_URL="${ARCHIVE_DIR}/boost_1_84_0.tar.gz"            \
    -D BOOST_ONLY_COPY_HEADERS:BOOL=ON                           \
    -D CATCH2_URL="${ARCHIVE_DIR}/catch2.tar.gz"                 \
    -D LAPACK_URL="${ARCHIVE_DIR}/lapack-3.11.tar.gz"          \
    -D KOKKOS_URL="${ARCHIVE_DIR}/kokkos-4.3.00.tar.gz"          \
    -D CABANA_URL="${ARCHIVE_DIR}/Cabana-0.5.0.tar.gz"           \
    -D CABANA_VERSION="0.5.0"                                    \
    -D CPPCHECK_INSTALL_DIR="/g/g16/romero52/src/xcap/solvers/packages/install/cppcheck" \
    -D ZLIB_URL="${ARCHIVE_DIR}/zlib-1.2.12.tar.gz"              \
    -D HDF5_URL="${ARCHIVE_DIR}/hdf5-1.12.0.tar.bz2"             \
    -D HDF5_VERSION="1.12.0"                                     \
    -D FFTW_URL="${ARCHIVE_DIR}/fftw-3.3.10.tar.gz"               \
    -D UMPIRE_URL="${ARCHIVE_DIR}/umpire-2024.02.1.tar.gz"       \
    -D RAJA_URL="${ARCHIVE_DIR}/RAJA-v2024.02.1.tar.gz"          \
    -D HYPRE_USE_UMPIRE:BOOL=OFF                                 \
    -D HYPRE_USE_OPENMP:BOOL=OFF                                 \
    -D HYPRE_HIP_ARCH="gfx90a"\
    -D HYPRE_URL="${ARCHIVE_DIR}/hypre-2.31.0.tar.gz"            \
    -D LIBMESH_URL="${ARCHIVE_DIR}/libmesh-1.7.1.tar.gz"         \
    -D SUNDIALS_URL="${ARCHIVE_DIR}/sundials-2.6.2.tar.gz"       \
    -D TRILINOS_URL="${ARCHIVE_DIR}/trilinos-13-4-1.tar.gz"      \
    -D TRILINOS_PACKAGES="Epetra;EpetraExt;Thyra;ML;Kokkos;Amesos;Ifpack;Ifpack2;Belos;NOX;Stratimikos" \
    -D PETSC_VERSION="3.19.0"                                    \
    -D PETSC_URL="${ARCHIVE_DIR}/petsc-3.20.0.tar.gz"            \
    -D XBRAID_URL="${ARCHIVE_DIR}/xbraid.tar.gz"                 \
    -D SAMRAI_URL="${ARCHIVE_DIR}/SAMRAI-v4.2.1.modified.tar.gz"                 \
    -D SAMRAI_ENABLE_TESTS:BOOL=OFF                              \
    -D SAMRAI_USE_UMPIRE:BOOL=ON                                 \
    -D SAMRAI_USE_RAJA:BOOL=ON                                   \
    -D SAMRAI_HIP_ARCH_FLAGS="gfx90a" \
    -D RAJA_HIP_ARCH_FLAGS="gfx90a" \
    -D SILO_URL="${ARCHIVE_DIR}/Silo-4.10.3RC.modified.tar.gz"   \
    -D TIMER_SRC_DIR="${PKG_ROOT}/src/timerutility"              \
    -D DISABLE_ALL_TESTS=on \
    ${TPL_BUILDER}

cmake --build ${BUILD_DIR} -j
# make -j 24 VERBOSE=1

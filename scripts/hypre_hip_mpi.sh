#!/bin/bash
#module use ~/Projects/XCAP/spack/share/spack/modules/linux-rhel8-haswell/
#module load openmpi/5.0.3-gcc-12.2.0-snnw3wr
#module load gcc/12.2.0 cmake/3.29.2 rocm/6.0.2 
module load cmake/3.29.2 rocm/6.0.2 openmpi/5.0.2-gcc_13.2.0 
#module load  cmake/3.29.2 rocm/6.0.2 openmpi/4.1.5-gcc_12.2.0
#module load cmake/3.29.2 rocm/6.0.2 mpich/3.4.3-gcc_11.2.0
module list

mpicc -show

ompi_info | grep "MPI extensions"
ucx_info -v

export TPL_BUILDER=~/Projects/XCAP/tpl-builder
export ARCHIVE_DIR=~/Projects/XCAP/archives
export MPI_VER=openmpi
export COMPILER_VER=hipcc

export BUILD_TYPE=Debug
export BUILD_SUFFIX=debug

export CC=mpicc
export CXX=mpicxx
export FC=mpifort

export OMPI_CC=hipcc
export OMPI_CXX=hipcc
export OMPI_FC=gfortran

export MPICH_CC=hipcc
export MPICH_CXX=hipcc

#export CUFLAGS="-O2 -x hip -std=c++17 -I/projects/opt/rhel8/x86_64/openmpi/5.0.2-gcc_13.2.0/include"

# export MPICH_CCC=hipcc
# export MPICH_F77=gfortran
# export MPICH_F90=gfortran

export BUILD_DIR=~/Projects/XCAP/tpl-builder/build
export INSTALL_DIR=~/Projects/XCAP/install/amp-tpls-${COMPILER_VER}-${BUILD_SUFFIX}
# export INSTALL_DIR=${PKG_ROOT}/install/amp-tpls-${MPI_VER}-${COMPILER_VER}-${BUILD_SUFFIX}
# export MPI_INSTALL_DIR=${PKG_ROOT}/install/${MPI_VER}-${COMPILER_VER}-opt

echo "TPLS will be installed in " $INSTALL_DIR

# for darwin 
    #    -D CXXFLAGS="--gcc-toolchain=/projects/opt/rhel8/x86_64/gcc/12.2.0"                                          \

if [ ! -d ${BUILD_DIR} ] ; then
    mkdir ${BUILD_DIR}
fi

rm -Irf ${BUILD_DIR}

cmake -S ~/Projects/XCAP/tpl-builder             \
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
    -D TPL_LIST:STRING="LAPACK;HYPRE"     \
    -D LAPACK_URL="${ARCHIVE_DIR}/lapack-3.10.0.tar.gz"     \
    -D HYPRE_USE_UMPIRE:BOOL=OFF                                 \
    -D HYPRE_USE_OPENMP:BOOL=OFF                                 \
    -D HYPRE_HIP_ARCH="gfx90a"\
    -D CMAKE_EXPORT_COMPILE_COMMANDS=TRUE \
    -D HYPRE_URL="${ARCHIVE_DIR}/hypre-2.31.0.tar.gz"   \
    -D DISABLE_ALL_TESTS=ON \
    ${TPL_BUILDER}

cmake --build ${BUILD_DIR} -j
#make -j 24 VERBOSE=1
mpicc -show
mpicxx -show

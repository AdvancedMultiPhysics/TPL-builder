# Set some CMake properties
CMAKE_MINIMUM_REQUIRED(VERSION 2.8)


MESSAGE("================")
MESSAGE("Configuring TPLS")
MESSAGE("================")


# Check if we are asking for help
IF ( HELP )
    UNSET( HELP CACHE )
    FILE(READ README.txt TMP )
    MESSAGE("")
    MESSAGE("${TMP}")
    MESSAGE(FATAL_ERROR)
ENDIF()


# Set the compilers (must be done before PROJECT)
IF ( NOT CMAKE_C_COMPILER AND C_COMPILER )
    SET( CMAKE_C_COMPILER "${C_COMPILER}" )
ENDIF()
IF ( NOT CMAKE_CXX_COMPILER AND CXX_COMPILER )
    SET( CMAKE_CXX_COMPILER "${CXX_COMPILER}" )
ENDIF()
IF ( NOT CMAKE_Fortran_COMPILER AND Fortran_COMPILER )
    SET( CMAKE_Fortran_COMPILER "${Fortran_COMPILER}" )
ELSEIF ( NOT CMAKE_Fortran_COMPILER AND FORTRAN_COMPILER )
    SET( CMAKE_Fortran_COMPILER "${FORTRAN_COMPILER}" )
ENDIF()


# Set the project name
PROJECT( TPLS )


# Set the install path
IF( PREFIX )
    SET( CMAKE_INSTALL_PREFIX ${PREFIX} )
ELSEIF( INSTALL_DIR )
    SET( CMAKE_INSTALL_PREFIX ${INSTALL_DIR} )
ELSEIF( TPL_INSTALL_DIR )
    SET( CMAKE_INSTALL_PREFIX ${TPL_INSTALL_DIR} )
ELSE()
    SET( CMAKE_INSTALL_PREFIX ${CMAKE_CURRENT_BINARY_DIR} )
ENDIF()
MESSAGE("Installing TPLs in: ${CMAKE_INSTALL_PREFIX}")


# Create a cmake file that can be included from other projects
FILE( WRITE "${CMAKE_INSTALL_PREFIX}/TPLs.cmake" "# This file sets cmake variables that specify the locations of TPLs\n")
FILE( APPEND "${CMAKE_INSTALL_PREFIX}/TPLs.cmake" "# It may also include comments for record information on how the TPLs were compiled\n")


# Enable the desired languages
ENABLE_LANGUAGE(C)
ENABLE_LANGUAGE(CXX)
ENABLE_LANGUAGE(Fortran)


# Include CMake files
INCLUDE(ExternalProject)
INCLUDE(macros.cmake)


# SET the global compile and link flags
IDENTIFY_COMPILER()
SET_COMPILE_FLAGS()


# Set TPL list
IF ( NOT TPL_LIST )
    SET( TPL_LIST "BOOST;LAPACK;ZLIB;PETSC;HDF5;HYPRE;SAMRAI" )
ENDIF()
STRING( REPLACE "," ";" TPL_LIST "${TPL_LIST}" )
FILE( APPEND "${CMAKE_INSTALL_PREFIX}/TPLs.cmake" "\n# TPL_LIST\nSET(TPL_LIST \"${TPL_LIST}\")\n")


# Set TPL defaults
SET_DEFAULT_TPL( ZLIB  URL http://zlib.net/zlib-1.2.8.tar.gz )
SET_DEFAULT_TPL( BOOST URL https://bitbucket.org/samrapps/samrbuilder/downloads/boost_1_47_0.tar.gz )
SET_DEFAULT_TPL( HDF5  URL https://bitbucket.org/samrapps/samrbuilder/downloads/hdf5-1.8.12.tar.gz  )
SET_DEFAULT_TPL( HYPRE URL https://bitbucket.org/samrapps/samrbuilder/downloads/hypre-2.4.0b.tar.gz )


# Configure TPLs
FOREACH( TPL ${TPL_LIST} )
    FILE( APPEND "${CMAKE_INSTALL_PREFIX}/TPLs.cmake" "\n")
    MESSAGE_TPL("Configuring ${TPL}")
    INCLUDE(TPLs/${TPL}.cmake)
    SET( ${TPL_LIST}_ENABLE true )
ENDFOREACH()
FILE( APPEND "${CMAKE_INSTALL_PREFIX}/TPLs.cmake" "\n")


# Add distclean
ADD_DISTCLEAN()



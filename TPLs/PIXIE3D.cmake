# This will configure and build PIXIE3D
# User can configure the source path by speficfying PIXIE3D_SRC_DIR,
#    the download path by specifying PIXIE3D_URL, or the installed 
#    location by specifying PIXIE3D_INSTALL_DIR


# Intialize download/src/install vars
SET( PIXIE3D_BUILD_DIR "${CMAKE_BINARY_DIR}/PIXIE3D-prefix/src/PIXIE3D-build" )
IF ( PIXIE3D_URL ) 
    MESSAGE_TPL("   PIXIE3D_URL = ${PIXIE3D_URL}")
    SET( PIXIE3D_SRC_DIR "${CMAKE_BINARY_DIR}/PIXIE3D-prefix/src/PIXIE3D-src" )
    SET( PIXIE3D_CMAKE_DOWNLOAD_DIR   "${PIXIE3D_BUILD_DIR}" )
    SET( PIXIE3D_CMAKE_SOURCE_DIR     "${PIXIE3D_BUILD_DIR}" )
    SET( PIXIE3D_CMAKE_INSTALL_DIR "${CMAKE_INSTALL_PREFIX}/pixie3d" )
    SET( CMAKE_BUILD_PIXIE3D TRUE )
ELSEIF ( PIXIE3D_SRC_DIR )
    VERIFY_PATH("${PIXIE3D_SRC_DIR}")
    MESSAGE_TPL("   PIXIE3D_SRC_DIR = ${PIXIE3D_SRC_DIR}"    )
    SET( PIXIE3D_CMAKE_URL            "${PIXIE3D_SRC_DIR}"   )
    SET( PIXIE3D_CMAKE_DOWNLOAD_DIR   "${PIXIE3D_BUILD_DIR}" )
    SET( PIXIE3D_CMAKE_SOURCE_DIR     "${PIXIE3D_BUILD_DIR}" )
    SET( PIXIE3D_CMAKE_INSTALL_DIR "${CMAKE_INSTALL_PREFIX}/pixie3d" )
    SET( CMAKE_BUILD_PIXIE3D TRUE )
ELSEIF ( PIXIE3D_INSTALL_DIR ) 
    SET( PIXIE3D_CMAKE_INSTALL_DIR "${PIXIE3D_INSTALL_DIR}" )
    SET( CMAKE_BUILD_PIXIE3D FALSE )
ELSE()
    MESSAGE(FATAL_ERROR "Please specify PIXIE3D_SRC_DIR, PIXIE3D_URL, or PIXIE3D_INSTALL_DIR")
ENDIF()
FILE( MAKE_DIRECTORY "${PIXIE3D_CMAKE_INSTALL_DIR}" )
SET( PIXIE3D_INSTALL_DIR "${PIXIE3D_CMAKE_INSTALL_DIR}" )
MESSAGE_TPL( "   PIXIE3D_INSTALL_DIR = ${PIXIE3D_INSTALL_DIR}" )
FILE( APPEND "${CMAKE_INSTALL_PREFIX}/TPLs.cmake" "SET(PIXIE3D_INSTALL_DIR \"${PIXIE3D_INSTALL_DIR}\")\n" )


# Configure PIXIE3D
IF ( CMAKE_BUILD_PIXIE3D )
    SET( PIXIE_ENV )
    SET( PIXIE_ENV ${PIXIE_ENV} "PETSC_DIR=${PETSC_INSTALL_DIR}" PETSC_ARCH= )
    SET( PIXIE_ENV ${PIXIE_ENV} SAMR=t SAMR_IMP=t "SAMRSOLVERS_HOME=${SAMRSOLVERS_INSTALL_DIR}" )
    SET( PIXIE_ENV ${PIXIE_ENV} "FC=${CMAKE_Fortran_COMPILER}" )
    IF ( ${CMAKE_BUILD_TYPE} STREQUAL "Debug" )
        SET( PIXIE_ENV ${PIXIE_ENV} OPT=O )
    ELSEIF ( ${CMAKE_BUILD_TYPE} STREQUAL "Release" )
        SET( PIXIE_ENV ${PIXIE_ENV} OPT=g )
    ELSE()
        MESSAGE ( FATAL_ERROR "Unknown CMAKE_BUILD_TYPE=${CMAKE_BUILD_TYPE}" )
    ENDIF()
    SET( PIXIE_ENV ${PIXIE_ENV} HDF5=t "HDF5_INC=${HDF5_INSTALL_DIR}/include" "HDF5_MOD=${HDF5_INSTALL_DIR}/include" )
    SET( PIXIE_ENV ${PIXIE_ENV} "COMMONDIR=${PIXIE3D_BUILD_DIR}/common" )
    SET( PIXIE_ENV ${PIXIE_ENV} MODFLAG=-I ADDMODFLAG=-I )
ENDIF()


# Build pixie3d
IF ( CMAKE_BUILD_PIXIE3D )
    EXTERNALPROJECT_ADD(
        PIXIE3D
        URL                 "${PIXIE3D_CMAKE_URL}"
        DOWNLOAD_DIR        "${PIXIE3D_CMAKE_DOWNLOAD_DIR}"
        DOWNLOAD_COMMAND    ""
        SOURCE_DIR          "${PIXIE3D_CMAKE_SOURCE_DIR}"
        UPDATE_COMMAND      ""
        CONFIGURE_COMMAND   make ${PIXIE_ENV} setup VERBOSE=1
        BUILD_COMMAND       make ${PIXIE_ENV} VERBOSE=1
        BUILD_IN_SOURCE     1
        INSTALL_COMMAND     "" #make ${PIXIE_ENV} install
        DEPENDS             SAMRSOLVERS HDF5
        LOG_DOWNLOAD 1   LOG_UPDATE 1   LOG_CONFIGURE 1   LOG_BUILD 1   LOG_INSTALL 1   LOG_TEST 1
        ALWAYS_DOWNLOAD                                   ALWAYS_BUILD  ALWAYS_INSTALL  ALWAYS_TEST
    )
    EXTERNALPROJECT_ADD_STEP(
        PIXIE3D
        copy-src
        COMMENT             "Copy src files"
        COMMAND             ${CMAKE_COMMAND} -E copy_directory "${PIXIE3D_CMAKE_URL}/src" "${PIXIE3D_CMAKE_SOURCE_DIR}/src"
        COMMAND             ${CMAKE_COMMAND} -E copy_directory "${PIXIE3D_CMAKE_URL}/common" "${PIXIE3D_CMAKE_SOURCE_DIR}/common"
        COMMAND             ${CMAKE_COMMAND} -E copy "${PIXIE3D_CMAKE_URL}/contrib.tgz" "${PIXIE3D_CMAKE_SOURCE_DIR}/contrib.tgz"
        COMMAND             ${CMAKE_COMMAND} -E copy "${PIXIE3D_CMAKE_URL}/Makefile" "${PIXIE3D_CMAKE_SOURCE_DIR}/Makefile"
        COMMAND             ${CMAKE_COMMAND} -E garbage
        COMMENT             ""
        DEPENDEES           download
        DEPENDERS           configure
        WORKING_DIRECTORY   "${PIXIE3D_CMAKE_SOURCE_DIR}"
        LOG                 1
    )
    EXTERNALPROJECT_ADD_STEP(
        PIXIE3D
        make-libstell
        COMMENT             "Make LIBSTELL"
        COMMAND             make clean_debug FC=${CMAKE_Fortran_COMPILER} FFLAGS=-cpp
        COMMAND             make clean_release FC=${CMAKE_Fortran_COMPILER} FFLAGS=-cpp
        COMMAND             make debug FC=${CMAKE_Fortran_COMPILER} FFLAGS=-cpp
        COMMAND             make release FC=${CMAKE_Fortran_COMPILER} FFLAGS=-cpp
        COMMAND             make static_release FC=${CMAKE_Fortran_COMPILER} FFLAGS=cpp
        COMMENT             ""
        DEPENDEES           configure
        DEPENDERS           build
        WORKING_DIRECTORY   "${PIXIE3D_BUILD_DIR}/contrib/vmec/LIBSTELL"
        LOG                 1
    )
    IF ( IS_DIRECTORY "${PIXIE3D_CMAKE_URL}" )
        FILE(GLOB_RECURSE all_files RELATIVE "${PIXIE3D_CMAKE_URL}" 
            "${PIXIE3D_CMAKE_URL}/*.h" 
            "${PIXIE3D_CMAKE_URL}/*.c" "${PIXIE3D_CMAKE_URL}/*.C" 
            "${PIXIE3D_CMAKE_URL}/*.f" "${PIXIE3D_CMAKE_URL}/*.F" 
            "${PIXIE3D_CMAKE_URL}/*.f90" "${PIXIE3D_CMAKE_URL}/*.F90" )
        SET( COPY_COMMAND )
        FOREACH( tmp ${all_files} )
            SET( COPY_COMMAND ${COPY_COMMAND} COMMAND ${CMAKE_COMMAND} -E copy_if_different
                "${PIXIE3D_CMAKE_URL}/${tmp}" "${PIXIE3D_BUILD_DIR}/${tmp}" )
        ENDFOREACH()
        EXTERNALPROJECT_ADD_STEP(
            PIXIE3D
            update-source
            COMMENT             "Updating source"
            ${COPY_COMMAND}
            COMMENT             ""
            DEPENDEES           make-libstell
            DEPENDERS           build
            WORKING_DIRECTORY   "${PIXIE3D_BUILD_DIR}"
            ALWAYS              1
            LOG                 1
        )
    ENDIF()
    ADD_TPL_SAVE_LOGS( PIXIE3D )
    ADD_TPL_CLEAN( PIXIE3D )
ELSE()
    ADD_TPL_EMPTY( PIXIE3D )
ENDIF()



# This will configure and build trilinos
# User can configure the source path by speficfying TRILINOS_SRC_DIR,
#    the download path by specifying TRILINOS_URL, or the installed 
#    location by specifying TRILINOS_INSTALL_DIR


# Intialize download/src/install vars
SET( TRILINOS_BUILD_DIR "${CMAKE_BINARY_DIR}/TRILINOS-prefix/src/TRILINOS-build" )
IF ( TRILINOS_URL ) 
    MESSAGE_TPL("   TRILINOS_URL = ${TRILINOS_URL}")
    SET( TRILINOS_SRC_DIR "${CMAKE_BINARY_DIR}/TRILINOS-prefix/src/TRILINOS-src" )
    SET( TRILINOS_CMAKE_URL            "${TRILINOS_URL}"     )
    SET( TRILINOS_CMAKE_DOWNLOAD_DIR   "${TRILINOS_SRC_DIR}" )
    SET( TRILINOS_CMAKE_SOURCE_DIR     "${TRILINOS_SRC_DIR}" )
    SET( TRILINOS_CMAKE_INSTALL_DIR "${CMAKE_INSTALL_PREFIX}/trilinos" )
    SET( CMAKE_BUILD_TRILINOS TRUE )
ELSEIF ( TRILINOS_SRC_DIR )
    VERIFY_PATH("${TRILINOS_SRC_DIR}")
    MESSAGE_TPL("   TRILINOS_SRC_DIR = ${TRILINOS_SRC_DIR}")
    SET( TRILINOS_CMAKE_URL            ""                  )
    SET( TRILINOS_CMAKE_DOWNLOAD_DIR   ""                  )
    SET( TRILINOS_CMAKE_SOURCE_DIR     "${TRILINOS_SRC_DIR}" )
    SET( TRILINOS_CMAKE_INSTALL_DIR "${CMAKE_INSTALL_PREFIX}/trilinos" )
    SET( CMAKE_BUILD_TRILINOS TRUE )
ELSEIF ( TRILINOS_INSTALL_DIR ) 
    SET( TRILINOS_CMAKE_INSTALL_DIR "${TRILINOS_INSTALL_DIR}" )
    SET( CMAKE_BUILD_TRILINOS FALSE )
ELSE()
    MESSAGE(FATAL_ERROR "Please specify TRILINOS_SRC_DIR, TRILINOS_URL, or TRILINOS_INSTALL_DIR")
ENDIF()
SET( TRILINOS_INSTALL_DIR "${TRILINOS_CMAKE_INSTALL_DIR}" )
MESSAGE_TPL( "   TRILINOS_INSTALL_DIR = ${TRILINOS_INSTALL_DIR}" )
FILE( APPEND "${CMAKE_INSTALL_PREFIX}/TPLs.cmake" "SET(TRILINOS_INSTALL_DIR \"${TRILINOS_INSTALL_DIR}\")\n" )


# Configure trilinos
IF ( CMAKE_BUILD_TRILINOS )
    SET( CONFIGURE_OPTIONS "${CMAKE_ARGS};-DCMAKE_INSTALL_PREFIX=${CMAKE_INSTALL_PREFIX}/trilinos" )
    SET( CONFIGURE_OPTIONS "${CONFIGURE_OPTIONS};-DTPL_ENABLE_MPI:BOOL=ON" )
    SET( CONFIGURE_OPTIONS "${CONFIGURE_OPTIONS};-DTrilinos_ENABLE_ALL_PACKAGES:BOOL=ON" )
    SET( CONFIGURE_OPTIONS "${CONFIGURE_OPTIONS};-DTPL_BLAS_LIBRARIES:STRING=${CMAKE_INSTALL_PREFIX}/lapack/lib/libblas.a" )
    SET( CONFIGURE_OPTIONS "${CONFIGURE_OPTIONS};-DTPL_LAPACK_LIBRARIES:STRING=${CMAKE_INSTALL_PREFIX}/lapack/lib/liblapack.a" )
ENDIF()


# Configure trilinos
IF ( CMAKE_BUILD_TRILINOS )
    EXTERNALPROJECT_ADD(
        TRILINOS
        URL                 "${TRILINOS_CMAKE_URL}"
        DOWNLOAD_DIR        "${TRILINOS_CMAKE_DOWNLOAD_DIR}"
        SOURCE_DIR          "${TRILINOS_CMAKE_SOURCE_DIR}"
        UPDATE_COMMAND      ""
        BUILD_IN_SOURCE     0
        INSTALL_DIR         ${CMAKE_INSTALL_PREFIX}/trilinos
        CMAKE_ARGS          "${CONFIGURE_OPTIONS}"
        BUILD_COMMAND       make install -j ${PROCS_INSTALL}  VERBOSE=1
        DEPENDS             LAPACK
        LOG_DOWNLOAD 1   LOG_UPDATE 1   LOG_CONFIGURE 1   LOG_BUILD 1   LOG_TEST 1   LOG_INSTALL 1
    )
    ADD_TPL_SAVE_LOGS( TRILINOS )
    ADD_TPL_CLEAN( TRILINOS )
ELSE()
    ADD_TPL_EMPTY( TRILINOS )
ENDIF()



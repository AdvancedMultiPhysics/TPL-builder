# This will configure and build petaca
# User can configure the source path by specifying PETACA_SRC_DIR,
#    the download path by specifying PETACA_URL, or the installed 
#    location by specifying PETACA_INSTALL_DIR


# Intialize download/src/install vars
SET( PETACA_BUILD_DIR "${CMAKE_BINARY_DIR}/PETACA-prefix/src/PETACA-build" )
IF ( PETACA_URL ) 
    MESSAGE("   PETACA_URL = ${PETACA_URL}")
    SET( PETACA_SRC_DIR "${CMAKE_BINARY_DIR}/PETACA-prefix/src/PETACA-src" )
    SET( PETACA_CMAKE_URL            "${PETACA_URL}"     )
    SET( PETACA_CMAKE_DOWNLOAD_DIR   "${PETACA_SRC_DIR}" )
    SET( PETACA_CMAKE_SOURCE_DIR     "${PETACA_SRC_DIR}" )
    SET( PETACA_CMAKE_INSTALL_DIR "${CMAKE_INSTALL_PREFIX}/petaca" )
    SET( CMAKE_BUILD_PETACA TRUE )
ELSEIF ( PETACA_SRC_DIR )
    VERIFY_PATH("${PETACA_SRC_DIR}")
    MESSAGE("   PETACA_SRC_DIR = ${PETACA_SRC_DIR}")
    SET( PETACA_CMAKE_URL            ""                  )
    SET( PETACA_CMAKE_DOWNLOAD_DIR   ""                  )
    SET( PETACA_CMAKE_SOURCE_DIR     "${PETACA_SRC_DIR}" )
    SET( PETACA_CMAKE_INSTALL_DIR "${CMAKE_INSTALL_PREFIX}/petaca" )
    SET( CMAKE_BUILD_PETACA TRUE )
ELSEIF ( PETACA_INSTALL_DIR ) 
    SET( PETACA_CMAKE_INSTALL_DIR "${PETACA_INSTALL_DIR}" )
    SET( CMAKE_BUILD_PETACA FALSE )
ELSE()
    MESSAGE(FATAL_ERROR "Please specify PETACA_SRC_DIR, PETACA_URL, or PETACA_INSTALL_DIR")
ENDIF()
SET( PETACA_INSTALL_DIR "${PETACA_CMAKE_INSTALL_DIR}" )
MESSAGE( "   PETACA_INSTALL_DIR = ${PETACA_INSTALL_DIR}" )


# Configure petaca
IF ( CMAKE_BUILD_PETACA )
    SET( PETACA_CONFIGURE_OPTIONS "${CMAKE_ARGS};-DCMAKE_INSTALL_PREFIX=${CMAKE_INSTALL_PREFIX}/petaca" )
    SET( PETACA_CONFIGURE_OPTIONS "${PETACA_CONFIGURE_OPTIONS};-DYAJL_LIBRARY_DIR=${CMAKE_INSTALL_PREFIX}/yajl/lib" )
    SET( PETACA_CONFIGURE_OPTIONS "${PETACA_CONFIGURE_OPTIONS};-DYAJL_INCLUDE_DIR=${CMAKE_INSTALL_PREFIX}/yajl/include" )
    SET( PETACA_CONFIGURE_OPTIONS "${PETACA_CONFIGURE_OPTIONS};-DCMAKE_Fortran_COMPILER_VERSION=18.0.0" )
ENDIF()


# Build petaca
ADD_TPL(
    PETACA
    URL                 "${PETACA_CMAKE_URL}"
    DOWNLOAD_DIR        "${PETACA_CMAKE_DOWNLOAD_DIR}"
    SOURCE_DIR          "${PETACA_CMAKE_SOURCE_DIR}"
    UPDATE_COMMAND      ""
    BUILD_IN_SOURCE     0
    INSTALL_DIR         ${CMAKE_INSTALL_PREFIX}/petaca
    CMAKE_ARGS          "${PETACA_CONFIGURE_OPTIONS}"
    BUILD_COMMAND       $(MAKE) install VERBOSE=1
    DEPENDS             YAJL
    LOG_DOWNLOAD 1   LOG_UPDATE 1   LOG_CONFIGURE 1   LOG_BUILD 1   LOG_TEST 1   LOG_INSTALL 1
)


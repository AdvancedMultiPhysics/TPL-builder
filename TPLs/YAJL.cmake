# This will configure and build yajl
# User can configure the source path by specifying YAJL_SRC_DIR,
#    the download path by specifying YAJL_URL, or the installed 
#    location by specifying YAJL_INSTALL_DIR


# Intialize download/src/install vars
SET( YAJL_BUILD_DIR "${CMAKE_BINARY_DIR}/YAJL-prefix/src/YAJL-build" )
IF ( YAJL_URL ) 
    MESSAGE("   YAJL_URL = ${YAJL_URL}")
    SET( YAJL_SRC_DIR "${CMAKE_BINARY_DIR}/YAJL-prefix/src/YAJL-src" )
    SET( YAJL_CMAKE_URL            "${YAJL_URL}"     )
    SET( YAJL_CMAKE_DOWNLOAD_DIR   "${YAJL_SRC_DIR}" )
    SET( YAJL_CMAKE_SOURCE_DIR     "${YAJL_SRC_DIR}" )
    SET( YAJL_CMAKE_INSTALL_DIR "${CMAKE_INSTALL_PREFIX}/yajl" )
    SET( CMAKE_BUILD_YAJL TRUE )
ELSEIF ( YAJL_SRC_DIR )
    VERIFY_PATH("${YAJL_SRC_DIR}")
    MESSAGE("   YAJL_SRC_DIR = ${YAJL_SRC_DIR}")
    SET( YAJL_CMAKE_URL            ""                  )
    SET( YAJL_CMAKE_DOWNLOAD_DIR   ""                  )
    SET( YAJL_CMAKE_SOURCE_DIR     "${YAJL_SRC_DIR}" )
    SET( YAJL_CMAKE_INSTALL_DIR "${CMAKE_INSTALL_PREFIX}/yajl" )
    SET( CMAKE_BUILD_YAJL TRUE )
ELSEIF ( YAJL_INSTALL_DIR ) 
    SET( YAJL_CMAKE_INSTALL_DIR "${YAJL_INSTALL_DIR}" )
    SET( CMAKE_BUILD_YAJL FALSE )
ELSE()
    MESSAGE(FATAL_ERROR "Please specify YAJL_SRC_DIR, YAJL_URL, or YAJL_INSTALL_DIR")
ENDIF()
SET( YAJL_INSTALL_DIR "${YAJL_CMAKE_INSTALL_DIR}" )
MESSAGE( "   YAJL_INSTALL_DIR = ${YAJL_INSTALL_DIR}" )


# Configure yajl
IF ( CMAKE_BUILD_YAJL )
    SET( CONFIGURE_OPTIONS "${CMAKE_ARGS};-DCMAKE_INSTALL_PREFIX=${CMAKE_INSTALL_PREFIX}/yajl" )
ENDIF()


# Build yajl
IF ( CMAKE_BUILD_YAJL )
    EXTERNALPROJECT_ADD(
        YAJL
        URL                 "${YAJL_CMAKE_URL}"
        DOWNLOAD_DIR        "${YAJL_CMAKE_DOWNLOAD_DIR}"
        SOURCE_DIR          "${YAJL_CMAKE_SOURCE_DIR}"
        UPDATE_COMMAND      ""
        BUILD_IN_SOURCE     0
        INSTALL_DIR         ${CMAKE_INSTALL_PREFIX}/yajl
        CMAKE_ARGS          "${CONFIGURE_OPTIONS}"
        BUILD_COMMAND       make install -j ${PROCS_INSTALL} VERBOSE=1
        DEPENDS             
        LOG_DOWNLOAD 1   LOG_UPDATE 1   LOG_CONFIGURE 1   LOG_BUILD 1   LOG_TEST 1   LOG_INSTALL 1
    )
    ADD_TPL_SAVE_LOGS( YAJL )
    ADD_TPL_CLEAN( YAJL )
ELSE()
    ADD_TPL_EMPTY( YAJL )
ENDIF()



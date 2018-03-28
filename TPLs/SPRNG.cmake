# This will configure and build sprng
# User can configure the source path by specifying SPRNG_SRC_DIR,
#    the download path by specifying SPRNG_URL, or the installed 
#    location by specifying SPRNG_INSTALL_DIR


# Intialize download/src/install vars
SET( SPRNG_BUILD_DIR "${CMAKE_BINARY_DIR}/SPRNG-prefix/src/SPRNG-build" )
IF ( SPRNG_URL ) 
    MESSAGE("   SPRNG_URL = ${SPRNG_URL}")
    SET( SPRNG_SRC_DIR "${CMAKE_BINARY_DIR}/SPRNG-prefix/src/SPRNG-src" )
    SET( SPRNG_CMAKE_URL            "${SPRNG_URL}"        )
    SET( SPRNG_CMAKE_DOWNLOAD_DIR   "${SPRNG_SRC_DIR}"    )
    SET( SPRNG_CMAKE_SOURCE_DIR     "${SPRNG_SRC_DIR}"    )
    SET( SPRNG_CMAKE_INSTALL_DIR "${CMAKE_INSTALL_PREFIX}/sprng" )
    SET( CMAKE_BUILD_SPRNG TRUE )
ELSEIF ( SPRNG_SRC_DIR )
    VERIFY_PATH("${SPRNG_SRC_DIR}")
    MESSAGE("   SPRNG_SRC_DIR = ${SPRNG_SRC_DIR}")
    SET( SPRNG_CMAKE_URL            ""                   )
    SET( SPRNG_CMAKE_DOWNLOAD_DIR   ""                   )
    SET( SPRNG_CMAKE_SOURCE_DIR     "${SPRNG_SRC_DIR}"   )
    SET( SPRNG_CMAKE_INSTALL_DIR "${CMAKE_INSTALL_PREFIX}/sprng" )
    SET( CMAKE_BUILD_SPRNG TRUE )
ELSEIF ( SPRNG_INSTALL_DIR ) 
    SET( SPRNG_CMAKE_INSTALL_DIR "${SPRNG_INSTALL_DIR}" )
    SET( CMAKE_BUILD_SPRNG FALSE )
ELSE()
    MESSAGE(FATAL_ERROR "Please specify SPRNG_SRC_DIR, SPRNG_URL, or SPRNG_INSTALL_DIR")
ENDIF()
SET( SPRNG_INSTALL_DIR "${SPRNG_CMAKE_INSTALL_DIR}" )
MESSAGE( "   SPRNG_INSTALL_DIR = ${SPRNG_INSTALL_DIR}" )


# Build sprng
IF ( CMAKE_BUILD_SPRNG )
    EXTERNALPROJECT_ADD(
        SPRNG
        URL                 "${SPRNG_CMAKE_URL}"
        DOWNLOAD_DIR        "${SPRNG_CMAKE_DOWNLOAD_DIR}"
        SOURCE_DIR          "${SPRNG_CMAKE_SOURCE_DIR}"
        UPDATE_COMMAND      ""
        CONFIGURE_COMMAND   ""
        BUILD_COMMAND       ${CMAKE_COMMAND} -E copy_directory ${SPRNG_SRC_DIR} ${CMAKE_INSTALL_PREFIX}/sprng
        BUILD_IN_SOURCE     0
        INSTALL_COMMAND     ""
        LOG_DOWNLOAD 1   LOG_UPDATE 1   LOG_CONFIGURE 1   LOG_BUILD 1   LOG_TEST 1   LOG_INSTALL 1
    )
    ADD_TPL_SAVE_LOGS( SPRNG )
    ADD_TPL_CLEAN( SPRNG )
ELSE()
    ADD_TPL_EMPTY( SPRNG )
ENDIF()



# This will configure and build moab
# User can configure the source path by specifying MOAB_SRC_DIR,
#    the download path by specifying MOAB_URL, or the installed 
#    location by specifying MOAB_INSTALL_DIR


# Intialize download/src/install vars
SET( MOAB_BUILD_DIR "${CMAKE_BINARY_DIR}/MOAB-prefix/src/MOAB-build" )
IF ( MOAB_URL ) 
    MESSAGE("   MOAB_URL = ${MOAB_URL}")
    SET( MOAB_SRC_DIR "${CMAKE_BINARY_DIR}/MOAB-prefix/src/MOAB-src" )
    SET( MOAB_CMAKE_URL            "${MOAB_URL}"     )
    SET( MOAB_CMAKE_DOWNLOAD_DIR   "${MOAB_SRC_DIR}" )
    SET( MOAB_CMAKE_SOURCE_DIR     "${MOAB_SRC_DIR}" )
    SET( MOAB_CMAKE_INSTALL_DIR "${CMAKE_INSTALL_PREFIX}/moab" )
    SET( CMAKE_BUILD_MOAB TRUE )
ELSEIF ( MOAB_SRC_DIR )
    VERIFY_PATH("${MOAB_SRC_DIR}")
    MESSAGE("   MOAB_SRC_DIR = ${MOAB_SRC_DIR}")
    SET( MOAB_CMAKE_URL            ""                )
    SET( MOAB_CMAKE_DOWNLOAD_DIR   ""                )
    SET( MOAB_CMAKE_SOURCE_DIR     "${MOAB_SRC_DIR}" )
    SET( MOAB_CMAKE_INSTALL_DIR "${CMAKE_INSTALL_PREFIX}/moab" )
    SET( CMAKE_BUILD_MOAB TRUE )
ELSEIF ( MOAB_INSTALL_DIR ) 
    SET( MOAB_CMAKE_INSTALL_DIR "${MOAB_INSTALL_DIR}" )
    SET( CMAKE_BUILD_MOAB FALSE )
ELSE()
    MESSAGE(FATAL_ERROR "Please specify MOAB_SRC_DIR, MOAB_URL, or MOAB_INSTALL_DIR")
ENDIF()
SET( MOAB_INSTALL_DIR "${MOAB_CMAKE_INSTALL_DIR}" )
MESSAGE( "   MOAB_INSTALL_DIR = ${MOAB_INSTALL_DIR}" )


# Configure moab
IF ( CMAKE_BUILD_MOAB )
    SET( CONFIGURE_OPTIONS QTDIR=${CMAKE_INSTALL_PREFIX}/qt )
    IF ( ${CMAKE_BUILD_TYPE} STREQUAL "Debug" )
        SET( CONFIGURE_OPTIONS ${CONFIGURE_OPTIONS} --enable-debug )
    ELSEIF ( ${CMAKE_BUILD_TYPE} STREQUAL "Release" )
        SET( CONFIGURE_OPTIONS ${CONFIGURE_OPTIONS} --enable-optimize )
    ELSE()
        MESSAGE ( FATAL_ERROR "Unknown CMAKE_BUILD_TYPE=${CMAKE_BUILD_TYPE}" )
    ENDIF()
    IF ( ENABLE_SHARED )
        SET( CONFIGURE_OPTIONS ${CONFIGURE_OPTIONS} --enable-shared )
    ELSE()
        SET( CONFIGURE_OPTIONS ${CONFIGURE_OPTIONS} --disable-shared )
    ENDIF()
    IF ( ENABLE_STATIC )
        SET( CONFIGURE_OPTIONS ${CONFIGURE_OPTIONS} --enable-static )
    ELSE()
        SET( CONFIGURE_OPTIONS ${CONFIGURE_OPTIONS} --disable-static )
    ENDIF()
ENDIF()


# Build moab
ADD_TPL(
    MOAB
    URL                 "${MOAB_CMAKE_URL}"
    DOWNLOAD_DIR        "${MOAB_CMAKE_DOWNLOAD_DIR}"
    SOURCE_DIR          "${MOAB_CMAKE_SOURCE_DIR}"

    UPDATE_COMMAND      ""
    CONFIGURE_COMMAND   ${MOAB_SRC_DIR}/configure --prefix=${CMAKE_INSTALL_PREFIX}/moab ${CONFIGURE_OPTIONS} ${ENV_VARS}
    BUILD_COMMAND       make install -j ${PROCS_INSTALL} VERBOSE=1
    BUILD_IN_SOURCE     0
    INSTALL_COMMAND     ""
    DEPENDS             QT
    LOG_DOWNLOAD 1   LOG_UPDATE 1   LOG_CONFIGURE 1   LOG_BUILD 1   LOG_TEST 1   LOG_INSTALL 1
)



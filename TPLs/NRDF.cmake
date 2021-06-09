# This will configure and build NRDF
# User can configure the source path by specifying NRDF_SRC_DIR,
#    the download path by specifying NRDF_URL, or the installed 
#    location by specifying NRDF_INSTALL_DIR


# Intialize download/src/install vars
SET( NRDF_BUILD_DIR "${CMAKE_BINARY_DIR}/NRDF-prefix/src/NRDF-build" )
IF ( NRDF_URL ) 
    MESSAGE("   NRDF_URL = ${NRDF_URL}")
    SET( NRDF_SRC_DIR "${CMAKE_BINARY_DIR}/NRDF-prefix/src/NRDF-src" )
    SET( NRDF_CMAKE_URL            "${NRDF_URL}"     )
    SET( NRDF_CMAKE_DOWNLOAD_DIR   "${NRDF_SRC_DIR}" )
    SET( NRDF_CMAKE_DOWNLOAD_CMD   URL                 )
    SET( NRDF_CMAKE_SOURCE_DIR     "${NRDF_SRC_DIR}" )
    SET( NRDF_CMAKE_INSTALL_DIR "${CMAKE_INSTALL_PREFIX}/nrdf" )
    SET( CMAKE_BUILD_NRDF TRUE )
ELSEIF ( NRDF_SRC_DIR )
    VERIFY_PATH("${NRDF_SRC_DIR}")
    MESSAGE("   NRDF_SRC_DIR = ${NRDF_SRC_DIR}")
    SET( NRDF_CMAKE_URL            ""                  )
    SET( NRDF_CMAKE_DOWNLOAD_DIR   ""                  )
    SET( NRDF_CMAKE_DOWNLOAD_CMD   URL                 )
    SET( NRDF_CMAKE_SOURCE_DIR     "${NRDF_SRC_DIR}" )
    SET( NRDF_CMAKE_INSTALL_DIR "${CMAKE_INSTALL_PREFIX}/nrdf" )
    SET( CMAKE_BUILD_NRDF TRUE )
ELSEIF ( NRDF_INSTALL_DIR ) 
    SET( NRDF_CMAKE_INSTALL_DIR "${NRDF_INSTALL_DIR}" )
    SET( CMAKE_BUILD_NRDF FALSE )
ELSE()
    MESSAGE(FATAL_ERROR "Please specify NRDF_SRC_DIR, NRDF_URL, or NRDF_INSTALL_DIR")
ENDIF()
FILE( MAKE_DIRECTORY "${NRDF_CMAKE_INSTALL_DIR}" )
SET( NRDF_INSTALL_DIR "${NRDF_CMAKE_INSTALL_DIR}" )
MESSAGE( "   NRDF_INSTALL_DIR = ${NRDF_INSTALL_DIR}" )


# Configure NRDF
IF ( CMAKE_BUILD_NRDF )
    SET( NRDF_FFLAGS "-x f95-cpp-input -ffixed-line-length-none" )
    SET( CONFIGURE_OPTIONS "${CMAKE_ARGS}" )
    SET( CONFIGURE_OPTIONS "${CONFIGURE_OPTIONS};-DSAMRSOLVERS_DIRECTORY=${SAMRSOLVERS_INSTALL_DIR}" )
    SET( CONFIGURE_OPTIONS "${CONFIGURE_OPTIONS};-DNRDF_INSTALL_DIR=${NRDF_INSTALL_DIR}" )
    SET( CONFIGURE_OPTIONS "${CONFIGURE_OPTIONS};-DFFLAGS=${NRDF_FFLAGS}" )
ENDIF()


# Build NRDF
ADD_TPL(
    NRDF
    URL                 "${NRDF_CMAKE_URL}"
    DOWNLOAD_DIR        "${NRDF_CMAKE_DOWNLOAD_DIR}"
    SOURCE_DIR          "${NRDF_CMAKE_SOURCE_DIR}"
    UPDATE_COMMAND      ""
    CMAKE_ARGS          "${CONFIGURE_OPTIONS}"
    BUILD_COMMAND       make -j ${PROCS_INSTALL} VERBOSE=1
    BUILD_IN_SOURCE     0
    INSTALL_COMMAND     make install
    DEPENDS             SAMRSOLVERS
    LOG_DOWNLOAD 1   LOG_UPDATE 1   LOG_CONFIGURE 1   LOG_BUILD 1   LOG_TEST 1   LOG_INSTALL 1
)



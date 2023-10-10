# This will configure and build SAMRSolvers
# User can configure the source path by specifying SAMRSOLVERS_SRC_DIR,
#    the download path by specifying SAMRSOLVERS_URL, or the installed 
#    location by specifying SAMRSOLVERS_INSTALL_DIR


# Intialize download/src/install vars
SET( SAMRSOLVERS_BUILD_DIR "${CMAKE_BINARY_DIR}/SAMRSOLVERS-prefix/src/SAMRSOLVERS-build" )
IF ( SAMRSOLVERS_URL ) 
    MESSAGE("   SAMRSOLVERS_URL = ${SAMRSOLVERS_URL}")
    SET( SAMRSOLVERS_SRC_DIR "${CMAKE_BINARY_DIR}/SAMRSOLVERS-prefix/src/SAMRSOLVERS-src" )
    SET( SAMRSOLVERS_CMAKE_URL            "${SAMRSOLVERS_URL}"     )
    SET( SAMRSOLVERS_CMAKE_DOWNLOAD_DIR   "${SAMRSOLVERS_SRC_DIR}" )
    SET( SAMRSOLVERS_CMAKE_DOWNLOAD_CMD   URL                 )
    SET( SAMRSOLVERS_CMAKE_SOURCE_DIR     "${SAMRSOLVERS_SRC_DIR}" )
    SET( SAMRSOLVERS_CMAKE_INSTALL_DIR "${CMAKE_INSTALL_PREFIX}/samrsolvers" )
    SET( CMAKE_BUILD_SAMRSOLVERS TRUE )
ELSEIF ( SAMRSOLVERS_SRC_DIR )
    VERIFY_PATH("${SAMRSOLVERS_SRC_DIR}")
    MESSAGE("   SAMRSOLVERS_SRC_DIR = ${SAMRSOLVERS_SRC_DIR}")
    SET( SAMRSOLVERS_CMAKE_URL            ""                  )
    SET( SAMRSOLVERS_CMAKE_DOWNLOAD_DIR   ""                  )
    SET( SAMRSOLVERS_CMAKE_DOWNLOAD_CMD   URL                 )
    SET( SAMRSOLVERS_CMAKE_SOURCE_DIR     "${SAMRSOLVERS_SRC_DIR}" )
    SET( SAMRSOLVERS_CMAKE_INSTALL_DIR "${CMAKE_INSTALL_PREFIX}/samrsolvers" )
    SET( CMAKE_BUILD_SAMRSOLVERS TRUE )
ELSEIF ( SAMRSOLVERS_INSTALL_DIR ) 
    SET( SAMRSOLVERS_CMAKE_INSTALL_DIR "${SAMRSOLVERS_INSTALL_DIR}" )
    SET( CMAKE_BUILD_SAMRSOLVERS FALSE )
ELSE()
    MESSAGE(FATAL_ERROR "Please specify SAMRSOLVERS_SRC_DIR, SAMRSOLVERS_URL, or SAMRSOLVERS_INSTALL_DIR")
ENDIF()
FILE( MAKE_DIRECTORY "${SAMRSOLVERS_CMAKE_INSTALL_DIR}" )
SET( SAMRSOLVERS_INSTALL_DIR "${SAMRSOLVERS_CMAKE_INSTALL_DIR}" )
MESSAGE( "   SAMRSOLVERS_INSTALL_DIR = ${SAMRSOLVERS_INSTALL_DIR}" )


# Configure SAMRSolvers
IF ( CMAKE_BUILD_SAMRSOLVERS )
    SET( SAMRSOLVERS_CONFIGURE_OPTIONS "${CMAKE_ARGS}" )
    SET( SAMRSOLVERS_CONFIGURE_OPTIONS "${SAMRSOLVERS_CONFIGURE_OPTIONS};-DSAMRUTILS_DIRECTORY=${SAMRUTILS_INSTALL_DIR}" )
    SET( SAMRSOLVERS_CONFIGURE_OPTIONS "${SAMRSOLVERS_CONFIGURE_OPTIONS};-DSAMRSOLVERS_INSTALL_DIR=${SAMRSOLVERS_INSTALL_DIR}" )
    IF ( SAMRSOLVERS_DISABLE_THRUST )
        SET( SAMRSOLVERS_CONFIGURE_OPTIONS "${SAMRSOLVERS_CONFIGURE_OPTIONS};-DDISABLE_THRUST=${SAMRSOLVERS_DISABLE_THRUST}" )
    ENDIF()
    IF ( SAMRSOLVERS_DISABLE_KOKKOS )
      SET( SAMRSOLVERS_CONFIGURE_OPTIONS "${SAMRSOLVERS_CONFIGURE_OPTIONS};-DDISABLE_KOKKOS=${SAMRSOLVERS_DISABLE_KOKKOS}" )
      # enable or disable cabana with the same options
      SET( SAMRSOLVERS_CONFIGURE_OPTIONS "${SAMRSOLVERS_CONFIGURE_OPTIONS};-DDISABLE_CABANA=${SAMRSOLVERS_DISABLE_KOKKOS}" )
    ENDIF()
    MESSAGE( "SAMRSOLVERS configure options: " "${SAMRSOLVERS_CONFIGURE_OPTIONS}" )  
ENDIF()


# Build SAMRSolvers
ADD_TPL(
    SAMRSOLVERS
    URL                 "${SAMRSOLVERS_CMAKE_URL}"
    DOWNLOAD_DIR        "${SAMRSOLVERS_CMAKE_DOWNLOAD_DIR}"
    SOURCE_DIR          "${SAMRSOLVERS_CMAKE_SOURCE_DIR}"
    UPDATE_COMMAND      ""
    CMAKE_ARGS          "${SAMRSOLVERS_CONFIGURE_OPTIONS}"
    BUILD_COMMAND       $(MAKE) VERBOSE=1
    BUILD_IN_SOURCE     0
    INSTALL_COMMAND     make install
    DEPENDS             SAMRUTILS
    LOG_DOWNLOAD 1   LOG_UPDATE 1   LOG_CONFIGURE 1   LOG_BUILD 1   LOG_TEST 1   LOG_INSTALL 1
)


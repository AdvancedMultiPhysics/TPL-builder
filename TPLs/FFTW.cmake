# This will configure and build fftw
# User can configure the source path by specifying FFTW_SRC_DIR,
#    the download path by specifying FFTW_URL, or the installed 
#    location by specifying FFTW_INSTALL_DIR


# Intialize download/src/install vars
SET( FFTW_BUILD_DIR "${CMAKE_BINARY_DIR}/FFTW-prefix/src/FFTW-build" )
IF ( FFTW_URL ) 
    MESSAGE("   FFTW_URL = ${FFTW_URL}")
    SET( FFTW_CMAKE_URL            "${FFTW_URL}"       )
    SET( FFTW_CMAKE_DOWNLOAD_DIR   "${FFTW_BUILD_DIR}" )
    SET( FFTW_CMAKE_SOURCE_DIR     "${FFTW_BUILD_DIR}" )
    SET( FFTW_CMAKE_INSTALL_DIR "${CMAKE_INSTALL_PREFIX}/fftw" )
    SET( CMAKE_BUILD_FFTW TRUE )
ELSEIF ( FFTW_SRC_DIR )
    VERIFY_PATH("${FFTW_SRC_DIR}")
    MESSAGE("   FFTW_SRC_DIR = ${FFTW_SRC_DIR}" )
    SET( FFTW_CMAKE_URL            ""                  )
    SET( FFTW_CMAKE_DOWNLOAD_DIR   ""                  )
    SET( FFTW_CMAKE_SOURCE_DIR     "${FFTW_SRC_DIR}" )
    SET( FFTW_CMAKE_INSTALL_DIR "${CMAKE_INSTALL_PREFIX}/fftw" )
    SET( CMAKE_BUILD_FFTW TRUE )
ELSEIF ( FFTW_INSTALL_DIR ) 
    SET( FFTW_CMAKE_INSTALL_DIR "${FFTW_INSTALL_DIR}" )
    SET( CMAKE_BUILD_FFTW FALSE )
ELSE()
    MESSAGE(FATAL_ERROR "Please specify FFTW_SRC_DIR, FFTW_URL, or FFTW_INSTALL_DIR")
ENDIF()
IF ( ${CMAKE_BUILD_TYPE} STREQUAL "Debug" )
    SET( FFTW_METHOD dbg )
ELSEIF ( ${CMAKE_BUILD_TYPE} STREQUAL "Release" )
    SET( FFTW_METHOD opt )
ELSE()
    MESSAGE ( FATAL_ERROR "Unknown CMAKE_BUILD_TYPE=${CMAKE_BUILD_TYPE}" )
ENDIF()
SET( FFTW_HOSTTYPE x86_64-unknown-linux-gnu )
SET( FFTW_INSTALL_DIR "${FFTW_CMAKE_INSTALL_DIR}" )
MESSAGE( "   FFTW_INSTALL_DIR = ${FFTW_INSTALL_DIR}" )


# Configure fftw
IF ( CMAKE_BUILD_FFTW )
    SET( CONFIGURE_OPTIONS )
    SET( CONFIGURE_OPTIONS ${CONFIGURE_OPTIONS} --prefix=${CMAKE_INSTALL_PREFIX}/fftw )
ENDIF()


# Build fftw
IF ( CMAKE_BUILD_FFTW )
    EXTERNALPROJECT_ADD( 
        FFTW
        URL                 "${FFTW_CMAKE_URL}"
        DOWNLOAD_DIR        "${FFTW_CMAKE_DOWNLOAD_DIR}"
        SOURCE_DIR          "${FFTW_CMAKE_SOURCE_DIR}"
        UPDATE_COMMAND      ""
        CONFIGURE_COMMAND   ${FFTW_CMAKE_SOURCE_DIR}/configure ${CONFIGURE_OPTIONS} CXXFLAGS=${FFTW_CXX_FLAGS} LDFLAGS=${FFTW_LD_FLAGS}
        BUILD_COMMAND       make -j ${PROCS_INSTALL} VERBOSE=1
        BUILD_IN_SOURCE     0
        INSTALL_COMMAND     make install
        DEPENDS             
        LOG_DOWNLOAD 1   LOG_UPDATE 1   LOG_CONFIGURE 1   LOG_BUILD 1   LOG_TEST 1   LOG_INSTALL 1
    )
    ADD_TPL_SAVE_LOGS( FFTW )
    ADD_TPL_CLEAN( FFTW )
ELSE()
    ADD_TPL_EMPTY( FFTW )
ENDIF()


# Add the appropriate fields to FindTPLs.cmake


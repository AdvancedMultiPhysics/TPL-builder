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
ELSEIF ( ${CMAKE_BUILD_TYPE} STREQUAL "Release" OR  ${CMAKE_BUILD_TYPE} STREQUAL "RelWithDebInfo")
    SET( FFTW_METHOD opt )
ELSE()
    MESSAGE ( FATAL_ERROR "Unknown CMAKE_BUILD_TYPE=${CMAKE_BUILD_TYPE}" )
ENDIF()
SET( FFTW_HOSTTYPE x86_64-unknown-linux-gnu )
SET( FFTW_INSTALL_DIR "${FFTW_CMAKE_INSTALL_DIR}" )
MESSAGE( "   FFTW_INSTALL_DIR = ${FFTW_INSTALL_DIR}" )

IF ( NOT DEFINED FFTW_USE_MPI )
    SET( FFTW_USE_MPI ${USE_MPI} )
ENDIF()


# Configure fftw
IF ( CMAKE_BUILD_FFTW )
    SET( FFTW_CONFIGURE_OPTIONS )
    SET( FFTW_CONFIGURE_OPTIONS ${FFTW_CONFIGURE_OPTIONS} --prefix=${CMAKE_INSTALL_PREFIX}/fftw )

    IF ( ENABLE_SHARED AND ENABLE_STATIC )
        SET( FFTW_CONFIGURE_OPTIONS ${FFTW_CONFIGURE_OPTIONS} --enable-shared=yes --enable-static=yes )
    ELSEIF ( ENABLE_SHARED )
        SET( FFTW_CONFIGURE_OPTIONS ${FFTW_CONFIGURE_OPTIONS} --enable-shared=yes --enable-static=no )
    ELSEIF ( ENABLE_STATIC )
        SET( FFTW_CONFIGURE_OPTIONS ${FFTW_CONFIGURE_OPTIONS} --enable-shared=no --enable-static=yes )
    ENDIF()
  
    IF ( FFTW_USE_MPI )
        SET( FFTW_CONFIGURE_OPTIONS ${FFTW_CONFIGURE_OPTIONS} --enable-mpi=yes )
    ELSE()
        SET( FFTW_CONFIGURE_OPTIONS ${FFTW_CONFIGURE_OPTIONS} --enable-mpi=no )
    ENDIF()
    IF ( ${CMAKE_BUILD_TYPE} STREQUAL "Debug" )
        SET( FFTW_CONFIGURE_OPTIONS ${FFTW_CONFIGURE_OPTIONS} --enable-debug=yes )
    ELSE()
        SET( FFTW_CONFIGURE_OPTIONS ${FFTW_CONFIGURE_OPTIONS} --enable-debug=no )
    ENDIF()


    # Build fftw
    ADD_TPL( 
        FFTW
        URL                 "${FFTW_CMAKE_URL}"
        DOWNLOAD_DIR        "${FFTW_CMAKE_DOWNLOAD_DIR}"
        SOURCE_DIR          "${FFTW_CMAKE_SOURCE_DIR}"
        UPDATE_COMMAND      ""
        CONFIGURE_COMMAND   ${FFTW_CMAKE_SOURCE_DIR}/configure ${FFTW_CONFIGURE_OPTIONS} CXXFLAGS=${FFTW_CXX_FLAGS} LDFLAGS=${FFTW_LD_FLAGS}
        BUILD_COMMAND       $(MAKE) VERBOSE=1
        BUILD_IN_SOURCE     0
        INSTALL_COMMAND     $(MAKE) install
        LOG_DOWNLOAD 1   LOG_UPDATE 1   LOG_CONFIGURE 1   LOG_BUILD 1   LOG_TEST 1   LOG_INSTALL 1
    )

ELSE()
    ADD_TPL_EMPTY( FFTW )
ENDIF()

# Add the appropriate fields to FindTPLs.cmake
FILE( APPEND "${FIND_TPLS_CMAKE}" "\n# Find FFTW\n" )
FILE( APPEND "${FIND_TPLS_CMAKE}" "IF ( TPLs_FIND_FFTW AND NOT TPLs_FFTW_FOUND )\n" )
FILE( APPEND "${FIND_TPLS_CMAKE}" "    SET( FFTW_DIR \"${FFTW_INSTALL_DIR}\" )\n" )
FILE( APPEND "${FIND_TPLS_CMAKE}" "    SET( FFTW_DIRECTORY \"${FFTW_INSTALL_DIR}\" )\n" )
FILE( APPEND "${FIND_TPLS_CMAKE}" "    SET( FFTW_INCLUDE ${FFTW_INSTALL_DIR}/include )\n" )
FILE( APPEND "${FIND_TPLS_CMAKE}" "    FIND_LIBRARY( FFTW_LIB  NAMES fftw3  PATHS $\{FFTW_DIRECTORY}/lib  NO_DEFAULT_PATH )\n" )
FILE( APPEND "${FIND_TPLS_CMAKE}" "    IF ( NOT FFTW_LIB )\n" )
FILE( APPEND "${FIND_TPLS_CMAKE}" "        MESSAGE(FATAL_ERROR \"fftw3 library not found in $\{FFTW_DIRECTORY}/lib\")\n" )
FILE( APPEND "${FIND_TPLS_CMAKE}" "    ENDIF()\n" )
FILE( APPEND "${FIND_TPLS_CMAKE}" "    ADD_TPL_LIBRARY( FFTW $\{FFTW_LIB} )\n" )
FILE( APPEND "${FIND_TPLS_CMAKE}" "ENDIF()\n" )
FILE( APPEND "${FIND_TPLS_CMAKE}" "\n" )


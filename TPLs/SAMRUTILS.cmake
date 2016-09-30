# This will configure and build SAMRUtils
# User can configure the source path by specifying SAMRUTILS_SRC_DIR,
#    the download path by specifying SAMRUTILS_URL, or the installed 
#    location by specifying SAMRUTILS_INSTALL_DIR


# Intialize download/src/install vars
SET( SAMRUTILS_BUILD_DIR "${CMAKE_BINARY_DIR}/SAMRUTILS-prefix/src/SAMRUTILS-build" )
IF ( SAMRUTILS_URL ) 
    MESSAGE_TPL("   SAMRUTILS_URL = ${SAMRUTILS_URL}")
    SET( SAMRUTILS_SRC_DIR "${CMAKE_BINARY_DIR}/SAMRUTILS-prefix/src/SAMRUTILS-src" )
    SET( SAMRUTILS_CMAKE_URL            "${SAMRUTILS_URL}"     )
    SET( SAMRUTILS_CMAKE_DOWNLOAD_DIR   "${SAMRUTILS_SRC_DIR}" )
    SET( SAMRUTILS_CMAKE_DOWNLOAD_CMD   URL                 )
    SET( SAMRUTILS_CMAKE_SOURCE_DIR     "${SAMRUTILS_SRC_DIR}" )
    SET( SAMRUTILS_CMAKE_INSTALL_DIR "${CMAKE_INSTALL_PREFIX}/samrutils" )
    SET( CMAKE_BUILD_SAMRUTILS TRUE )
ELSEIF ( SAMRUTILS_SRC_DIR )
    VERIFY_PATH("${SAMRUTILS_SRC_DIR}")
    MESSAGE_TPL("   SAMRUTILS_SRC_DIR = ${SAMRUTILS_SRC_DIR}")
    SET( SAMRUTILS_CMAKE_URL            ""                  )
    SET( SAMRUTILS_CMAKE_DOWNLOAD_DIR   ""                  )
    SET( SAMRUTILS_CMAKE_DOWNLOAD_CMD   URL                 )
    SET( SAMRUTILS_CMAKE_SOURCE_DIR     "${SAMRUTILS_SRC_DIR}" )
    SET( SAMRUTILS_CMAKE_INSTALL_DIR "${CMAKE_INSTALL_PREFIX}/samrutils" )
    SET( CMAKE_BUILD_SAMRUTILS TRUE )
ELSEIF ( SAMRUTILS_INSTALL_DIR ) 
    SET( SAMRUTILS_CMAKE_INSTALL_DIR "${SAMRUTILS_INSTALL_DIR}" )
    SET( CMAKE_BUILD_SAMRUTILS FALSE )
ELSE()
    MESSAGE(FATAL_ERROR "Please specify SAMRUTILS_SRC_DIR, SAMRUTILS_URL, or SAMRUTILS_INSTALL_DIR")
ENDIF()
FILE( MAKE_DIRECTORY "${SAMRUTILS_CMAKE_INSTALL_DIR}" )
SET( SAMRUTILS_INSTALL_DIR "${SAMRUTILS_CMAKE_INSTALL_DIR}" )
MESSAGE_TPL( "   SAMRUTILS_INSTALL_DIR = ${SAMRUTILS_INSTALL_DIR}" )
FILE( APPEND "${CMAKE_INSTALL_PREFIX}/TPLs.cmake" "SET(SAMRUTILS_INSTALL_DIR \"${SAMRUTILS_INSTALL_DIR}\")\n" )


# Configure SAMRUtils
IF ( CMAKE_BUILD_SAMRUTILS )
    SET( CONFIGURE_OPTIONS "${CMAKE_ARGS}" )
    SET( CONFIGURE_OPTIONS "${CONFIGURE_OPTIONS};-DCMAKE_BUILD_TYPE=${CMAKE_BUILD_TYPE}" )
    SET( CONFIGURE_OPTIONS "${CONFIGURE_OPTIONS};-DSAMRUTILS_INSTALL_DIR=${SAMRUTILS_INSTALL_DIR}" )
    SET( CONFIGURE_OPTIONS "${CONFIGURE_OPTIONS};-DTPL_DIRECTORY=${CMAKE_INSTALL_PREFIX}" )
    IF ( DISABLE_THREAD_CHANGES )
        SET( CONFIGURE_OPTIONS "${CONFIGURE_OPTIONS};-DDISABLE_THREAD_CHANGES=${DISABLE_THREAD_CHANGES}" )
    ENDIF()
    IF ( TEST_MAX_PROCS )
        SET( CONFIGURE_OPTIONS "${CONFIGURE_OPTIONS};-DTEST_MAX_PROCS=${TEST_MAX_PROCS}" )
    ENDIF()
ENDIF()


# Build SAMRUtils
IF ( CMAKE_BUILD_SAMRUTILS )
    EXTERNALPROJECT_ADD(
        SAMRUTILS
        URL                 "${SAMRUTILS_CMAKE_URL}"
        DOWNLOAD_DIR        "${SAMRUTILS_CMAKE_DOWNLOAD_DIR}"
        SOURCE_DIR          "${SAMRUTILS_CMAKE_SOURCE_DIR}"
        UPDATE_COMMAND      ""
        CMAKE_ARGS          "${CONFIGURE_OPTIONS}"
        BUILD_COMMAND       make -j ${PROCS_INSTALL} VERBOSE=1
        BUILD_IN_SOURCE     0
        INSTALL_COMMAND     make install
        DEPENDS             LAPACK HDF5 HYPRE PETSC ZLIB BOOST SAMRAI
        LOG_DOWNLOAD 1   LOG_UPDATE 1   LOG_CONFIGURE 1   LOG_BUILD 1   LOG_TEST 1   LOG_INSTALL 1
    )
    ADD_TPL_SAVE_LOGS( SAMRUTILS )
    ADD_TPL_CLEAN( SAMRUTILS )
ELSE()
    ADD_TPL_EMPTY( SAMRUTILS )
ENDIF()



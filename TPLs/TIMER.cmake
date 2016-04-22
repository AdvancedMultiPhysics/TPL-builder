# This will configure and build Timer
# User can configure the source path by specifying TIMER_SRC_DIR,
#    the download path by specifying TIMER_URL, or the installed 
#    location by specifying TIMER_INSTALL_DIR


# Intialize download/src/install vars
SET( TIMER_BUILD_DIR "${CMAKE_BINARY_DIR}/TIMER-prefix/src/TIMER-build" )
IF ( TIMER_URL ) 
    MESSAGE_TPL("   TIMER_URL = ${TIMER_URL}")
    SET( TIMER_SRC_DIR "${CMAKE_BINARY_DIR}/TIMER-prefix/src/TIMER-src" )
    SET( TIMER_CMAKE_URL            "${TIMER_URL}"     )
    SET( TIMER_CMAKE_DOWNLOAD_DIR   "${TIMER_SRC_DIR}" )
    SET( TIMER_CMAKE_DOWNLOAD_CMD   URL                )
    SET( TIMER_CMAKE_SOURCE_DIR     "${TIMER_SRC_DIR}" )
    SET( TIMER_CMAKE_INSTALL_DIR "${CMAKE_INSTALL_PREFIX}/timer" )
    SET( CMAKE_BUILD_TIMER TRUE )
ELSEIF ( TIMER_SRC_DIR )
    VERIFY_PATH("${TIMER_SRC_DIR}")
    MESSAGE_TPL("   TIMER_SRC_DIR = ${TIMER_SRC_DIR}")
    SET( TIMER_CMAKE_URL            ""                  )
    SET( TIMER_CMAKE_DOWNLOAD_DIR   ""                  )
    SET( TIMER_CMAKE_DOWNLOAD_CMD   URL                 )
    SET( TIMER_CMAKE_SOURCE_DIR     "${TIMER_SRC_DIR}" )
    SET( TIMER_CMAKE_INSTALL_DIR "${CMAKE_INSTALL_PREFIX}/timer" )
    SET( CMAKE_BUILD_TIMER TRUE )
ELSEIF ( TIMER_INSTALL_DIR ) 
    SET( TIMER_CMAKE_INSTALL_DIR "${TIMER_INSTALL_DIR}" )
    SET( CMAKE_BUILD_TIMER FALSE )
    # Check that the libraries exist
    FIND_LIBRARY(TIMER_LIB timerutility "${TIMER_INSTALL_DIR}/lib")
    IF ( NOT TIMER_LIB )
        MESSAGE(FATAL_ERROR "Timer library does not exist in \"${TIMER_INSTALL_DIR}/lib\"")
    ENDIF()
ELSE()
    MESSAGE(FATAL_ERROR "Please specify TIMER_SRC_DIR, TIMER_URL, or TIMER_INSTALL_DIR")
ENDIF()
FILE( MAKE_DIRECTORY "${TIMER_CMAKE_INSTALL_DIR}" )
SET( TIMER_INSTALL_DIR "${TIMER_CMAKE_INSTALL_DIR}" )
MESSAGE_TPL( "   TIMER_INSTALL_DIR = ${TIMER_INSTALL_DIR}" )
FILE( APPEND "${CMAKE_INSTALL_PREFIX}/TPLs.cmake" "SET(TIMER_INSTALL_DIR \"${TIMER_INSTALL_DIR}\")\n" )


# Configure Timer
IF ( CMAKE_BUILD_TIMER )
    SET( CONFIGURE_OPTIONS "${CMAKE_ARGS}" )
    SET( CONFIGURE_OPTIONS "${CONFIGURE_OPTIONS};-DCMAKE_BUILD_TYPE=${CMAKE_BUILD_TYPE}" )
    SET( CONFIGURE_OPTIONS "${CONFIGURE_OPTIONS};-DCMAKE_INSTALL_PREFIX=${TIMER_CMAKE_INSTALL_DIR}" )
    SET( CONFIGURE_OPTIONS "${CONFIGURE_OPTIONS};-DMPI_COMPILER:BOOL=true" )
    IF ( TEST_MAX_PROCS )
        SET( CONFIGURE_OPTIONS "${CONFIGURE_OPTIONS};-DTEST_MAX_PROCS=${TEST_MAX_PROCS}" )
    ENDIF()
    IF ( TIMER_USE_MATLAB )
        SET( CONFIGURE_OPTIONS "${CONFIGURE_OPTIONS};-DUSE_MATLAB:BOOL=true" )
        SET( CONFIGURE_OPTIONS "${CONFIGURE_OPTIONS};-DMATLAB_DIRECTORY=${MATLAB_DIRECTORY}" )
    ENDIF()
    IF ( TIMER_MPI_INCLUDE )
        SET( CONFIGURE_OPTIONS "${CONFIGURE_OPTIONS};-DMPI_INCLUDE=${TIMER_MPI_INCLUDE}" )
    ENDIF()
    IF ( TIMER_MPI_LINK_FLAGS )
        SET( CONFIGURE_OPTIONS "${CONFIGURE_OPTIONS};-DMPI_LINK_FLAGS=${TIMER_MPI_LINK_FLAGS}" )
    ENDIF()
    IF ( TIMER_MPI_LIBRARIES )
        SET( CONFIGURE_OPTIONS "${CONFIGURE_OPTIONS};-DMPI_LIBRARIES=${TIMER_MPI_LIBRARIES}" )
    ENDIF()
    MESSAGE("CONFIGURE_OPTIONS ${CONFIGURE_OPTIONS}")
ENDIF()


# Build Timer
IF ( CMAKE_BUILD_TIMER )
    EXTERNALPROJECT_ADD(
        TIMER
        URL                 "${TIMER_CMAKE_URL}"
        DOWNLOAD_DIR        "${TIMER_CMAKE_DOWNLOAD_DIR}"
        SOURCE_DIR          "${TIMER_CMAKE_SOURCE_DIR}"
        UPDATE_COMMAND      ""
        CMAKE_ARGS          "${CONFIGURE_OPTIONS}"
        BUILD_COMMAND       make -j ${PROCS_INSTALL} VERBOSE=1
        BUILD_IN_SOURCE     0
        INSTALL_COMMAND     make install
        DEPENDS             
        LOG_DOWNLOAD 1   LOG_UPDATE 1   LOG_CONFIGURE 1   LOG_BUILD 1   LOG_TEST 1   LOG_INSTALL 1
    )
    ADD_TPL_SAVE_LOGS( TIMER )
    ADD_TPL_CLEAN( TIMER )
ELSE()
    ADD_TPL_EMPTY( TIMER )
ENDIF()



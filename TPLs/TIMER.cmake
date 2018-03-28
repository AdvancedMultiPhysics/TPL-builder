# This will configure and build Timer
# User can configure the source path by specifying TIMER_SRC_DIR,
#    the download path by specifying TIMER_URL, or the installed 
#    location by specifying TIMER_INSTALL_DIR


# Intialize download/src/install vars
SET( TIMER_BUILD_DIR "${CMAKE_BINARY_DIR}/TIMER-prefix/src/TIMER-build" )
IF ( TIMER_URL ) 
    MESSAGE("   TIMER_URL = ${TIMER_URL}")
    SET( TIMER_SRC_DIR "${CMAKE_BINARY_DIR}/TIMER-prefix/src/TIMER-src" )
    SET( TIMER_CMAKE_URL            "${TIMER_URL}"     )
    SET( TIMER_CMAKE_DOWNLOAD_DIR   "${TIMER_SRC_DIR}" )
    SET( TIMER_CMAKE_DOWNLOAD_CMD   URL                )
    SET( TIMER_CMAKE_SOURCE_DIR     "${TIMER_SRC_DIR}" )
    SET( TIMER_CMAKE_INSTALL_DIR "${CMAKE_INSTALL_PREFIX}/timer" )
    SET( CMAKE_BUILD_TIMER TRUE )
ELSEIF ( TIMER_SRC_DIR )
    VERIFY_PATH("${TIMER_SRC_DIR}")
    MESSAGE("   TIMER_SRC_DIR = ${TIMER_SRC_DIR}")
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
MESSAGE( "   TIMER_INSTALL_DIR = ${TIMER_INSTALL_DIR}" )


# Configure Timer
IF ( CMAKE_BUILD_TIMER )
    SET( CONFIGURE_OPTIONS "${CMAKE_ARGS}" )
    SET( CONFIGURE_OPTIONS "${CONFIGURE_OPTIONS};-DCMAKE_BUILD_TYPE=${CMAKE_BUILD_TYPE}" )
    SET( CONFIGURE_OPTIONS "${CONFIGURE_OPTIONS};-DTIMER_INSTALL_DIR=${TIMER_INSTALL_DIR}" )
    SET( CONFIGURE_OPTIONS "${CONFIGURE_OPTIONS};-DCXX_STD=${CXX_STD}" )
    SET( CONFIGURE_OPTIONS "${CONFIGURE_OPTIONS};-DUSE_MPI=${USE_MPI}" )
    IF ( TEST_MAX_PROCS )
        SET( CONFIGURE_OPTIONS "${CONFIGURE_OPTIONS};-DTEST_MAX_PROCS=${TEST_MAX_PROCS}" )
    ENDIF()
    IF ( USE_MATLAB )
        SET( CONFIGURE_OPTIONS "${CONFIGURE_OPTIONS};-DDISABLE_THREAD_LOCAL:BOOL=true" )
    ENDIF()
    IF ( TIMER_USE_MATLAB )
        SET( CONFIGURE_OPTIONS "${CONFIGURE_OPTIONS};-DUSE_MATLAB:BOOL=true" )
        SET( CONFIGURE_OPTIONS "${CONFIGURE_OPTIONS};-DMATLAB_DIRECTORY=${MATLAB_DIRECTORY}" )
    ENDIF()
    IF ( TIMER_DISABLE_NEW_OVERLOAD )
        SET( CONFIGURE_OPTIONS "${CONFIGURE_OPTIONS};-DDISABLE_NEW_OVERLOAD:BOOL=true" )
    ENDIF()
    IF ( USE_MPI )
        SET( CONFIGURE_OPTIONS "${CONFIGURE_OPTIONS};-DMPI_COMPILER=1" )
        SET( CONFIGURE_OPTIONS "${CONFIGURE_OPTIONS};-DMPI_INCLUDE=${MPI_CXX_INCLUDE_PATH}" )
        SET( CONFIGURE_OPTIONS "${CONFIGURE_OPTIONS};-DMPI_LINK_FLAGS=${MPI_CXX_LINK_FLAGS}" )
        SET( CONFIGURE_OPTIONS "${CONFIGURE_OPTIONS};-DMPI_LIBRARIES=${MPI_CXX_LIBRARIES}" )
    ENDIF()
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


# Add the appropriate fields to FindTPLs.cmake
CONFIGURE_FILE( ${CMAKE_CURRENT_SOURCE_DIR}/cmake/FindTimer.cmake "${CMAKE_INSTALL_PREFIX}/cmake/FindTimer.cmake" COPYONLY )
FILE( APPEND "${FIND_TPLS_CMAKE}" "\n# Find TIMER\n" )
FILE( APPEND "${FIND_TPLS_CMAKE}" "IF ( TPLs_FIND_TIMER AND NOT TPL_FOUND_TIMER )\n" )
FILE( APPEND "${FIND_TPLS_CMAKE}" "    INCLUDE( \"${CMAKE_INSTALL_PREFIX}/cmake/FindTimer.cmake\" )\n" )
FILE( APPEND "${FIND_TPLS_CMAKE}" "    SET( TIMER_DIR \"${TIMER_INSTALL_DIR}\" )\n" )
FILE( APPEND "${FIND_TPLS_CMAKE}" "    SET( TIMER_DIRECTORY \"${TIMER_INSTALL_DIR}\" )\n" )
FILE( APPEND "${FIND_TPLS_CMAKE}" "    IF ( TPLs_FIND_QUIETLY )\n" )
FILE( APPEND "${FIND_TPLS_CMAKE}" "        CONFIGURE_TIMER( TRUE \"$\{$\{PROJ}_INSTALL_DIR}/include\" TRUE )\n" )
FILE( APPEND "${FIND_TPLS_CMAKE}" "    ELSE()\n" )
FILE( APPEND "${FIND_TPLS_CMAKE}" "        CONFIGURE_TIMER( TRUE \"$\{$\{PROJ}_INSTALL_DIR}/include\" FALSE )\n" )
FILE( APPEND "${FIND_TPLS_CMAKE}" "    ENDIF()\n" )
FILE( APPEND "${FIND_TPLS_CMAKE}" "    SET( TPL_INCLUDE_DIRS $\{TPL_INCLUDE_DIRS} $\{TIMER_INCLUDE} )\n" )
FILE( APPEND "${FIND_TPLS_CMAKE}" "    SET( TPL_LIBRARIES $\{TIMER_LIBS} $\{TPL_LIBRARIES} )\n" )
FILE( APPEND "${FIND_TPLS_CMAKE}" "    SET( TIMER_FOUND TRUE )\n" )
FILE( APPEND "${FIND_TPLS_CMAKE}" "    SET( TPL_FOUND_TIMER TRUE )\n" )
FILE( APPEND "${FIND_TPLS_CMAKE}" "ENDIF()\n" )
FILE( APPEND "${FIND_TPLS_CMAKE}" "\n" )


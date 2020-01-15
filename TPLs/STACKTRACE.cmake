# This will configure and build lapack wrappers
# User can configure the source path by specifying STACKTRACE_SRC_DIR
#    the download path by specifying STACKTRACE_URL, or the installed 
#    location by specifying STACKTRACE_INSTALL_DIR


# Intialize download/src/install vars
SET( STACKTRACE_SOURCE_DIR "${CMAKE_CURRENT_SOURCE_DIR}/TPLs/StackTrace" )
SET( STACKTRACE_INSTALL_DIR "${CMAKE_INSTALL_PREFIX}/StackTrace" )
VERIFY_PATH( "${STACKTRACE_SOURCE_DIR}" )


# Configure StackTrace
SET( CONFIGURE_OPTIONS "${CMAKE_ARGS}" )
SET( CONFIGURE_OPTIONS "${CONFIGURE_OPTIONS};-DINSTALL_PREFIX=${STACKTRACE_INSTALL_DIR}" )
SET( CONFIGURE_OPTIONS "${CONFIGURE_OPTIONS};-DCMAKE_BUILD_TYPE=${CMAKE_BUILD_TYPE}" )
SET( CONFIGURE_OPTIONS "${CONFIGURE_OPTIONS};-DCXX_STD=${CXX_STD}" )
IF ( USE_MPI )
    SET( CONFIGURE_OPTIONS "${CONFIGURE_OPTIONS};-DUSE_MPI:BOOL=TRUE" )
ENDIF()
LIST(FIND TPL_LIST "TIMER" index)
IF ( ${index} GREATER -1 )
    SET( STACK_DEPENDS TIMER )
    SET( CONFIGURE_OPTIONS "${CONFIGURE_OPTIONS};-DTIMER_DIRECTORY=${TIMER_INSTALL_DIR}" )
ENDIF()
EXTERNALPROJECT_ADD(
    STACKTRACE
    URL                 ""
    DOWNLOAD_DIR        ""
    SOURCE_DIR          "${STACKTRACE_SOURCE_DIR}"
    UPDATE_COMMAND      ""
    BUILD_IN_SOURCE     0
    INSTALL_DIR         "${STACKTRACE_INSTALL_DIR}"
    CMAKE_ARGS          "${CONFIGURE_OPTIONS}"
    BUILD_COMMAND       make install -j ${PROCS_INSTALL} VERBOSE=1
    DEPENDS             ${STACK_DEPENDS}
    LOG_DOWNLOAD 1   LOG_UPDATE 1   LOG_CONFIGURE 1   LOG_BUILD 1   LOG_TEST 1   LOG_INSTALL 1
)
ADD_TPL_SAVE_LOGS( STACKTRACE )
ADD_TPL_CLEAN( STACKTRACE )


# Add the appropriate fields to FindTPLs.cmake
FILE( APPEND "${FIND_TPLS_CMAKE}" "\n# Find STACKTRACE\n" )
FILE( APPEND "${FIND_TPLS_CMAKE}" "IF ( TPLs_FIND_STACKTRACE AND NOT TPL_FOUND_STACKTRACE )\n" )
FILE( APPEND "${FIND_TPLS_CMAKE}" "    SET( CMAKE_MODULE_PATH ${STACKTRACE_INSTALL_DIR} $\{CMAKE_MODULE_PATH} )\n" )
FILE( APPEND "${FIND_TPLS_CMAKE}" "    FIND_PACKAGE( StackTrace )\n" )
FILE( APPEND "${FIND_TPLS_CMAKE}" "    SET( TPL_INCLUDE_DIRS $\{StackTrace_INCLUDE_DIRS} $\{TPL_INCLUDE_DIRS} )\n" )
FILE( APPEND "${FIND_TPLS_CMAKE}" "    SET( TPL_LIBRARIES $\{StackTrace_LIBRARIES} $\{TPL_LIBRARIES} )\n" )
FILE( APPEND "${FIND_TPLS_CMAKE}" "    SET( TPL_FOUND_STACKTRACE $\{StackTrace_FOUND} )\n" )
FILE( APPEND "${FIND_TPLS_CMAKE}" "ENDIF()\n" )
FILE( APPEND "${FIND_TPLS_CMAKE}" "\n" )

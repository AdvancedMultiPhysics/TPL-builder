# This will configure and build zlib
# User can configure the source path by specifying ZLIB_SRC_DIR
#    the download path by specifying ZLIB_URL, or the installed 
#    location by specifying ZLIB_INSTALL_DIR


# Intialize download/src/install vars
SET( ZLIB_BUILD_DIR "${CMAKE_BINARY_DIR}/ZLIB-prefix/src/ZLIB-build" )
IF ( ZLIB_URL ) 
    MESSAGE("   ZLIB_URL = ${ZLIB_URL}")
    SET( ZLIB_CMAKE_URL            "${ZLIB_URL}"        )
    SET( ZLIB_CMAKE_DOWNLOAD_DIR   "${ZLIB_BUILD_DIR}"  )
    SET( ZLIB_CMAKE_SOURCE_DIR     "${ZLIB_BUILD_DIR}"  )
    SET( ZLIB_CMAKE_INSTALL_DIR "${CMAKE_INSTALL_PREFIX}/zlib" )
    SET( CMAKE_BUILD_ZLIB TRUE )
ELSEIF ( ZLIB_SRC_DIR )
    VERIFY_PATH("${ZLIB_SRC_DIR}")
    MESSAGE("   ZLIB_SRC_DIR = ${ZLIB_SRC_DIR}")
    SET( ZLIB_CMAKE_URL                                 )
    SET( ZLIB_CMAKE_DOWNLOAD_DIR                        )
    SET( ZLIB_CMAKE_SOURCE_DIR     "${ZLIB_SRC_DIR}"    )
    SET( ZLIB_CMAKE_INSTALL_DIR "${CMAKE_INSTALL_PREFIX}/zlib" )
    SET( CMAKE_BUILD_ZLIB TRUE )
ELSEIF ( ZLIB_INSTALL_DIR ) 
    SET( ZLIB_CMAKE_INSTALL_DIR "${ZLIB_INSTALL_DIR}" )
    SET( CMAKE_BUILD_ZLIB FALSE )
ELSE()
    MESSAGE(FATAL_ERROR "Please specify ZLIB_SRC_DIR, ZLIB_URL, or ZLIB_INSTALL_DIR")
ENDIF()
FILE( MAKE_DIRECTORY "${ZLIB_CMAKE_INSTALL_DIR}" )
SET( ZLIB_INSTALL_DIR "${ZLIB_CMAKE_INSTALL_DIR}" )
MESSAGE( "   ZLIB_INSTALL_DIR = ${ZLIB_INSTALL_DIR}" )


# Build zlib
IF ( CMAKE_BUILD_ZLIB ) 
    SET( ZLIB_ARGS "${CMAKE_ARGS}" )
    IF ( CMAKE_SYSTEM_NAME )
        IF ( ${CMAKE_SYSTEM_NAME} STREQUAL "Generic" ) 
            SET( ZLIB_ARGS "${ZLIB_ARGS};-DCMAKE_SYSTEM_NAME=${CMAKE_SYSTEM_NAME};-DUNIX:BOOL=ON" )
        ENDIF()
    ENDIF()
    EXTERNALPROJECT_ADD(
        ZLIB
        URL                 "${ZLIB_CMAKE_URL}"
        DOWNLOAD_DIR        "${ZLIB_CMAKE_DOWNLOAD_DIR}"
        SOURCE_DIR          "${ZLIB_SRC_DIR}"
        UPDATE_COMMAND      ""
        BUILD_IN_SOURCE     0
        INSTALL_DIR         "${ZLIB_INSTALL_DIR}"
        CMAKE_ARGS          "${ZLIB_ARGS};-DCMAKE_INSTALL_PREFIX=${CMAKE_INSTALL_PREFIX}/zlib"
        BUILD_COMMAND       make install -j ${PROCS_INSTALL} VERBOSE=1
        LOG_DOWNLOAD 1   LOG_UPDATE 1   LOG_CONFIGURE 1   LOG_BUILD 1   LOG_TEST 1   LOG_INSTALL 1
    )
    SET( ZLIB_INCLUDE_DIR "${ZLIB_INSTALL_DIR}/include")
    SET( ZLIB_LIB_DIR "${ZLIB_INSTALL_DIR}/lib")
    ADD_TPL_SAVE_LOGS( ZLIB )
    ADD_TPL_CLEAN( ZLIB )
ELSE()
    VERIFY_PATH( "${ZLIB_INSTALL_DIR}" )
    IF ( NOT ZLIB_INCLUDE_DIR )
        SET( ZLIB_INCLUDE_DIR "${ZLIB_INSTALL_DIR}" )
        IF ( EXISTS "${ZLIB_INCLUDE_DIR}/include" )
            SET( ZLIB_INCLUDE_DIR "${ZLIB_INSTALL_DIR}/include" )
        ENDIF()
    ENDIF()
    IF ( NOT ZLIB_LIB_DIR )
        SET( ZLIB_LIB_DIR "${ZLIB_INSTALL_DIR}" )
        IF ( EXISTS "${ZLIB_INSTALL_DIR}/lib" )
            SET( ZLIB_LIB_DIR "${ZLIB_INSTALL_DIR}/lib" )
        ENDIF()
    ENDIF()
    IF ( ENABLE_STATIC ) 
        FIND_LIBRARY( ZLIB_LIBRARY    NAMES libz.a     PATHS "${ZLIB_LIB_DIR}"  NO_DEFAULT_PATH )
        FIND_LIBRARY( ZLIB_LIBRARY    NAMES z          PATHS "${ZLIB_LIB_DIR}"  NO_DEFAULT_PATH )
    ELSEIF( ENABLE_SHARED ) 
        FIND_LIBRARY( ZLIB_LIBRARY    NAMES libz.so    PATHS "${ZLIB_LIB_DIR}"  NO_DEFAULT_PATH )
        FIND_LIBRARY( ZLIB_LIBRARY    NAMES z          PATHS "${ZLIB_LIB_DIR}"  NO_DEFAULT_PATH )
    ELSE()
        MESSAGE(FATAL_ERROR "Both static and shared libraries are disabled")
    ENDIF()
    IF ( NOT ZLIB_LIBRARY )
        MESSAGE(FATAL_ERROR "No sutable zlib library found in ${ZLIB_INSTALL_DIR}")
    ENDIF()
    ADD_TPL_EMPTY( ZLIB )
ENDIF()
MESSAGE("   ZLIB_INCLUDE_DIR=${ZLIB_INCLUDE_DIR}")
MESSAGE("   ZLIB_LIB_DIR=${ZLIB_LIB_DIR}")


# Add the appropriate fields to FindTPLs.cmake
FILE( APPEND "${FIND_TPLS_CMAKE}" "\n# Find ZLIB\n" )
FILE( APPEND "${FIND_TPLS_CMAKE}" "IF ( TPLs_FIND_ZLIB AND NOT TPL_FOUND_ZLIB )\n" )
FILE( APPEND "${FIND_TPLS_CMAKE}" "    SET( TPL_INCLUDE_DIRS $\{TPL_INCLUDE_DIRS} ${ZLIB_INCLUDE_DIR} )\n" )
FILE( APPEND "${FIND_TPLS_CMAKE}" "    SET( TPL_LIBRARIES ${ZLIB_LIBRARY} $\{TPL_LIBRARIES} )\n" )
FILE( APPEND "${FIND_TPLS_CMAKE}" "    SET( ZLIB_FOUND TRUE )\n" )
FILE( APPEND "${FIND_TPLS_CMAKE}" "    SET( TPL_FOUND_ZLIB TRUE )\n" )
FILE( APPEND "${FIND_TPLS_CMAKE}" "ENDIF()\n" )
FILE( APPEND "${FIND_TPLS_CMAKE}" "\n" )


# This will configure and build cppcheck
# User can configure the source path by specifying CPPCHECK_SRC_DIR,
#    the download path by specifying CPPCHECK__URL, or the installed 
#    location by specifying CPPCHECK__INSTALL_DIR


# Intialize download/src/install vars
SET( CPPCHECK_BUILD_DIR "${CMAKE_BINARY_DIR}/CPPCHECK-prefix/src/CPPCHECK-build" )
IF ( CPPCHECK_URL ) 
    MESSAGE("   CPPCHECK_URL = ${CPPCHECK_URL}")
    SET( CPPCHECK_SRC_DIR "${CMAKE_BINARY_DIR}/CPPCHECK-prefix/src/CPPCHECK-src" )
    SET( CPPCHECK_CMAKE_URL            "${CPPCHECK_URL}"     )
    SET( CPPCHECK_CMAKE_DOWNLOAD_DIR   "${CPPCHECK_SRC_DIR}" )
    SET( CPPCHECK_CMAKE_SOURCE_DIR     "${CPPCHECK_SRC_DIR}" )
    SET( CPPCHECK_CMAKE_INSTALL_DIR "${CMAKE_INSTALL_PREFIX}/cppcheck" )
    SET( CMAKE_BUILD_CPPCHECK TRUE )
ELSEIF ( CPPCHECK_SRC_DIR )
    VERIFY_PATH("${CPPCHECK_SRC_DIR}")
    MESSAGE("   CPPCHECK_SRC_DIR = ${CPPCHECK_SRC_DIR}")
    SET( CPPCHECK_CMAKE_URL            ""                  )
    SET( CPPCHECK_CMAKE_DOWNLOAD_DIR   ""                  )
    SET( CPPCHECK_CMAKE_SOURCE_DIR     "${CPPCHECK_SRC_DIR}" )
    SET( CPPCHECK_CMAKE_INSTALL_DIR "${CMAKE_INSTALL_PREFIX}/cppcheck" )
    SET( CMAKE_BUILD_CPPCHECK TRUE )
ELSEIF ( CPPCHECK_INSTALL_DIR ) 
    SET( CPPCHECK_CMAKE_INSTALL_DIR "${CPPCHECK_INSTALL_DIR}" )
    SET( CMAKE_BUILD_CPPCHECK FALSE )
ELSE()
    MESSAGE(FATAL_ERROR "Please specify CPPCHECK_SRC_DIR, CPPCHECK_URL, or CPPCHECK_INSTALL_DIR")
ENDIF()
SET( CPPCHECK_INSTALL_DIR "${CPPCHECK_CMAKE_INSTALL_DIR}" )
MESSAGE( "   CPPCHECK_INSTALL_DIR = ${CPPCHECK_INSTALL_DIR}" )

IF ( CMAKE_BUILD_CPPCHECK )
    SET( CPPCHECK_CONFIGURE_OPTIONS -DCMAKE_C_COMPILER=${CMAKE_C_COMPILER} -DCMAKE_CXX_COMPILER=${CMAKE_CXX_COMPILER} -DCMAKE_BUILD_TYPE=Release )
    IF ( USING_ICC )
       SET( CPPCHECK_CONFIGURE_OPTIONS ${CPPCHECK_CONFIGURE_OPTIONS} -DCMAKE_CXX_FLAGS=-D_GLIBCXX_USE_CXX11_ABI=0 )
    ENDIF()
    MESSAGE( "Configuring cppcheck with ${CPPCHECK_CONFIGURE_OPTIONS}")

    # Configure cppcheck
    ADD_TPL(
        CPPCHECK
        URL                 "${CPPCHECK_CMAKE_URL}"
        TIMEOUT             300
        DOWNLOAD_DIR        "${CPPCHECK_CMAKE_DOWNLOAD_DIR}"
        SOURCE_DIR          "${CPPCHECK_CMAKE_SOURCE_DIR}"
        UPDATE_COMMAND      ""
        BUILD_IN_SOURCE     0
        INSTALL_DIR         ${CMAKE_INSTALL_PREFIX}/cppcheck
        CMAKE_ARGS          ${CPPCHECK_CONFIGURE_OPTIONS}  -DCMAKE_INSTALL_PREFIX=${CMAKE_INSTALL_PREFIX}/cppcheck
        BUILD_COMMAND       $(MAKE) install VERBOSE=1
        CLEAN_COMMAND       $(MAKE) clean
        DEPENDS             
        LOG_DOWNLOAD 1   LOG_UPDATE 1   LOG_CONFIGURE 1   LOG_BUILD 1   LOG_TEST 1   LOG_INSTALL 1
        )
ELSE()
    ADD_TPL_EMPTY( CPPCHECK )
ENDIF()

# Add the appropriate fields to FindTPLs.cmake
FILE( APPEND "${FIND_TPLS_CMAKE}" "\n# Find CPPCHECK\n" )
FILE( APPEND "${FIND_TPLS_CMAKE}" "IF ( TPLs_FIND_CPPCHECK AND NOT TPL_FOUND_CPPCHECK )\n" )
FILE( APPEND "${FIND_TPLS_CMAKE}" "    SET( CPPCHECK_DIRECTORY ${CPPCHECK_INSTALL_DIR} )\n"  )
FILE( APPEND "${FIND_TPLS_CMAKE}" "    SET( CPPCHECK_FOUND TRUE )\n" )
FILE( APPEND "${FIND_TPLS_CMAKE}" "    SET( TPL_FOUND_CPPCHECK TRUE )\n" )
FILE( APPEND "${FIND_TPLS_CMAKE}" "    # SET( CMAKE_CXX_CPPCHECK \"${CPPCHECK_INSTALL_DIR}/bin/cppcheck\" )\n" )
FILE( APPEND "${FIND_TPLS_CMAKE}" "ENDIF()\n" )
FILE( APPEND "${FIND_TPLS_CMAKE}" "\n" )


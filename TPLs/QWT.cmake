# This will configure and build QWT
# User can configure the source path by specifying QWT_SRC_DIR
#    the download path by specifying QWT_URL, or the installed 
#    location by specifying QWT_INSTALL_DIR


# Intialize download/src/install vars
SET( QWT_BUILD_DIR "${CMAKE_BINARY_DIR}/QWT-prefix/src/QWT-build" )
IF ( QWT_URL ) 
    MESSAGE("   QWT_URL = ${QWT_URL}")
    SET( QWT_SRC_DIR "${CMAKE_BINARY_DIR}/QWT-prefix/src/QWT-src" )
    SET( QWT_CMAKE_URL            "${QWT_URL}"     )
    SET( QWT_CMAKE_DOWNLOAD_DIR   "${QWT_SRC_DIR}" )
    SET( QWT_CMAKE_SOURCE_DIR     "${QWT_SRC_DIR}" )
    SET( QWT_CMAKE_INSTALL_DIR "${CMAKE_INSTALL_PREFIX}/QWT" )
    SET( CMAKE_BUILD_QWT TRUE )
ELSEIF ( QWT_SRC_DIR )
    VERIFY_PATH("${QWT_SRC_DIR}")
    MESSAGE("   QWT_SRC_DIR = ${QWT_SRC_DIR}")
    SET( QWT_CMAKE_URL            ""                  )
    SET( QWT_CMAKE_DOWNLOAD_DIR   ""                  )
    SET( QWT_CMAKE_SOURCE_DIR     "${QWT_SRC_DIR}" )
    SET( QWT_CMAKE_INSTALL_DIR "${CMAKE_INSTALL_PREFIX}/QWT" )
    SET( CMAKE_BUILD_QWT TRUE )
ELSEIF ( QWT_INSTALL_DIR ) 
    SET( QWT_CMAKE_INSTALL_DIR "${QWT_INSTALL_DIR}" )
    SET( CMAKE_BUILD_QWT FALSE )
ELSE()
    MESSAGE(FATAL_ERROR "Please specify QWT_SRC_DIR, QWT_URL, or QWT_INSTALL_DIR")
ENDIF()
SET( QWT_INSTALL_DIR "${QWT_CMAKE_INSTALL_DIR}" )
MESSAGE( "   QWT_INSTALL_DIR = ${QWT_INSTALL_DIR}" )


# Configure optional/required TPLs
CONFIGURE_DEPENDENCIES( QWT OPTIONAL QT )


IF ( CMAKE_BUILD_QWT )
    # Configure QWT
    ADD_TPL(
        QWT
        URL                 "${QWT_CMAKE_URL}"
        TIMEOUT             300
        DOWNLOAD_DIR        "${QWT_CMAKE_DOWNLOAD_DIR}"
        SOURCE_DIR          "${QWT_CMAKE_SOURCE_DIR}"
        PATCH_COMMAND       patch -p1 -i ${CMAKE_CURRENT_LIST_DIR}/../patches/QWT.patch
        UPDATE_COMMAND      ""
        BUILD_IN_SOURCE     1
        INSTALL_DIR         "${QWT_INSTALL_DIR}"
        CONFIGURE_COMMAND   ${QT_QMAKE_EXECUTABLE} QWT_INSTALL_PREFIX=${QWT_INSTALL_DIR} qwt.pro
        BUILD_COMMAND       $(MAKE) install
        LOG_DOWNLOAD 1   LOG_UPDATE 1   LOG_CONFIGURE 1   LOG_BUILD 1   LOG_TEST 1   LOG_INSTALL 1
    )
ELSE()
    ADD_TPL_EMPTY( QWT )
ENDIF()

# Add the appropriate fields to FindTPLs.cmake
FILE( APPEND "${FIND_TPLS_CMAKE}" "\n# Find QWT\n" )
FILE( APPEND "${FIND_TPLS_CMAKE}" "IF ( TPLs_FIND_QWT AND NOT TPLs_QWT_FOUND )\n" )
FILE( APPEND "${FIND_TPLS_CMAKE}" "    SET( QWT_INSTALL_DIR ${QWT_INSTALL_DIR} )\n" )
FILE( APPEND "${FIND_TPLS_CMAKE}" "    FIND_LIBRARY( QWT_LIB REQUIRED NAMES qwt  PATHS \"$\{QWT_INSTALL_DIR}/lib\" \"$\{QWT_INSTALL_DIR}/lib64\" NO_DEFAULT_PATH )\n" )
FILE( APPEND "${FIND_TPLS_CMAKE}" "    ADD_TPL_LIBRARY( QWT $\{qwt} )\n" )
FILE( APPEND "${FIND_TPLS_CMAKE}" "ENDIF()\n" )
FILE( APPEND "${FIND_TPLS_CMAKE}" "\n" )

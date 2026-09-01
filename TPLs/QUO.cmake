# This will configure and build QUO
# User can configure the source path by specifying QUO_SRC_DIR,
#    the download path by specifying QUO_URL, or the installed
#    location by specifying QUO_INSTALL_DIR


# Intialize download/src/install vars
SET( QUO_BUILD_DIR "${CMAKE_BINARY_DIR}/QUO-prefix/src/QUO-build" )
IF ( QUO_URL )
    MESSAGE("   QUO_URL = ${QUO_URL}")
    SET( QUO_SRC_DIR "${CMAKE_BINARY_DIR}/QUO-prefix/src/QUO-src" )
    SET( QUO_CMAKE_URL          "${QUO_URL}"     )
    SET( QUO_CMAKE_DOWNLOAD_DIR "${QUO_SRC_DIR}" )
    SET( QUO_CMAKE_SOURCE_DIR   "${QUO_SRC_DIR}" )
    SET( QUO_CMAKE_INSTALL_DIR "${CMAKE_INSTALL_PREFIX}/quo" )
    SET( CMAKE_BUILD_QUO TRUE )
ELSEIF ( QUO_SRC_DIR )
    VERIFY_PATH("${QUO_SRC_DIR}")
    MESSAGE("   QUO_SRC_DIR = ${QUO_SRC_DIR}")
    SET( QUO_CMAKE_URL          ""               )
    SET( QUO_CMAKE_DOWNLOAD_DIR ""               )
    SET( QUO_CMAKE_SOURCE_DIR   "${QUO_SRC_DIR}" )
    SET( QUO_CMAKE_INSTALL_DIR "${CMAKE_INSTALL_PREFIX}/quo" )
    SET( CMAKE_BUILD_QUO TRUE )
ELSEIF ( QUO_INSTALL_DIR )
    SET( QUO_CMAKE_INSTALL_DIR "${QUO_INSTALL_DIR}" )
    SET( CMAKE_BUILD_QUO FALSE )
ELSE()
    MESSAGE(FATAL_ERROR "Please specify QUO_URL, QUO_SRC_DIR, or QUO_INSTALL_DIR")
ENDIF()
SET( QUO_INSTALL_DIR "${QUO_CMAKE_INSTALL_DIR}" )
MESSAGE( "   QUO_INSTALL_DIR = ${QUO_INSTALL_DIR}" )


# Configure optional/required TPLs
IF ( NOT USE_MPI )
    MESSAGE( FATAL_ERROR "QUO requires MPI. Please configure with USE_MPI=ON." )
ENDIF()
CONFIGURE_DEPENDENCIES( QUO )


# Configure QUO
IF ( CMAKE_BUILD_QUO )
    SET( QUO_CONFIGURE_OPTIONS --prefix=${QUO_CMAKE_INSTALL_DIR} )
    IF ( ENABLE_SHARED AND ENABLE_STATIC )
        LIST( APPEND QUO_CONFIGURE_OPTIONS --enable-shared=yes --enable-static=yes )
    ELSEIF ( ENABLE_SHARED )
        LIST( APPEND QUO_CONFIGURE_OPTIONS --enable-shared=yes --enable-static=no )
    ELSEIF ( ENABLE_STATIC )
        LIST( APPEND QUO_CONFIGURE_OPTIONS --enable-shared=no --enable-static=yes )
    ENDIF()

    ADD_TPL(
        QUO
        URL                 "${QUO_CMAKE_URL}"
        DOWNLOAD_DIR        "${QUO_CMAKE_DOWNLOAD_DIR}"
        SOURCE_DIR          "${QUO_CMAKE_SOURCE_DIR}"
        UPDATE_COMMAND      ""
        CONFIGURE_COMMAND   ${QUO_CMAKE_SOURCE_DIR}/configure ${QUO_CONFIGURE_OPTIONS} ${ENV_VARS}
        BUILD_COMMAND       $(MAKE) VERBOSE=1
        BUILD_IN_SOURCE     0
        INSTALL_COMMAND     $(MAKE) install
        CLEAN_COMMAND       $(MAKE) clean
        LOG_DOWNLOAD 1   LOG_UPDATE 1   LOG_CONFIGURE 1   LOG_BUILD 1   LOG_TEST 1   LOG_INSTALL 1
    )
ELSE()
    ADD_TPL_EMPTY( QUO )
ENDIF()


# Add the appropriate fields to FindTPLs.cmake
FILE( APPEND "${FIND_TPLS_CMAKE}" "\n# Find QUO\n" )
FILE( APPEND "${FIND_TPLS_CMAKE}" "IF ( TPLs_FIND_QUO AND NOT TPLs_QUO_FOUND )\n" )
FILE( APPEND "${FIND_TPLS_CMAKE}" "    SET( QUO_INSTALL_DIR \"${QUO_INSTALL_DIR}\" )\n" )
FILE( APPEND "${FIND_TPLS_CMAKE}" "    SET( QUO_INCLUDE_DIR \"${QUO_INSTALL_DIR}/include\" )\n" )
FILE( APPEND "${FIND_TPLS_CMAKE}" "    IF ( EXISTS \"${QUO_INSTALL_DIR}/lib\" )\n" )
FILE( APPEND "${FIND_TPLS_CMAKE}" "        SET( QUO_LIB_DIR \"${QUO_INSTALL_DIR}/lib\" )\n" )
FILE( APPEND "${FIND_TPLS_CMAKE}" "    ELSEIF ( EXISTS \"${QUO_INSTALL_DIR}/lib64\" )\n" )
FILE( APPEND "${FIND_TPLS_CMAKE}" "        SET( QUO_LIB_DIR \"${QUO_INSTALL_DIR}/lib64\" )\n" )
FILE( APPEND "${FIND_TPLS_CMAKE}" "    ENDIF()\n" )
FILE( APPEND "${FIND_TPLS_CMAKE}" "    FIND_LIBRARY( QUO_LIB NAMES quo PATHS $\{QUO_LIB_DIR} NO_DEFAULT_PATH )\n" )
FILE( APPEND "${FIND_TPLS_CMAKE}" "    IF ( NOT QUO_LIB )\n" )
FILE( APPEND "${FIND_TPLS_CMAKE}" "        MESSAGE(FATAL_ERROR \"QUO library not found in $\{QUO_LIB_DIR}\")\n" )
FILE( APPEND "${FIND_TPLS_CMAKE}" "    ENDIF()\n" )
FILE( APPEND "${FIND_TPLS_CMAKE}" "    ADD_TPL_LIBRARY( QUO $\{QUO_LIB} )\n" )
FILE( APPEND "${FIND_TPLS_CMAKE}" "ENDIF()\n" )
FILE( APPEND "${FIND_TPLS_CMAKE}" "\n" )

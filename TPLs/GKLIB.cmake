# This will configure and build metis
# User can configure the source path by specifying GKLIB_SRC_DIR,
#    the download path by specifying GKLIB_URL, or the installed 
#    location by specifying GKLIB_INSTALL_DIR


# Intialize download/src/install vars
SET( GKLIB_BUILD_DIR "${CMAKE_BINARY_DIR}/GKLIB-prefix/src/GKLIB-build" )
IF ( GKLIB_URL ) 
    MESSAGE("   GKLIB_URL = ${GKLIB_URL}")
    SET( GKLIB_CMAKE_URL            "${GKLIB_URL}"       )
    SET( GKLIB_CMAKE_DOWNLOAD_DIR   "${GKLIB_BUILD_DIR}" )
    SET( GKLIB_CMAKE_SOURCE_DIR     "${GKLIB_BUILD_DIR}" )
    SET( GKLIB_CMAKE_INSTALL_DIR "${CMAKE_INSTALL_PREFIX}/gklib" )
    SET( CMAKE_BUILD_GKLIB TRUE )
ELSEIF ( GKLIB_SRC_DIR )
    VERIFY_PATH("${GKLIB_SRC_DIR}")
    MESSAGE("   GKLIB_SRC_DIR = ${GKLIB_SRC_DIR}")
    SET( GKLIB_CMAKE_URL            "${GKLIB_SRC_DIR}"   )
    SET( GKLIB_CMAKE_DOWNLOAD_DIR   "${GKLIB_BUILD_DIR}" )
    SET( GKLIB_CMAKE_SOURCE_DIR     "${GKLIB_BUILD_DIR}" )
    SET( GKLIB_CMAKE_INSTALL_DIR "${CMAKE_INSTALL_PREFIX}/gklib" )
    SET( CMAKE_BUILD_GKLIB TRUE )
ELSEIF ( GKLIB_INSTALL_DIR ) 
    SET( GKLIB_CMAKE_INSTALL_DIR "${GKLIB_INSTALL_DIR}" )
    SET( CMAKE_BUILD_GKLIB FALSE )
ELSE()
    MESSAGE(FATAL_ERROR "Please specify GKLIB_SRC_DIR, GKLIB_URL, or GKLIB_INSTALL_DIR")
ENDIF()
SET( GKLIB_INSTALL_DIR "${GKLIB_CMAKE_INSTALL_DIR}" )
MESSAGE( "   GKLIB_INSTALL_DIR = ${GKLIB_INSTALL_DIR}" )

SET( GKLIB_CONFIGURE_OPTIONS -DCMAKE_INSTALL_PREFIX=${GKLIB_CMAKE_INSTALL_DIR} )
SET( GKLIB_CONFIGURE_OPTIONS ${GKLIB_CONFIGURE_OPTIONS} -DCMAKE_BUILD_TYPE=${CMAKE_BUILD_TYPE} )
SET( GKLIB_CONFIGURE_OPTIONS ${GKLIB_CONFIGURE_OPTIONS} -DCMAKE_C_COMPILER=${CMAKE_C_COMPILER} )

# Configure gklib
IF ( CMAKE_BUILD_GKLIB )
    IF ( ENABLE_SHARED AND ENABLE_STATIC )
        MESSAGE(FATAL_ERROR "Compiling gklib with both static and shared libraries is not yet supported")
    ELSEIF ( ENABLE_SHARED )
        SET( GKLIB_CONFIGURE_OPTIONS ${GKLIB_CONFIGURE_OPTIONS} -DBUILD_SHARED_LIBS=ON )
    ELSEIF ( ENABLE_STATIC )
        SET( GKLIB_CONFIGURE_OPTIONS ${GKLIB_CONFIGURE_OPTIONS} -DBUILD_SHARED_LIBS=OFF )
    ENDIF()

    # Build gklib
    ADD_TPL(
        GKLIB
        URL                 "${GKLIB_CMAKE_URL}"
        DOWNLOAD_DIR        "${GKLIB_CMAKE_DOWNLOAD_DIR}"
        SOURCE_DIR          "${GKLIB_CMAKE_SOURCE_DIR}"
        UPDATE_COMMAND      ""
        CMAKE_ARGS          ${GKLIB_CONFIGURE_OPTIONS}
        BUILD_COMMAND       $(MAKE) VERBOSE=1
        BUILD_IN_SOURCE     0
        INSTALL_COMMAND     $(MAKE) install
        LOG_DOWNLOAD 1   LOG_UPDATE 1   LOG_CONFIGURE 1   LOG_BUILD 1   LOG_TEST 1   LOG_INSTALL 1
    )
ELSE()
    ADD_TPL_EMPTY( GKLIB )
ENDIF()


FILE( APPEND "${FIND_TPLS_CMAKE}" "\n# Find GKLIB\n" )
FILE( APPEND "${FIND_TPLS_CMAKE}" "IF ( TPLs_FIND_GKLIB AND NOT TPLs_GKLIB_FOUND )\n" )
FILE( APPEND "${FIND_TPLS_CMAKE}" "    SET( GKLIB_FOUND $\{USE_GKLIB} )\n" )
FILE( APPEND "${FIND_TPLS_CMAKE}" "    SET( GKLIB_INSTALL_DIR \"${GKLIB_INSTALL_DIR}\" )\n" )
FILE( APPEND "${FIND_TPLS_CMAKE}" "    SET( GKLIB_LIB_DIR \"${GKLIB_INSTALL_DIR}/lib\" )\n" )
FILE( APPEND "${FIND_TPLS_CMAKE}" "    FIND_LIBRARY( GKLIB_LIB  NAMES GKlib  PATHS $\{GKLIB_LIB_DIR}  NO_DEFAULT_PATH )\n" )
FILE( APPEND "${FIND_TPLS_CMAKE}" "    ADD_TPL_LIBRARY( GKLIB $\{GKLIB_LIB} )\n" )
FILE( APPEND "${FIND_TPLS_CMAKE}" "ENDIF()\n" )
FILE( APPEND "${FIND_TPLS_CMAKE}" "\n" )

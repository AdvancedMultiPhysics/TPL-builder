# This will configure and build kokkos
# User can configure the source path by specifying CATCH2_SRC_DIR,
#    the download path by specifying CATCH2_URL, or the installed
#    location by specifying CATCH2_INSTALL_DIR


# Intialize download/src/install vars
SET( CATCH2_BUILD_DIR "${CMAKE_BINARY_DIR}/CATCH2-prefix/src/CATCH2-build" )
IF ( CATCH2_URL )
    MESSAGE("   CATCH2_URL = ${CATCH2_URL}")
    SET( CATCH2_SRC_DIR "${CMAKE_BINARY_DIR}/CATCH2-prefix/src/CATCH2-src" )
    SET( CATCH2_CMAKE_URL            "${CATCH2_URL}"       )
    SET( CATCH2_CMAKE_DOWNLOAD_DIR   "${CATCH2_SRC_DIR}" )
    SET( CATCH2_CMAKE_SOURCE_DIR     "${CATCH2_SRC_DIR}" )
    SET( CATCH2_CMAKE_INSTALL_DIR "${CMAKE_INSTALL_PREFIX}/Catch2" )
    SET( CMAKE_BUILD_CATCH2 TRUE )
ELSEIF ( CATCH2_SRC_DIR )
    VERIFY_PATH("${CATCH2_SRC_DIR}")
    MESSAGE("   CATCH2_SRC_DIR = ${CATCH2_SRC_DIR}")
    SET( CATCH2_CMAKE_URL            ""   )
    SET( CATCH2_CMAKE_DOWNLOAD_DIR   "" )
    SET( CATCH2_CMAKE_SOURCE_DIR     "${CATCH2_SRC_DIR}" )
    SET( CATCH2_CMAKE_INSTALL_DIR "${CMAKE_INSTALL_PREFIX}/Catch2" )
    SET( CMAKE_BUILD_CATCH2 TRUE )
ELSEIF ( CATCH2_INSTALL_DIR )
    SET( CATCH2_CMAKE_INSTALL_DIR "${CATCH2_INSTALL_DIR}" )
    SET( CMAKE_BUILD_CATCH2 FALSE )
ELSE()
    MESSAGE(FATAL_ERROR "Please specify CATCH2_SRC_DIR, CATCH2_URL, or CATCH2_INSTALL_DIR")
ENDIF()
SET( CATCH2_INSTALL_DIR "${CATCH2_CMAKE_INSTALL_DIR}" )
MESSAGE( "   CATCH2_INSTALL_DIR = ${CATCH2_INSTALL_DIR}" )

IF ( CMAKE_BUILD_CATCH2 )
    SET( CATCH2_CONFIGURE_OPTIONS ${CMAKE_ARGS} )
    SET( CATCH2_CONFIGURE_OPTIONS ${CATCH2_CONFIGURE_OPTIONS} -DCMAKE_INSTALL_PREFIX=${CATCH2_CMAKE_INSTALL_DIR} )
    SET( CATCH2_CONFIGURE_OPTIONS ${CATCH2_CONFIGURE_OPTIONS} -DCMAKE_BUILD_TYPE=${CMAKE_BUILD_TYPE} )
    SET( CATCH2_CONFIGURE_OPTIONS ${CATCH2_CONFIGURE_OPTIONS} -DBUILD_TESTING=OFF )
    SET( CATCH2_CONFIGURE_OPTIONS ${CATCH2_CONFIGURE_OPTIONS} -B${CATCH2_BUILD_DIR} )
    SET( CATCH2_CONFIGURE_OPTIONS ${CATCH2_CONFIGURE_OPTIONS} -H${CATCH2_CMAKE_SOURCE_DIR} )
    MESSAGE("   CATCH2 configure options: ${CATCH2_CONFIGURE_OPTIONS}")
ENDIF()


# Build catch2
IF ( CMAKE_BUILD_CATCH2 )
    ADD_TPL(
        CATCH2
        URL                 "${CATCH2_CMAKE_URL}"
        DOWNLOAD_DIR        "${CATCH2_CMAKE_DOWNLOAD_DIR}"
        SOURCE_DIR          "${CATCH2_CMAKE_SOURCE_DIR}"
        UPDATE_COMMAND      ""
        CMAKE_ARGS          ${CATCH2_CONFIGURE_OPTIONS}
        BUILD_COMMAND       cmake --build ${CATCH2_BUILD_DIR} --target install -j 8
        BUILD_IN_SOURCE     0
        INSTALL_COMMAND     ""
        LOG_DOWNLOAD 1   LOG_UPDATE 1   LOG_CONFIGURE 1   LOG_BUILD 1   LOG_TEST 1   LOG_INSTALL 1
    )
ELSE()
    ADD_TPL_EMPTY( CATCH2 )
ENDIF()

SET( CATCH2_CMAKE_CONFIG_DIR "${CATCH2_INSTALL_DIR}/${CMAKE_INSTALL_LIBDIR}/cmake/Catch2")
MESSAGE( "CATCH2_CMAKE_CONFIG_DIR ${CATCH2_CMAKE_CONFIG_DIR}" )

# Add the appropriate fields to FindTPLs.cmake
FILE( APPEND "${FIND_TPLS_CMAKE}" "\n# Find CATCH2\n" )
FILE( APPEND "${FIND_TPLS_CMAKE}" "IF ( TPLs_FIND_CATCH2 AND NOT TPL_FOUND_CATCH2 )\n" )
FILE( APPEND "${FIND_TPLS_CMAKE}" "    SET( Catch2_DIR \"${CATCH2_CMAKE_CONFIG_DIR}\" )\n" )
FILE( APPEND "${FIND_TPLS_CMAKE}" "    FIND_PACKAGE( Catch2 REQUIRED CONFIG )\n" )
FILE( APPEND "${FIND_TPLS_CMAKE}" "    SET( CATCH2_FOUND TRUE )\n" )
FILE( APPEND "${FIND_TPLS_CMAKE}" "    SET( TPL_FOUND_CATCH2 TRUE )\n" )
FILE( APPEND "${FIND_TPLS_CMAKE}" "ENDIF()\n" )
FILE( APPEND "${FIND_TPLS_CMAKE}" "\n" )

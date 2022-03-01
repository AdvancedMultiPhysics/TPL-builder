# This will configure and build xbraid
# User can configure the source path by specifying XBRAID_SRC_DIR
#    the download path by specifying XBRAID_URL, or the installed 
#    location by specifying XBRAID_INSTALL_DIR


# Intialize download/src/install vars
SET( XBRAID_BUILD_DIR "${CMAKE_BINARY_DIR}/XBRAID-prefix/src/XBRAID-build" )
IF ( XBRAID_URL ) 
    MESSAGE("   XBRAID_URL = ${XBRAID_URL}")
    SET( XBRAID_CMAKE_URL            "${XBRAID_URL}"       )
    SET( XBRAID_CMAKE_DOWNLOAD_DIR   "${XBRAID_BUILD_DIR}" )
    SET( XBRAID_CMAKE_SOURCE_DIR     "${XBRAID_BUILD_DIR}" )
    SET( XBRAID_CMAKE_INSTALL_DIR "${CMAKE_INSTALL_PREFIX}/xbraid" )
    SET( CMAKE_BUILD_XBRAID TRUE )
ELSEIF ( XBRAID_SRC_DIR )
    MESSAGE("   XBRAID_SRC_DIR = ${XBRAID_SRC_DIR}")
    SET( XBRAID_CMAKE_URL            "${XBRAID_SRC_DIR}" )
    SET( XBRAID_CMAKE_DOWNLOAD_DIR   "${XBRAID_BUILD_DIR}" )
    SET( XBRAID_CMAKE_SOURCE_DIR     "${XBRAID_BUILD_DIR}" )
    SET( XBRAID_CMAKE_INSTALL_DIR "${CMAKE_INSTALL_PREFIX}/xbraid" )
    SET( CMAKE_BUILD_XBRAID TRUE )
ELSEIF ( XBRAID_INSTALL_DIR ) 
    SET( XBRAID_CMAKE_INSTALL_DIR "${XBRAID_INSTALL_DIR}" )
    SET( CMAKE_BUILD_XBRAID FALSE )
ELSE()
    MESSAGE(FATAL_ERROR "Please specify XBRAID_SRC_DIR, XBRAID_URL, or XBRAID_INSTALL_DIR")
ENDIF()
FILE( MAKE_DIRECTORY "${XBRAID_CMAKE_INSTALL_DIR}" )
SET( XBRAID_INSTALL_DIR "${XBRAID_CMAKE_INSTALL_DIR}" )
MESSAGE( "   XBRAID_INSTALL_DIR = ${XBRAID_INSTALL_DIR}" )


IF ( CMAKE_BUILD_XBRAID )
    EXECUTE_PROCESS( COMMAND ${CMAKE_COMMAND} -E make_directory "${XBRAID_INSTALL_DIR}/include" )
    EXECUTE_PROCESS( COMMAND ${CMAKE_COMMAND} -E make_directory "${XBRAID_INSTALL_DIR}/lib" )

    IF ( ${CMAKE_BUILD_TYPE} STREQUAL "Debug" )
        SET( XBRAID_CONFIGURE_OPTIONS debug=yes )
    ELSEIF ( (${CMAKE_BUILD_TYPE} STREQUAL "Release") OR (${CMAKE_BUILD_TYPE} STREQUAL "RelWithDebInfo") )
        SET( XBRAID_CONFIGURE_OPTIONS debug=no )
    ELSE()
        MESSAGE ( FATAL_ERROR "Unknown CMAKE_BUILD_TYPE=${CMAKE_BUILD_TYPE}" )
    ENDIF()

    ADD_TPL(
        XBRAID
        URL                 "${XBRAID_CMAKE_URL}"
        DOWNLOAD_DIR        "${XBRAID_CMAKE_DOWNLOAD_DIR}"
        SOURCE_DIR          "${XBRAID_CMAKE_SOURCE_DIR}"
        UPDATE_COMMAND      ""
	CONFIGURE_COMMAND   echo xbraid doesn't configure like the rest of the world
        BUILD_COMMAND       make braid
        BUILD_IN_SOURCE     1
        INSTALL_COMMAND     echo doesn't support installation like the rest of the world
        LOG_DOWNLOAD 1   LOG_UPDATE 1   LOG_CONFIGURE 1   LOG_BUILD 1   LOG_TEST 1   LOG_INSTALL 1
    )

    EXTERNALPROJECT_ADD_STEP(
        XBRAID
        copy-products
        COMMAND             ${CMAKE_COMMAND} -E copy "${XBRAID_CMAKE_SOURCE_DIR}/braid/libbraid.a" "${XBRAID_INSTALL_DIR}/lib/libXBRAID.a"
        COMMAND             ${CMAKE_COMMAND} -E copy "${XBRAID_CMAKE_SOURCE_DIR}/braid/adjoint.h" "${XBRAID_INSTALL_DIR}/include/adjoint.h"
        COMMAND             ${CMAKE_COMMAND} -E copy "${XBRAID_CMAKE_SOURCE_DIR}/braid/base.h" "${XBRAID_INSTALL_DIR}/include/base.h"
        COMMAND             ${CMAKE_COMMAND} -E copy "${XBRAID_CMAKE_SOURCE_DIR}/braid/braid_defs.h" "${XBRAID_INSTALL_DIR}/include/braid_defs.h"
        COMMAND             ${CMAKE_COMMAND} -E copy "${XBRAID_CMAKE_SOURCE_DIR}/braid/_braid.h" "${XBRAID_INSTALL_DIR}/include/_braid.h"
        COMMAND             ${CMAKE_COMMAND} -E copy "${XBRAID_CMAKE_SOURCE_DIR}/braid/braid.h" "${XBRAID_INSTALL_DIR}/include/braid.h"
        COMMAND             ${CMAKE_COMMAND} -E copy "${XBRAID_CMAKE_SOURCE_DIR}/braid/braid_status.h" "${XBRAID_INSTALL_DIR}/include/braid_status.h"
        COMMAND             ${CMAKE_COMMAND} -E copy "${XBRAID_CMAKE_SOURCE_DIR}/braid/braid_test.h" "${XBRAID_INSTALL_DIR}/include/braid_test.h"
        COMMAND             ${CMAKE_COMMAND} -E copy "${XBRAID_CMAKE_SOURCE_DIR}/braid/mpistubs.h" "${XBRAID_INSTALL_DIR}/include/mpistubs.h"
        COMMAND             ${CMAKE_COMMAND} -E copy "${XBRAID_CMAKE_SOURCE_DIR}/braid/status.h" "${XBRAID_INSTALL_DIR}/include/status.h"
        COMMAND             ${CMAKE_COMMAND} -E copy "${XBRAID_CMAKE_SOURCE_DIR}/braid/tape.h" "${XBRAID_INSTALL_DIR}/include/tape.h"
        COMMAND             ${CMAKE_COMMAND} -E copy "${XBRAID_CMAKE_SOURCE_DIR}/braid/util.h" "${XBRAID_INSTALL_DIR}/include/util.h"
        COMMAND             ${CMAKE_COMMAND} -E copy "${XBRAID_CMAKE_SOURCE_DIR}/braid/braid.hpp" "${XBRAID_INSTALL_DIR}/include/braid.hpp"
        COMMENT             ""
    	DEPENDEES           install
        WORKING_DIRECTORY   "${XBRAID_CMAKE_SOURCE_DIR}/.."
        LOG                 0
    )


ELSE()
    ADD_TPL_EMPTY( XBRAID )
ENDIF()

# Add the appropriate fields to FindTPLs.cmake
CONFIGURE_FILE( ${CMAKE_CURRENT_SOURCE_DIR}/cmake/FindXbraid.cmake "${CMAKE_INSTALL_PREFIX}/cmake/FindXbraid.cmake" COPYONLY )
FILE( APPEND "${FIND_TPLS_CMAKE}" "\n# Find XBRAID\n" )
FILE( APPEND "${FIND_TPLS_CMAKE}" "IF ( TPLs_FIND_XBRAID AND NOT TPL_FOUND_XBRAID )\n" )
FILE( APPEND "${FIND_TPLS_CMAKE}" "    INCLUDE( \"${CMAKE_INSTALL_PREFIX}/cmake/FindXbraid.cmake\" )\n" )
FILE( APPEND "${FIND_TPLS_CMAKE}" "    SET( XBRAID_DIR \"${XBRAID_INSTALL_DIR}\" )\n" )
FILE( APPEND "${FIND_TPLS_CMAKE}" "    SET( XBRAID_DIRECTORY \"${XBRAID_INSTALL_DIR}\" )\n" )
FILE( APPEND "${FIND_TPLS_CMAKE}" "    XBRAID_SET_INCLUDES( ${XBRAID_INSTALL_DIR} )\n" )
FILE( APPEND "${FIND_TPLS_CMAKE}" "    XBRAID_SET_LIBRARIES( ${XBRAID_INSTALL_DIR} )\n" )
FILE( APPEND "${FIND_TPLS_CMAKE}" "    SET( TPL_INCLUDE_DIRS $\{TPL_INCLUDE_DIRS} $\{XBRAID_INCLUDE} )\n" )
FILE( APPEND "${FIND_TPLS_CMAKE}" "    SET( TPL_LIBRARIES $\{XBRAID_LIBS} $\{TPL_LIBRARIES} )\n" )
FILE( APPEND "${FIND_TPLS_CMAKE}" "    SET( XBRAID_FOUND TRUE )\n" )
FILE( APPEND "${FIND_TPLS_CMAKE}" "    SET( TPL_FOUND_XBRAID TRUE )\n" )
FILE( APPEND "${FIND_TPLS_CMAKE}" "ENDIF()\n" )
FILE( APPEND "${FIND_TPLS_CMAKE}" "\n" )

# This will configure and build thrust if necessary
# User can configure the source path by specifying THRUST_SRC_DIR,
#    the download path by specifying THRUST_URL, or the installed
#    location by specifying THRUST_INSTALL_DIR


# Intialize download/src/install vars
SET( THRUST_BUILD_DIR "${CMAKE_BINARY_DIR}/THRUST-prefix/src/THRUST-build" )
IF ( THRUST_URL )
    MESSAGE("   THRUST_URL = ${THRUST_URL}")
    SET( THRUST_SRC_DIR "${CMAKE_BINARY_DIR}/THRUST-prefix/src/THRUST-src" )
    SET( THRUST_CMAKE_URL            "${THRUST_URL}"       )
    SET( THRUST_CMAKE_DOWNLOAD_DIR   "${THRUST_SRC_DIR}" )
    SET( THRUST_CMAKE_SOURCE_DIR     "${THRUST_SRC_DIR}" )
    SET( THRUST_CMAKE_INSTALL_DIR "${CMAKE_INSTALL_PREFIX}/thrust" )
    SET( CMAKE_BUILD_THRUST TRUE )
ELSEIF ( THRUST_SRC_DIR )
    VERIFY_PATH("${THRUST_SRC_DIR}")
    MESSAGE("   THRUST_SRC_DIR = ${THRUST_SRC_DIR}")
    SET( THRUST_CMAKE_URL            ""   )
    SET( THRUST_CMAKE_DOWNLOAD_DIR   "" )
    SET( THRUST_CMAKE_SOURCE_DIR     "${THRUST_SRC_DIR}" )
    SET( THRUST_CMAKE_INSTALL_DIR "${CMAKE_INSTALL_PREFIX}/thrust" )
    SET( CMAKE_BUILD_THRUST TRUE )
ELSEIF ( THRUST_INSTALL_DIR )
    SET( THRUST_CMAKE_INSTALL_DIR "${THRUST_INSTALL_DIR}" )
    SET( CMAKE_BUILD_THRUST FALSE )
ELSE()
    MESSAGE(FATAL_ERROR "Please specify THRUST_SRC_DIR, THRUST_URL, or THRUST_INSTALL_DIR")
ENDIF()
SET( THRUST_INSTALL_DIR "${THRUST_CMAKE_INSTALL_DIR}" )
MESSAGE( "   THRUST_INSTALL_DIR = ${THRUST_INSTALL_DIR}" )

IF ( NOT DEFINED THRUST_USE_CUDA )
    SET( THRUST_USE_CUDA ${USE_CUDA} )
ENDIF()
IF ( NOT DEFINED THRUST_USE_OPENMP )
    SET( THRUST_USE_OPENMP ${USE_OPENMP} )
ENDIF()

# Configure thrust
IF ( CMAKE_BUILD_THRUST )
    SET( THRUST_CONFIGURE_OPTIONS -DCMAKE_INSTALL_PREFIX=${THRUST_CMAKE_INSTALL_DIR} )
    SET( THRUST_CONFIGURE_OPTIONS ${THRUST_CONFIGURE_OPTIONS} -DTHRUST_ENABLE_INSTALL_RULES=ON )
    SET( THRUST_CONFIGURE_OPTIONS ${THRUST_CONFIGURE_OPTIONS} -B${THRUST_BUILD_DIR} )
    SET( THRUST_CONFIGURE_OPTIONS ${THRUST_CONFIGURE_OPTIONS} -H${THRUST_CMAKE_SOURCE_DIR} )
    IF ( THRUST_USE_OPENMP )
        MESSAGE( "Enabling OpenMP support for thrust host system" )
        SET( THRUST_CONFIGURE_OPTIONS ${THRUST_CONFIGURE_OPTIONS} -DTHRUST_HOST_SYSTEM=OMP )
    ELSE ()
        SET( THRUST_CONFIGURE_OPTIONS ${THRUST_CONFIGURE_OPTIONS} -DTHRUST_HOST_SYSTEM=CPP )
    ENDIF()

    # If cuda is on use that for the device, else use openmp else set device system to cpp
    IF ( THRUST_USE_CUDA )
        MESSAGE( "Enabling CUDA support for thrust device system" )
        SET( THRUST_CONFIGURE_OPTIONS ${THRUST_CONFIGURE_OPTIONS} -DTHRUST_DEVICE_SYSTEM=CUDA )
    ELSEIF( THRUST_USE_OPENMP )
        MESSAGE( "Enabling OpenMP support for thrust device system" )
        SET( THRUST_CONFIGURE_OPTIONS ${THRUST_CONFIGURE_OPTIONS} -DTHRUST_DEVICE_SYSTEM=OMP )
    ELSE()
        MESSAGE( "Enabling serial support for thrust device system" )
        SET( THRUST_CONFIGURE_OPTIONS ${THRUST_CONFIGURE_OPTIONS} -DTHRUST_DEVICE_SYSTEM=CPP )
    ENDIF()
    MESSAGE("   THRUST configure options: ${THRUST_CONFIGURE_OPTIONS}")
ENDIF()


# Build thrust
IF ( CMAKE_BUILD_THRUST )
    ADD_TPL(
        THRUST
        URL                 "${THRUST_CMAKE_URL}"
        DOWNLOAD_DIR        "${THRUST_CMAKE_DOWNLOAD_DIR}"
        SOURCE_DIR          "${THRUST_CMAKE_SOURCE_DIR}"
        UPDATE_COMMAND      ""
        CMAKE_ARGS          ${THRUST_CONFIGURE_OPTIONS}
        BUILD_COMMAND       cmake --build ${THRUST_BUILD_DIR} --target install -j ${PROCS_INSTALL}
        BUILD_IN_SOURCE     0
        INSTALL_COMMAND     ""
        DEPENDS
        LOG_DOWNLOAD 1   LOG_UPDATE 1   LOG_CONFIGURE 1   LOG_BUILD 1   LOG_TEST 1   LOG_INSTALL 1
    )
ELSE()
    ADD_TPL_EMPTY( THRUST )
ENDIF()

SET( THRUST_CMAKE_CONFIG_DIR "${THRUST_INSTALL_DIR}/${CMAKE_INSTALL_LIBDIR}/cmake/thrust/" )
MESSAGE( "THRUST_CMAKE_CONFIG_DIR ${THRUST_CMAKE_CONFIG_DIR}" )

# Add the appropriate fields to FindTPLs.cmake
FILE( APPEND "${FIND_TPLS_CMAKE}" "\n# Find THRUST\n" )
FILE( APPEND "${FIND_TPLS_CMAKE}" "IF ( TPLs_FIND_THRUST AND NOT TPL_FOUND_THRUST )\n" )
FILE( APPEND "${FIND_TPLS_CMAKE}" "    SET( Thrust_DIR \"${THRUST_CMAKE_CONFIG_DIR}\" )\n" )
FILE( APPEND "${FIND_TPLS_CMAKE}" "    FIND_PACKAGE( Thrust REQUIRED CONFIG )\n" )
FILE( APPEND "${FIND_TPLS_CMAKE}" "    IF (USE_CUDA)\n" )
FILE( APPEND "${FIND_TPLS_CMAKE}" "        thrust_create_target(Thrust)\n" )
FILE( APPEND "${FIND_TPLS_CMAKE}" "    ELSE()\n" )
FILE( APPEND "${FIND_TPLS_CMAKE}" "        thrust_create_target(Thrust DEVICE OMP)\n" )
FILE( APPEND "${FIND_TPLS_CMAKE}" "    ENDIF()\n" )
FILE( APPEND "${FIND_TPLS_CMAKE}" "    get_target_property(THRUST_INCLUDES Thrust INCLUDE_DIRECTORIES)\n" )
FILE( APPEND "${FIND_TPLS_CMAKE}" "    get_target_property(THRUST_LIBS Thrust LINK_LIBRARIES)\n" )
FILE( APPEND "${FIND_TPLS_CMAKE}" "    SET( TPL_INCLUDE_DIRS $\{TPL_INCLUDE_DIRS} $\{THRUST_INCLUDES} )\n" )
FILE( APPEND "${FIND_TPLS_CMAKE}" "    SET( TPL_LIBRARIES $\{THRUST_LIBS} $\{TPL_LIBRARIES} )\n" )
FILE( APPEND "${FIND_TPLS_CMAKE}" "    SET( THRUST_FOUND TRUE )\n" )
FILE( APPEND "${FIND_TPLS_CMAKE}" "    SET( TPL_FOUND_THRUST TRUE )\n" )
FILE( APPEND "${FIND_TPLS_CMAKE}" "ENDIF()\n" )
FILE( APPEND "${FIND_TPLS_CMAKE}" "\n" )

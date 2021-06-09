# This will configure and build silo
# User can configure the source path by specifying SILO_SRC_DIR,
#    the download path by specifying SILO_URL, or the installed 
#    location by specifying SILO_INSTALL_DIR


# Intialize download/src/install vars
SET( SILO_BUILD_DIR "${CMAKE_BINARY_DIR}/SILO-prefix/src/SILO-build" )
IF ( SILO_URL ) 
    MESSAGE("   SILO_URL = ${SILO_URL}")
    SET( SILO_SRC_DIR "${CMAKE_BINARY_DIR}/SILO-prefix/src/SILO-src" )
    SET( SILO_CMAKE_URL            "${SILO_URL}"        )
    SET( SILO_CMAKE_DOWNLOAD_DIR   "${SILO_SRC_DIR}"    )
    SET( SILO_CMAKE_SOURCE_DIR     "${SILO_SRC_DIR}"    )
    SET( SILO_CMAKE_INSTALL_DIR "${CMAKE_INSTALL_PREFIX}/silo" )
    SET( CMAKE_BUILD_SILO TRUE )
ELSEIF ( SILO_SRC_DIR )
    VERIFY_PATH("${SILO_SRC_DIR}")
    MESSAGE("   SILO_SRC_DIR = ${SILO_SRC_DIR}")
    SET( SILO_CMAKE_URL            ""                   )
    SET( SILO_CMAKE_DOWNLOAD_DIR   ""                   )
    SET( SILO_CMAKE_SOURCE_DIR     "${SILO_SRC_DIR}"    )
    SET( SILO_CMAKE_INSTALL_DIR "${CMAKE_INSTALL_PREFIX}/silo" )
    SET( CMAKE_BUILD_SILO TRUE )
ELSEIF ( SILO_INSTALL_DIR ) 
    SET( SILO_CMAKE_INSTALL_DIR "${SILO_INSTALL_DIR}" )
    SET( CMAKE_BUILD_SILO FALSE )
ELSE()
    MESSAGE(FATAL_ERROR "Please specify SILO_SRC_DIR, SILO_URL, or SILO_INSTALL_DIR")
ENDIF()
SET( SILO_INSTALL_DIR "${SILO_CMAKE_INSTALL_DIR}" )
MESSAGE( "   SILO_INSTALL_DIR = ${SILO_INSTALL_DIR}" )


# Configure silo
IF ( CMAKE_BUILD_SILO )
    EXECUTE_PROCESS( COMMAND ${CMAKE_COMMAND} -E make_directory "${SILO_INSTALL_DIR}/include" )
    EXECUTE_PROCESS( COMMAND ${CMAKE_COMMAND} -E make_directory "${SILO_INSTALL_DIR}/lib" )
    SET( CONFIGURE_OPTIONS )
    SET( CONFIGURE_OPTIONS ${CONFIGURE_OPTIONS} --prefix=${CMAKE_INSTALL_PREFIX}/silo  )
    SET( CONFIGURE_OPTIONS ${CONFIGURE_OPTIONS} --with-zlib=${ZLIB_INCLUDE_DIR},${ZLIB_LIB_DIR} )
    SET( CONFIGURE_OPTIONS ${CONFIGURE_OPTIONS} --with-hdf5=${HDF5_INSTALL_DIR}/include,${HDF5_INSTALL_DIR}/lib,-ldl )
    IF ( MPI_C_INCLUDE_PATH )
        SET( CONFIGURE_OPTIONS ${CONFIGURE_OPTIONS} --includedir=${SILO_INSTALL_DIR}/include,${MPI_C_INCLUDE_PATH} )
    ELSE()
        SET( CONFIGURE_OPTIONS ${CONFIGURE_OPTIONS} --includedir=${SILO_INSTALL_DIR}/include )
    ENDIF()
    SET( CONFIGURE_OPTIONS ${CONFIGURE_OPTIONS} --libdir=${SILO_INSTALL_DIR}/lib )
    SET( CONFIGURE_OPTIONS ${CONFIGURE_OPTIONS} --disable-silex )
    SET( CONFIGURE_OPTIONS ${CONFIGURE_OPTIONS} --disable-browser )
    SET( CONFIGURE_OPTIONS ${CONFIGURE_OPTIONS} --with-szlib=no )
    IF ( ${CMAKE_BUILD_TYPE} STREQUAL "Debug" )
        SET(CONFIGURE_OPTIONS ${CONFIGURE_OPTIONS} --disable-optimization )
    ELSEIF ( ${CMAKE_BUILD_TYPE} STREQUAL "Release" )
        SET(CONFIGURE_OPTIONS ${CONFIGURE_OPTIONS} --enable-optimization )
    ELSE()
        MESSAGE ( FATAL_ERROR "Unknown CMAKE_BUILD_TYPE=${CMAKE_BUILD_TYPE}" )
    ENDIF()
    IF ( ENABLE_SHARED )
        SET( CONFIGURE_OPTIONS ${CONFIGURE_OPTIONS} --enable-shared )
    ELSE()
        SET( CONFIGURE_OPTIONS ${CONFIGURE_OPTIONS} --disable-shared )
    ENDIF()
    IF ( ENABLE_STATIC )
        SET( CONFIGURE_OPTIONS ${CONFIGURE_OPTIONS} --enable-static )
    ELSE()
        SET( CONFIGURE_OPTIONS ${CONFIGURE_OPTIONS} --disable-static )
    ENDIF()
    IF ( BUILD_TYPE )
        SET( CONFIGURE_OPTIONS ${CONFIGURE_OPTIONS} --build=${BUILD_TYPE} )
    ENDIF()
ENDIF()


# Build silo
ADD_TPL(
    SILO
    URL                 "${SILO_CMAKE_URL}"
    DOWNLOAD_DIR        "${SILO_CMAKE_DOWNLOAD_DIR}"
    SOURCE_DIR          "${SILO_CMAKE_SOURCE_DIR}"
    UPDATE_COMMAND      ""
    CONFIGURE_COMMAND   "${SILO_CMAKE_SOURCE_DIR}/configure" ${CONFIGURE_OPTIONS} ${ENV_VARS}
    BUILD_COMMAND       make install -j ${PROCS_INSTALL} VERBOSE=1
    BUILD_IN_SOURCE     0
    INSTALL_COMMAND     ""
    DEPENDS             ZLIB HDF5
    LOG_DOWNLOAD 1   LOG_UPDATE 1   LOG_CONFIGURE 1   LOG_BUILD 1   LOG_TEST 1   LOG_INSTALL 1
)


# Add the appropriate fields to FindTPLs.cmake
FILE( APPEND "${FIND_TPLS_CMAKE}" "\n# Find SILO\n" )
FILE( APPEND "${FIND_TPLS_CMAKE}" "IF ( TPLs_FIND_SILO AND NOT TPL_FOUND_SILO )\n" )
FILE( APPEND "${FIND_TPLS_CMAKE}" "    SET( SILO_DIR \"${SILO_INSTALL_DIR}\" )\n" )
FILE( APPEND "${FIND_TPLS_CMAKE}" "    SET( SILO_DIRECTORY \"${SILO_INSTALL_DIR}\" )\n" )
FILE( APPEND "${FIND_TPLS_CMAKE}" "    SET( SILO_INCLUDE ${SILO_INSTALL_DIR}/include )\n" )
FILE( APPEND "${FIND_TPLS_CMAKE}" "    FIND_LIBRARY ( SILO_LIB  NAMES siloh5  PATHS $\{SILO_DIRECTORY}/lib  NO_DEFAULT_PATH )\n" )
FILE( APPEND "${FIND_TPLS_CMAKE}" "    SET( SILO_LIBS $\{SILO_LIB} )\n" )
FILE( APPEND "${FIND_TPLS_CMAKE}" "    SET( TPL_INCLUDE_DIRS $\{TPL_INCLUDE_DIRS} $\{SILO_INCLUDE} )\n" )
FILE( APPEND "${FIND_TPLS_CMAKE}" "    SET( TPL_LIBRARIES $\{SILO_LIB} $\{TPL_LIBRARIES} )\n" )
FILE( APPEND "${FIND_TPLS_CMAKE}" "    SET( SILO_FOUND TRUE )\n" )
FILE( APPEND "${FIND_TPLS_CMAKE}" "    SET( TPL_FOUND_SILO TRUE )\n" )
FILE( APPEND "${FIND_TPLS_CMAKE}" "ENDIF()\n" )
FILE( APPEND "${FIND_TPLS_CMAKE}" "\n" )



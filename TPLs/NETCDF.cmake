# This will configure and build netcdf
# User can configure the source path by specifying NETCDF_SRC_DIR,
#    the download path by specifying NETCDF_URL, or the installed 
#    location by specifying NETCDF_INSTALL_DIR


# Intialize download/src/install vars
SET( NETCDF_BUILD_DIR "${CMAKE_BINARY_DIR}/NETCDF-prefix/src/NETCDF-build" )
IF ( NETCDF_URL ) 
    MESSAGE("   NETCDF_URL = ${NETCDF_URL}")
    SET( NETCDF_SRC_DIR "${CMAKE_BINARY_DIR}/NETCDF-prefix/src/NETCDF-src" )
    SET( NETCDF_CMAKE_URL            "${NETCDF_URL}"     )
    SET( NETCDF_CMAKE_DOWNLOAD_DIR   "${NETCDF_SRC_DIR}" )
    SET( NETCDF_CMAKE_SOURCE_DIR     "${NETCDF_SRC_DIR}" )
    SET( NETCDF_CMAKE_INSTALL_DIR "${CMAKE_INSTALL_PREFIX}/netcdf" )
    SET( CMAKE_BUILD_NETCDF TRUE )
ELSEIF ( NETCDF_SRC_DIR )
    VERIFY_PATH("${NETCDF_SRC_DIR}")
    MESSAGE("   NETCDF_SRC_DIR = ${NETCDF_SRC_DIR}")
    SET( NETCDF_CMAKE_URL            ""                  )
    SET( NETCDF_CMAKE_DOWNLOAD_DIR   ""                  )
    SET( NETCDF_CMAKE_SOURCE_DIR     "${NETCDF_SRC_DIR}" )
    SET( NETCDF_CMAKE_INSTALL_DIR "${CMAKE_INSTALL_PREFIX}/netcdf" )
    SET( CMAKE_BUILD_NETCDF TRUE )
ELSEIF ( NETCDF_INSTALL_DIR ) 
    SET( NETCDF_CMAKE_INSTALL_DIR "${NETCDF_INSTALL_DIR}" )
    SET( CMAKE_BUILD_NETCDF FALSE )
ELSE()
    MESSAGE(FATAL_ERROR "Please specify NETCDF_SRC_DIR, NETCDF_URL, or NETCDF_INSTALL_DIR")
ENDIF()
SET( NETCDF_INSTALL_DIR "${NETCDF_CMAKE_INSTALL_DIR}" )
MESSAGE( "   NETCDF_INSTALL_DIR = ${NETCDF_INSTALL_DIR}" )


# Configure netcdf
IF ( CMAKE_BUILD_NETCDF )
    SET( CONFIGURE_OPTIONS )
    SET( CONFIGURE_OPTIONS ${CONFIGURE_OPTIONS} --prefix=${NETCDF_INSTALL_DIR} )
    SET( CONFIGURE_OPTIONS ${CONFIGURE_OPTIONS} --with-hdf5=${HDF5_INSTALL_DIR} )
    SET( CONFIGURE_OPTIONS ${CONFIGURE_OPTIONS} --disable-examples --enable-netcdf4 --disable-dap )
    SET( NETCDF_CFLAGS "${CMAKE_C_FLAGS} -I${CMAKE_INSTALL_PREFIX}/hdf5/include -I${CMAKE_INSTALL_PREFIX}/netcdf/include" )
    SET( NETCDF_LDFLAGS "${LDFLAGS} -L/${CMAKE_INSTALL_PREFIX}/hdf5/lib -L/${CMAKE_INSTALL_PREFIX}/netcdf/lib" )
    SET( NETCDF_LIBS -ldl )
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
ENDIF()


# Build netcdf
IF ( CMAKE_BUILD_NETCDF )
    EXTERNALPROJECT_ADD(
        NETCDF
        URL                 "${NETCDF_CMAKE_URL}"
        DOWNLOAD_DIR        "${NETCDF_CMAKE_DOWNLOAD_DIR}"
        SOURCE_DIR          "${NETCDF_CMAKE_SOURCE_DIR}"

        UPDATE_COMMAND      ""
        CONFIGURE_COMMAND   ${NETCDF_SRC_DIR}/configure ${CONFIGURE_OPTIONS} 
                            CC=${CMAKE_C_COMPILER} CFLAGS=${NETCDF_CFLAGS} LDFLAGS=${NETCDF_LDFLAGS} LIBS=${NETCDF_LIBS}
        BUILD_COMMAND       make install -j ${PROCS_INSTALL} VERBOSE=1
        BUILD_IN_SOURCE     0
        INSTALL_COMMAND     ""
        DEPENDS             HDF5
        LOG_DOWNLOAD 1   LOG_UPDATE 1   LOG_CONFIGURE 1   LOG_BUILD 1   LOG_TEST 1   LOG_INSTALL 1
    )
    ADD_TPL_SAVE_LOGS( NETCDF )
    ADD_TPL_CLEAN( NETCDF )
ELSE()
    ADD_TPL_EMPTY( NETCDF )
ENDIF()


# Add the appropriate fields to FindTPLs.cmake
FILE( APPEND "${FIND_TPLS_CMAKE}" "\n# Find NETCDF\n" )
FILE( APPEND "${FIND_TPLS_CMAKE}" "IF ( TPLs_FIND_NETCDF AND NOT TPL_FOUND_NETCDF )\n" )
FILE( APPEND "${FIND_TPLS_CMAKE}" "    SET( NETCDF_DIR \"${NETCDF_INSTALL_DIR}\" )\n" )
FILE( APPEND "${FIND_TPLS_CMAKE}" "    SET( NETCDF_DIRECTORY \"${NETCDF_INSTALL_DIR}\" )\n" )
FILE( APPEND "${FIND_TPLS_CMAKE}" "    SET( NETCDF_INCLUDE ${NETCDF_INSTALL_DIR}/include )\n" )
FILE( APPEND "${FIND_TPLS_CMAKE}" "    FIND_LIBRARY( NETCDF_NETCDF_LIB    NAMES netcdf    PATHS $\{NETCDF_DIRECTORY}/lib  NO_DEFAULT_PATH )\n" )
FILE( APPEND "${FIND_TPLS_CMAKE}" "    FIND_LIBRARY( NETCDF_HDF5_LIB      NAMES hdf5      PATHS ${HDF5_INSTALL_DIR}/lib  NO_DEFAULT_PATH )\n" )
FILE( APPEND "${FIND_TPLS_CMAKE}" "    FIND_LIBRARY( NETCDF_HL_LIB        NAMES hdf5 _hl  PATHS ${HDF5_INSTALL_DIR}/lib  NO_DEFAULT_PATH )\n" )
FILE( APPEND "${FIND_TPLS_CMAKE}" "    IF ( (NOT NETCDF_NETCDF_LIB) OR (NOT NETCDF_HDF5_LIB) OR (NOT NETCDF_HL_LIB)  )\n" )
FILE( APPEND "${FIND_TPLS_CMAKE}" "        MESSAGE( \"$\{NETCDF_NETCDF_LIB}\" )\n" )
FILE( APPEND "${FIND_TPLS_CMAKE}" "        MESSAGE( \"$\{NETCDF_HDF5_LIB}\" )\n" )
FILE( APPEND "${FIND_TPLS_CMAKE}" "        MESSAGE( \"$\{NETCDF_HL_LIB}\" )\n" )
FILE( APPEND "${FIND_TPLS_CMAKE}" "    ENDIF()\n" )
FILE( APPEND "${FIND_TPLS_CMAKE}" "    SET( NETCDF_LIBS $\{NETCDF_NETCDF_LIB} $\{NETCDF_HDF5_LIB} $\{NETCDF_HL_LIB} $\{NETCDF_NETCDF_LIB} $\{NETCDF_HDF5_LIB} $\{NETCDF_HL_LIB} )\n" )
FILE( APPEND "${FIND_TPLS_CMAKE}" "    SET( TPL_INCLUDE_DIRS $\{TPL_INCLUDE_DIRS} $\{NETCDF_INCLUDE} )\n" )
FILE( APPEND "${FIND_TPLS_CMAKE}" "    SET( TPL_LIBRARIES $\{NETCDF_LIB} $\{TPL_LIBRARIES} )\n" )
FILE( APPEND "${FIND_TPLS_CMAKE}" "    SET( NETCDF_FOUND TRUE )\n" )
FILE( APPEND "${FIND_TPLS_CMAKE}" "    SET( TPL_FOUND_NETCDF TRUE )\n" )
FILE( APPEND "${FIND_TPLS_CMAKE}" "ENDIF()\n" )
FILE( APPEND "${FIND_TPLS_CMAKE}" "\n" )



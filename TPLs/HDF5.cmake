# This will configure and build hdf5
# User can configure the source path by specifying HDF5_SRC_DIR
#    the download path by specifying HDF5_URL, or the installed 
#    location by specifying HDF5_INSTALL_DIR


# Intialize download/src/install vars
SET( HDF5_BUILD_DIR "${CMAKE_BINARY_DIR}/HDF5-prefix/src/HDF5-build" )
IF ( HDF5_URL ) 
    MESSAGE_TPL("   HDF5_URL = ${HDF5_URL}")
    SET( HDF5_CMAKE_URL            "${HDF5_URL}"       )
    SET( HDF5_CMAKE_DOWNLOAD_DIR   "${HDF5_BUILD_DIR}" )
    SET( HDF5_CMAKE_SOURCE_DIR     "${HDF5_BUILD_DIR}" )
    SET( HDF5_CMAKE_INSTALL_DIR "${CMAKE_INSTALL_PREFIX}/hdf5" )
    SET( CMAKE_BUILD_HDF5 TRUE )
ELSEIF ( HDF5_SRC_DIR )
    MESSAGE_TPL("   HDF5_SRC_DIR = ${HDF5_SRC_DIR}")
    SET( HDF5_CMAKE_URL            "${HDF5_SRC_DIR}"   )
    SET( HDF5_CMAKE_DOWNLOAD_DIR   "${HDF5_BUILD_DIR}" )
    SET( HDF5_CMAKE_SOURCE_DIR     "${HDF5_BUILD_DIR}" )
    SET( HDF5_CMAKE_INSTALL_DIR "${CMAKE_INSTALL_PREFIX}/hdf5" )
    SET( CMAKE_BUILD_HDF5 TRUE )
ELSEIF ( HDF5_INSTALL_DIR ) 
    SET( HDF5_CMAKE_INSTALL_DIR "${HDF5_INSTALL_DIR}" )
    SET( CMAKE_BUILD_HDF5 FALSE )
ELSE()
    MESSAGE(FATAL_ERROR "Please specify HDF5_SRC_DIR")
ENDIF()
FILE( MAKE_DIRECTORY "${HDF5_CMAKE_INSTALL_DIR}" )
SET( HDF5_INSTALL_DIR "${HDF5_CMAKE_INSTALL_DIR}" )
MESSAGE_TPL( "   HDF5_INSTALL_DIR = ${HDF5_INSTALL_DIR}" )
FILE( APPEND "${CMAKE_INSTALL_PREFIX}/TPLs.cmake" "SET(HDF5_INSTALL_DIR \"${HDF5_INSTALL_DIR}\")\n" )

# Configure hdf5
IF ( CMAKE_BUILD_HDF5 )
    EXECUTE_PROCESS( COMMAND ${CMAKE_COMMAND} -E make_directory "${HDF5_INSTALL_DIR}/include" )
    EXECUTE_PROCESS( COMMAND ${CMAKE_COMMAND} -E make_directory "${HDF5_INSTALL_DIR}/lib" )
    SET( CONFIGURE_OPTIONS )
    SET( HDF5_COMPONENTS "C" )
    IF ( HDF5_ENABLE_CXX )
        SET( HDF5_COMPONENTS "${HDF5_COMPONENTS} CXX" )
        SET( CONFIGURE_OPTIONS ${CONFIGURE_OPTIONS} --enable-cxx )
    ELSE()
        SET( CONFIGURE_OPTIONS ${CONFIGURE_OPTIONS} --disable-cxx )
    ENDIF()
    IF ( HDF5_ENABLE_UNSUPPORTED )
        SET( CONFIGURE_OPTIONS ${CONFIGURE_OPTIONS} --enable-unsupported )
    ENDIF()
    IF ( NOT USE_MPI )
        SET( CONFIGURE_OPTIONS ${CONFIGURE_OPTIONS} --disable-parallel )
    ENDIF()
    IF ( NOT DEFINED HDF5_ENABLE_FORTRAN )
        SET( HDF5_ENABLE_FORTRAN 1 )
    ENDIF()
    IF ( HDF5_ENABLE_FORTRAN )
        SET( HDF5_COMPONENTS "${HDF5_COMPONENTS} Fortran" )
        SET( CONFIGURE_OPTIONS ${CONFIGURE_OPTIONS} --enable-fortran )
    ENDIF()
    SET( CONFIGURE_OPTIONS ${CONFIGURE_OPTIONS} --with-zlib='${ZLIB_INCLUDE_DIR}','${ZLIB_LIB_DIR}' )
    SET( CONFIGURE_OPTIONS ${CONFIGURE_OPTIONS} --includedir=${HDF5_INSTALL_DIR}/include )
    SET( CONFIGURE_OPTIONS ${CONFIGURE_OPTIONS} --libdir=${HDF5_INSTALL_DIR}/lib )
    IF ( ${CMAKE_BUILD_TYPE} STREQUAL "Debug" )
        SET(CONFIGURE_OPTIONS ${CONFIGURE_OPTIONS} --disable-production --enable-debug )
    ELSEIF ( ${CMAKE_BUILD_TYPE} STREQUAL "Release" )
        SET(CONFIGURE_OPTIONS ${CONFIGURE_OPTIONS} --enable-production --disable-debug )
    ELSE()
        MESSAGE ( FATAL_ERROR "Unknown CMAKE_BUILD_TYPE=${CMAKE_BUILD_TYPE}" )
    ENDIF()
    IF ( ENABLE_SHARED )
        SET( CONFIGURE_OPTIONS ${CONFIGURE_OPTIONS} --enable-shared )
        IF ( "${CMAKE_SYSTEM_NAME}" STREQUAL "Darwin" AND HDF5_ENABLE_FORTRAN )
            MESSAGE( WARNING "Shared fortran libraries are not supported by HDF5 on MAC and will likely fail to configure")
        ENDIF()
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
ELSE()
    SET( HDF5_COMPONENTS "C" )
    FIND_LIBRARY( HDF5_CXX_LIBRARY  NAMES hdf5_cxx PATHS "${HDF5_INSTALL_DIR}/lib"  NO_DEFAULT_PATH )
    FIND_LIBRARY( HDF5_Fortran_LIBRARY  NAMES hdf5_fortran PATHS "${HDF5_INSTALL_DIR}/lib"  NO_DEFAULT_PATH )
    IF ( HDF5_CXX_LIBRARY )
        SET( HDF5_COMPONENTS "${HDF5_COMPONENTS} CXX" )
    ENDIF()
    IF ( HDF5_Fortran_LIBRARY )
        SET( HDF5_COMPONENTS "${HDF5_COMPONENTS} Fortran" )
    ENDIF()
ENDIF()


# Build hdf5
IF ( CMAKE_BUILD_HDF5 )
    EXTERNALPROJECT_ADD(
        HDF5
        URL                 "${HDF5_CMAKE_URL}"
        DOWNLOAD_DIR        "${HDF5_CMAKE_DOWNLOAD_DIR}"
        SOURCE_DIR          "${HDF5_CMAKE_SOURCE_DIR}"
        UPDATE_COMMAND      ""
        CONFIGURE_COMMAND   ${HDF5_CMAKE_SOURCE_DIR}/configure ${CONFIGURE_OPTIONS} ${ENV_VARS}
        BUILD_COMMAND       make install -j ${PROCS_INSTALL} VERBOSE=1
        BUILD_IN_SOURCE     0
        INSTALL_COMMAND     ""
        DEPENDS             ZLIB
        LOG_DOWNLOAD 1   LOG_UPDATE 1   LOG_CONFIGURE 1   LOG_BUILD 1   LOG_TEST 1   LOG_INSTALL 1
    )
    ADD_TPL_SAVE_LOGS( HDF5 )
    ADD_TPL_CLEAN( HDF5 )
ELSE()
    ADD_TPL_EMPTY( HDF5 )
ENDIF()


# Add the appropriate fields to FindTPLs.cmake
FILE( APPEND "${FIND_TPLS_CMAKE}" "\n# Find HDF5\n" )
FILE( APPEND "${FIND_TPLS_CMAKE}" "IF ( TPLs_FIND_HDF5 AND NOT TPL_FOUND_HDF5 )\n" )
FILE( APPEND "${FIND_TPLS_CMAKE}" "    SET( ENV{HDF5_ROOT} \"${HDF5_INSTALL_DIR}\" )\n" )
FILE( APPEND "${FIND_TPLS_CMAKE}" "    FIND_PACKAGE( HDF5 COMPONENTS ${HDF5_COMPONENTS} )\n" )
FILE( APPEND "${FIND_TPLS_CMAKE}" "    SET( TPL_INCLUDE_DIRS $\{TPL_INCLUDE_DIRS} $\{HDF5_INCLUDE_DIRS} )\n" )
FILE( APPEND "${FIND_TPLS_CMAKE}" "    SET( TPL_LIBRARIES $\{HDF5_LIBRARIES} $\{TPL_LIBRARIES} )\n" )
FILE( APPEND "${FIND_TPLS_CMAKE}" "    SET( TPL_FOUND_HDF5 $\{HDF5_FOUND} )\n" )
FILE( APPEND "${FIND_TPLS_CMAKE}" "ENDIF()\n" )
FILE( APPEND "${FIND_TPLS_CMAKE}" "\n" )

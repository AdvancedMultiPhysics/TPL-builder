# This will configure and build hdf5
# User can configure the source path by speficfying HDF5_SRC_DIR
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
    IF ( HDF5_ENABLE_CXX )
        SET( CONFIGURE_OPTIONS ${CONFIGURE_OPTIONS} --enable-cxx )
    ELSE()
        SET( CONFIGURE_OPTIONS ${CONFIGURE_OPTIONS} --disable-cxx )
    ENDIF()
    IF ( HDF5_ENABLE_UNSUPPORTED )
        SET( CONFIGURE_OPTIONS ${CONFIGURE_OPTIONS} --enable-unsupported )
    ENDIF()
    #SET( CONFIGURE_OPTIONS ${CONFIGURE_OPTIONS} --disable-parallel )
    SET( CONFIGURE_OPTIONS ${CONFIGURE_OPTIONS} --enable-fortran )
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
        IF ( "${CMAKE_SYSTEM_NAME}" STREQUAL "Darwin" )
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



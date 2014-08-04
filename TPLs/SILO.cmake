# This will configure and build silo
# User can configure the source path by speficfying SILO_SRC_DIR,
#    the download path by specifying SILO_URL, or the installed 
#    location by specifying SILO_INSTALL_DIR


# Intialize download/src/install vars
SET( SILO_BUILD_DIR "${CMAKE_BINARY_DIR}/SILO-prefix/src/SILO-build" )
IF ( SILO_URL ) 
    MESSAGE_TPL("   SILO_URL = ${SILO_URL}")
    SET( SILO_SRC_DIR "${CMAKE_BINARY_DIR}/SILO-prefix/src/SILO-src" )
    SET( SILO_CMAKE_URL            "${SILO_URL}"        )
    SET( SILO_CMAKE_DOWNLOAD_DIR   "${SILO_SRC_DIR}"    )
    SET( SILO_CMAKE_SOURCE_DIR     "${SILO_SRC_DIR}"    )
    SET( SILO_CMAKE_INSTALL_DIR "${CMAKE_INSTALL_PREFIX}/silo" )
    SET( CMAKE_BUILD_SILO TRUE )
ELSEIF ( SILO_SRC_DIR )
    VERIFY_PATH("${SILO_SRC_DIR}")
    MESSAGE_TPL("   SILO_SRC_DIR = ${SILO_SRC_DIR}")
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
MESSAGE_TPL( "   SILO_INSTALL_DIR = ${SILO_INSTALL_DIR}" )
FILE( APPEND "${CMAKE_INSTALL_PREFIX}/TPLs.cmake" "SET(SILO_INSTALL_DIR \"${SILO_INSTALL_DIR}\")\n" )


# Configure silo
IF ( CMAKE_BUILD_SILO )
    SET( CONFIGURE_OPTIONS )
    SET( CONFIGURE_OPTIONS ${CONFIGURE_OPTIONS} --prefix=${CMAKE_INSTALL_PREFIX}/silo  )
    SET( CONFIGURE_OPTIONS ${CONFIGURE_OPTIONS} --with-hdf5=${HDF5_INSTALL_DIR}/include,${HDF5_INSTALL_DIR}/lib )
    SET( CONFIGURE_OPTIONS ${CONFIGURE_OPTIONS} --with-Qt=no --disable-silex --disable-browser )
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
ENDIF()


# Build silo
IF ( CMAKE_BUILD_SILO )
    EXTERNALPROJECT_ADD(
        SILO
        URL                 "${SILO_CMAKE_URL}"
        DOWNLOAD_DIR        "${SILO_CMAKE_DOWNLOAD_DIR}"
        SOURCE_DIR          "${SILO_CMAKE_SOURCE_DIR}"
        UPDATE_COMMAND      ""
        CONFIGURE_COMMAND   "${SILO_CMAKE_SOURCE_DIR}/configure" ${CONFIGURE_OPTIONS} ${ENV_VARS} LIBS=-ldl
        BUILD_COMMAND       make install -j ${PROCS_INSTALL} VERBOSE=1
        BUILD_IN_SOURCE     0
        INSTALL_COMMAND     ""
        DEPENDS             HDF5
        LOG_DOWNLOAD 1   LOG_UPDATE 1   LOG_CONFIGURE 1   LOG_BUILD 1   LOG_TEST 1   LOG_INSTALL 1
    )
    ADD_TPL_SAVE_LOGS( SILO )
    ADD_TPL_CLEAN( SILO )
ELSE()
    ADD_TPL_EMPTY( SILO )
ENDIF()



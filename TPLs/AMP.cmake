# This will configure and build amp
# User can configure the source path by speficfying AMP_SRC_DIR,
#    the download path by specifying AMP_URL, or the installed 
#    location by specifying AMP_INSTALL_DIR


# Intialize download/src/install vars
SET( AMP_BUILD_DIR "${CMAKE_BINARY_DIR}/AMP-prefix/src/AMP-build" )
IF ( AMP_URL ) 
    MESSAGE_TPL("   AMP_URL = ${AMP_URL}")
    SET( AMP_SRC_DIR "${CMAKE_BINARY_DIR}/AMP-prefix/src/AMP-src" )
    SET( AMP_CMAKE_URL            "${AMP_URL}"     )
    SET( AMP_CMAKE_DOWNLOAD_DIR   "${AMP_SRC_DIR}" )
    SET( AMP_CMAKE_SOURCE_DIR     "${AMP_SRC_DIR}" )
    SET( AMP_CMAKE_INSTALL_DIR "${CMAKE_INSTALL_PREFIX}/amp" )
    SET( CMAKE_BUILD_AMP TRUE )
ELSEIF ( AMP_SRC_DIR )
    VERIFY_PATH("${AMP_SRC_DIR}")
    MESSAGE_TPL("   AMP_SRC_DIR = ${AMP_SRC_DIR}")
    SET( AMP_CMAKE_URL            ""                  )
    SET( AMP_CMAKE_DOWNLOAD_DIR   ""                  )
    SET( AMP_CMAKE_SOURCE_DIR     "${AMP_SRC_DIR}" )
    SET( AMP_CMAKE_INSTALL_DIR "${CMAKE_INSTALL_PREFIX}/amp" )
    SET( CMAKE_BUILD_AMP TRUE )
ELSEIF ( AMP_INSTALL_DIR ) 
    SET( AMP_CMAKE_INSTALL_DIR "${AMP_INSTALL_DIR}" )
    SET( CMAKE_BUILD_AMP FALSE )
ELSE()
    MESSAGE(FATAL_ERROR "Please specify AMP_SRC_DIR, AMP_URL, or AMP_INSTALL_DIR")
ENDIF()
SET( AMP_INSTALL_DIR "${AMP_CMAKE_INSTALL_DIR}" )
MESSAGE_TPL( "   AMP_INSTALL_DIR = ${AMP_INSTALL_DIR}" )
FILE( APPEND "${CMAKE_INSTALL_PREFIX}/TPLs.cmake" "SET(AMP_INSTALL_DIR \"${AMP_INSTALL_DIR}\")\n" )


# Configure amp
IF ( CMAKE_BUILD_AMP )
    SET( CONFIGURE_OPTIONS "${CMAKE_ARGS}" )
    SET( CONFIGURE_OPTIONS "${CONFIGURE_OPTIONS};-DAMP_INSTALL_DIR=${CMAKE_INSTALL_PREFIX}/amp" )
    SET( CONFIGURE_OPTIONS "${CONFIGURE_OPTIONS};-DCMAKE_INSTALL_PREFIX=${CMAKE_INSTALL_PREFIX}/amp" )
    SET( CONFIGURE_OPTIONS "${CONFIGURE_OPTIONS};-DTPL_DIRECTORY=${CMAKE_INSTALL_PREFIX}" )
    SET( CONFIGURE_OPTIONS "${CONFIGURE_OPTIONS};-DDISABLE_GXX_DEBUG:BOOL=true" )
    SET( CONFIGURE_OPTIONS "${CONFIGURE_OPTIONS};-DAMP_DATA:PATH=${AMP_DATA}" )
    IF ( ${CMAKE_BUILD_TYPE} STREQUAL "Debug" )
        SET( CONFIGURE_OPTIONS "${CONFIGURE_OPTIONS};-DCOMPILE_MODE=debug" )
    ELSEIF ( ${CMAKE_BUILD_TYPE} STREQUAL "Release" )
        SET( CONFIGURE_OPTIONS "${CONFIGURE_OPTIONS};-DCOMPILE_MODE=optimized" )
    ELSE()
        MESSAGE ( FATAL_ERROR "Unknown CMAKE_BUILD_TYPE=${CMAKE_BUILD_TYPE}" )
    ENDIF()
    STRING(REGEX REPLACE ";AMP.*" "" AMP_DEPENDS "${TPL_LIST}" )
    CHECK_ENABLE_FLAG( AMP_DOCS 1 )
ENDIF()


# Configure amp
IF ( CMAKE_BUILD_AMP )
    EXTERNALPROJECT_ADD(
        AMP
        URL                 "${AMP_CMAKE_URL}"
        DOWNLOAD_DIR        "${AMP_CMAKE_DOWNLOAD_DIR}"
        SOURCE_DIR          "${AMP_CMAKE_SOURCE_DIR}"
        UPDATE_COMMAND      ""
        BUILD_IN_SOURCE     0
        INSTALL_DIR         ${CMAKE_INSTALL_PREFIX}/amp
        CMAKE_ARGS          "${CONFIGURE_OPTIONS}"
        BUILD_COMMAND       make install -j ${PROCS_INSTALL}  VERBOSE=1
        DEPENDS             ${AMP_DEPENDS}
        LOG_DOWNLOAD 1   LOG_UPDATE 1   LOG_CONFIGURE 1   LOG_BUILD 1   LOG_TEST 1   LOG_INSTALL 1
    )
    IF ( AMP_DOCS )
        EXTERNALPROJECT_ADD_STEP(
            AMP
            build-docs
            COMMENT             "Compiling documentation"
            COMMAND             make doc -j ${PROCS_INSTALL}
            COMMENT             ""
            DEPENDEES           install
            DEPENDERS           
            WORKING_DIRECTORY   "${AMP_BUILD_DIR}"
            LOG                 1
        )

    ENDIF()
    ADD_TPL_SAVE_LOGS( AMP )
    ADD_TPL_CLEAN( AMP )
ELSE()
    ADD_TPL_EMPTY( AMP )
ENDIF()



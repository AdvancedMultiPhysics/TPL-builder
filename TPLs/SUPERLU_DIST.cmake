# This will configure and build superlu
# User can configure the source path by specifying SUPERLU_DIST_SRC_DIR,
#    the download path by specifying SUPERLU_DIST_URL, or the installed 
#    location by specifying SUPERLU_DIST_INSTALL_DIR


# Intialize download/src/install vars
SET( SUPERLU_DIST_BUILD_DIR "${CMAKE_BINARY_DIR}/SUPERLU_DIST-prefix/src/SUPERLU_DIST-build" )
IF ( SUPERLU_DIST_URL ) 
    MESSAGE_TPL("   SUPERLU_DIST_URL = ${SUPERLU_DIST_URL}")
    SET( SUPERLU_DIST_SRC_DIR "${CMAKE_BINARY_DIR}/SUPERLU_DIST-prefix/src/SUPERLU_DIST-src" )
    SET( SUPERLU_DIST_CMAKE_URL            "${SUPERLU_DIST_URL}"     )
    SET( SUPERLU_DIST_CMAKE_DOWNLOAD_DIR   "${SUPERLU_DIST_SRC_DIR}" )
    SET( SUPERLU_DIST_CMAKE_DOWNLOAD_CMD   URL                 )
    SET( SUPERLU_DIST_CMAKE_SOURCE_DIR     "${SUPERLU_DIST_SRC_DIR}" )
    SET( SUPERLU_DIST_CMAKE_INSTALL_DIR "${CMAKE_INSTALL_PREFIX}/superlu_dist" )
    SET( CMAKE_BUILD_SUPERLU_DIST TRUE )
ELSEIF ( SUPERLU_DIST_SRC_DIR )
    VERIFY_PATH("${SUPERLU_DIST_SRC_DIR}")
    MESSAGE_TPL("   SUPERLU_DIST_SRC_DIR = ${SUPERLU_DIST_SRC_DIR}")
    SET( SUPERLU_DIST_CMAKE_URL            ""                  )
    SET( SUPERLU_DIST_CMAKE_DOWNLOAD_DIR   ""                  )
    SET( SUPERLU_DIST_CMAKE_DOWNLOAD_CMD   URL                 )
    SET( SUPERLU_DIST_CMAKE_SOURCE_DIR     "${SUPERLU_DIST_SRC_DIR}" )
    SET( SUPERLU_DIST_CMAKE_INSTALL_DIR "${CMAKE_INSTALL_PREFIX}/superlu_dist" )
    SET( CMAKE_BUILD_SUPERLU_DIST TRUE )
ELSEIF ( SUPERLU_DIST_INSTALL_DIR ) 
    SET( SUPERLU_DIST_CMAKE_INSTALL_DIR "${SUPERLU_DIST_INSTALL_DIR}" )
    SET( CMAKE_BUILD_SUPERLU_DIST FALSE )
ELSE()
    MESSAGE(FATAL_ERROR "Please specify SUPERLU_DIST_SRC_DIR, SUPERLU_DIST_URL, or SUPERLU_DIST_INSTALL_DIR")
ENDIF()
FILE( MAKE_DIRECTORY "${SUPERLU_DIST_CMAKE_INSTALL_DIR}" )
SET( SUPERLU_DIST_INSTALL_DIR "${SUPERLU_DIST_CMAKE_INSTALL_DIR}" )
MESSAGE_TPL( "   SUPERLU_DIST_INSTALL_DIR = ${SUPERLU_DIST_INSTALL_DIR}" )
FILE( APPEND "${CMAKE_INSTALL_PREFIX}/TPLs.cmake" "SET(SUPERLU_DIST_INSTALL_DIR \"${SUPERLU_DIST_INSTALL_DIR}\")\n" )


# Configure superlu
IF ( CMAKE_BUILD_SUPERLU_DIST )
    IF ( ENABLE_SHARED AND ENABLE_STATIC )
        MESSAGE(FATAL_ERROR "Compiling superlu_dist with both static and shared libraries is not yet supported")
    ELSEIF ( ENABLE_SHARED )
        SET( TPL_PARMETIS_LIBRARIES "${PARMETIS_INSTALL_DIR}/lib/libparmetis.so;${PARMETIS_INSTALL_DIR}/lib/libmetis.so" )
    ELSEIF ( ENABLE_STATIC )
        SET( TPL_PARMETIS_LIBRARIES "${PARMETIS_INSTALL_DIR}/lib/libparmetis.a;${PARMETIS_INSTALL_DIR}/lib/libmetis.a" )
    ENDIF()
    SET( CONFIGURE_OPTIONS "${CONFIGURE_OPTIONS};-DCMAKE_BUILD_TYPE=${CMAKE_BUILD_TYPE}" )
    SET( CONFIGURE_OPTIONS "${CONFIGURE_OPTIONS};-DCMAKE_INSTALL_PREFIX=${SUPERLU_DIST_CMAKE_INSTALL_DIR}" )
    SET( CONFIGURE_OPTIONS "${CONFIGURE_OPTIONS};-DCMAKE_C_COMPILER=${CMAKE_C_COMPILER}" )
    SET( CONFIGURE_OPTIONS "${CONFIGURE_OPTIONS};-DCMAKE_Fortran_COMPILER=${CMAKE_Fortran_COMPILER}" )
    SET( CONFIGURE_OPTIONS "${CONFIGURE_OPTIONS};-DTPL_PARMETIS_INCLUDE_DIRS=${PARMETIS_INSTALL_DIR}/include" )
    SET( CONFIGURE_OPTIONS "${CONFIGURE_OPTIONS};-DTPL_PARMETIS_LIBRARIES=${TPL_PARMETIS_LIBRARIES}" )
ENDIF()


# Build superlu
IF ( CMAKE_BUILD_SUPERLU_DIST )
    EXTERNALPROJECT_ADD(
        SUPERLU_DIST
        URL                 "${SUPERLU_DIST_CMAKE_URL}"
        DOWNLOAD_DIR        "${SUPERLU_DIST_CMAKE_DOWNLOAD_DIR}"
        SOURCE_DIR          "${SUPERLU_DIST_CMAKE_SOURCE_DIR}"
        UPDATE_COMMAND      ""
        CMAKE_ARGS          "${CONFIGURE_OPTIONS}"
        BUILD_COMMAND       make -j ${PROCS_INSTALL} VERBOSE=1
        BUILD_IN_SOURCE     0
        INSTALL_COMMAND     make install
        DEPENDS             PARMETIS
        LOG_DOWNLOAD 1   LOG_UPDATE 1   LOG_CONFIGURE 1   LOG_BUILD 1   LOG_TEST 1   LOG_INSTALL 1
    )
    ADD_TPL_SAVE_LOGS( SUPERLU_DIST )
    ADD_TPL_CLEAN( SUPERLU_DIST )
ELSE()
    ADD_TPL_EMPTY( SUPERLU_DIST )
ENDIF()



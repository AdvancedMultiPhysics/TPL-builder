# This will configure and build scalapack
# User can configure the source path by specifying SCALAPACK_SRC_DIR,
#    the download path by specifying SCALAPACK_URL, or the installed 
#    location by specifying SCALAPACK_INSTALL_DIR


# Intialize download/src/install vars
SET( SCALAPACK_BUILD_DIR "${CMAKE_BINARY_DIR}/SCALAPACK-prefix/src/SCALAPACK-build" )
IF ( SCALAPACK_URL ) 
    MESSAGE("   SCALAPACK_URL = ${SCALAPACK_URL}")
    SET( SCALAPACK_SRC_DIR "${CMAKE_BINARY_DIR}/SCALAPACK-prefix/src/SCALAPACK-src" )
    SET( SCALAPACK_CMAKE_URL            "${SCALAPACK_URL}"     )
    SET( SCALAPACK_CMAKE_DOWNLOAD_DIR   "${SCALAPACK_SRC_DIR}" )
    SET( SCALAPACK_CMAKE_DOWNLOAD_CMD   URL                 )
    SET( SCALAPACK_CMAKE_SOURCE_DIR     "${SCALAPACK_SRC_DIR}" )
    SET( SCALAPACK_CMAKE_INSTALL_DIR "${CMAKE_INSTALL_PREFIX}/scalapack" )
    SET( CMAKE_BUILD_SCALAPACK TRUE )
ELSEIF ( SCALAPACK_SRC_DIR )
    VERIFY_PATH("${SCALAPACK_SRC_DIR}")
    MESSAGE("   SCALAPACK_SRC_DIR = ${SCALAPACK_SRC_DIR}")
    SET( SCALAPACK_CMAKE_URL            ""                  )
    SET( SCALAPACK_CMAKE_DOWNLOAD_DIR   ""                  )
    SET( SCALAPACK_CMAKE_DOWNLOAD_CMD   URL                 )
    SET( SCALAPACK_CMAKE_SOURCE_DIR     "${SCALAPACK_SRC_DIR}" )
    SET( SCALAPACK_CMAKE_INSTALL_DIR "${CMAKE_INSTALL_PREFIX}/scalapack" )
    SET( CMAKE_BUILD_SCALAPACK TRUE )
ELSEIF ( SCALAPACK_INSTALL_DIR ) 
    SET( SCALAPACK_CMAKE_INSTALL_DIR "${SCALAPACK_INSTALL_DIR}" )
    SET( CMAKE_BUILD_SCALAPACK FALSE )
ELSE()
    MESSAGE(FATAL_ERROR "Please specify SCALAPACK_SRC_DIR, SCALAPACK_URL, or SCALAPACK_INSTALL_DIR")
ENDIF()
FILE( MAKE_DIRECTORY "${SCALAPACK_CMAKE_INSTALL_DIR}" )
SET( SCALAPACK_INSTALL_DIR "${SCALAPACK_CMAKE_INSTALL_DIR}" )
MESSAGE( "   SCALAPACK_INSTALL_DIR = ${SCALAPACK_INSTALL_DIR}" )


# Configure scalapack
IF ( CMAKE_BUILD_SCALAPACK )
    SET( CONFIGURE_OPTIONS "${CMAKE_ARGS}" )
    SET( CONFIGURE_OPTIONS "${CONFIGURE_OPTIONS};-DCMAKE_BUILD_TYPE=${CMAKE_BUILD_TYPE}" )
    SET( CONFIGURE_OPTIONS "${CONFIGURE_OPTIONS};-DCMAKE_INSTALL_PREFIX=${SCALAPACK_CMAKE_INSTALL_DIR}" )
    SET( CONFIGURE_OPTIONS "${CONFIGURE_OPTIONS};-DCMAKE_C_COMPILER=${CMAKE_C_COMPILER}" )
    SET( CONFIGURE_OPTIONS "${CONFIGURE_OPTIONS};-DCMAKE_Fortran_COMPILER=${CMAKE_Fortran_COMPILER}" )
ENDIF()


# Build scalapack
ADD_TPL(
    SCALAPACK
    URL                 "${SCALAPACK_CMAKE_URL}"
    DOWNLOAD_DIR        "${SCALAPACK_CMAKE_DOWNLOAD_DIR}"
    SOURCE_DIR          "${SCALAPACK_CMAKE_SOURCE_DIR}"
    UPDATE_COMMAND      ""
    CMAKE_ARGS          "${CONFIGURE_OPTIONS}"
    BUILD_COMMAND       make -j ${PROCS_INSTALL} VERBOSE=1
    BUILD_IN_SOURCE     0
    INSTALL_COMMAND     make install
    DEPENDS             LAPACK
    LOG_DOWNLOAD 1   LOG_UPDATE 1   LOG_CONFIGURE 1   LOG_BUILD 1   LOG_TEST 1   LOG_INSTALL 1
)



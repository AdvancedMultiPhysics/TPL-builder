# This will configure and build chaco
# User can configure the source path by specifying CHACO_SRC_DIR
#    the download path by specifying CHACO_URL, or the installed 
#    location by specifying CHACO_INSTALL_DIR


# Intialize download/src/install vars
SET( CHACO_BUILD_DIR "${CMAKE_BINARY_DIR}/CHACO-prefix/src/CHACO-build" )
IF ( CHACO_URL ) 
    MESSAGE("   CHACO_URL = ${CHACO_URL}")
    SET( CHACO_CMAKE_URL            "${CHACO_URL}"       )
    SET( CHACO_CMAKE_DOWNLOAD_DIR   "${CHACO_BUILD_DIR}" )
    SET( CHACO_CMAKE_SOURCE_DIR     "${CHACO_BUILD_DIR}" )
    SET( CHACO_CMAKE_INSTALL_DIR "${CMAKE_INSTALL_PREFIX}/chaco" )
    SET( CMAKE_BUILD_CHACO TRUE )
ELSEIF ( CHACO_SRC_DIR )
    MESSAGE("   CHACO_SRC_DIR = ${CHACO_SRC_DIR}")
    SET( CHACO_CMAKE_URL            "${CHACO_SRC_DIR}/code"   )
    SET( CHACO_CMAKE_DOWNLOAD_DIR   "${CHACO_BUILD_DIR}" )
    SET( CHACO_CMAKE_SOURCE_DIR     "${CHACO_BUILD_DIR}" )
    SET( CHACO_CMAKE_INSTALL_DIR "${CMAKE_INSTALL_PREFIX}/chaco" )
    SET( CMAKE_BUILD_CHACO TRUE )
ELSEIF ( CHACO_INSTALL_DIR ) 
    SET( CHACO_CMAKE_INSTALL_DIR "${CHACO_INSTALL_DIR}" )
    SET( CMAKE_BUILD_CHACO FALSE )
ELSE()
    MESSAGE(FATAL_ERROR "Please specify CHACO_SRC_DIR, CHACO_URL, or CHACO_INSTALL_DIR")
ENDIF()
SET( CHACO_INSTALL_DIR "${CHACO_CMAKE_INSTALL_DIR}" )
MESSAGE("   CHACO_SRC_DIR = ${CHACO_SRC_DIR}")


# Configure chaco
IF ( CMAKE_BUILD_CHACO )
    IF ( ENABLE_SHARED AND ENABLE_STATIC )
        MESSAGE(FATAL_ERROR "Compiling parmetis with both static and shared libraries is not yet supported")
    ELSEIF ( ENABLE_SHARED )
        SET( CHACO_CFLAGS ${CMAKE_C_FLAGS} -shared )
        SET( CHACO_CXXFLAGS ${CMAKE_CXX_FLAGS} -shared )
        SET( CHACO_FFLAGS ${CMAKE_Fortran_FLAGS} -shared )
    ELSEIF ( ENABLE_STATIC )
        SET( CHACO_CFLAGS ${CMAKE_C_FLAGS} -static )
        SET( CHACO_CXXFLAGS ${CMAKE_CXX_FLAGS} -static )
        SET( CHACO_FFLAGS ${CMAKE_Fortran_FLAGS} -static )
    ENDIF()
    SET( CHACO_VARS CC=${CMAKE_C_COMPILER} CFLAGS=${PARMETIS_CFLAGS} )
    SET( CHACO_VARS ${CHACO_VARS} CXX=${CMAKE_CXX_COMPILER} CXXFLAGS=${PARMETIS_CXXFLAGS} )
    SET( CHACO_VARS ${CHACO_VARS} FC=${CMAKE_Fortran_COMPILER} FCFLAGS=${PARMETIS_FFLAGS} )
    SET( CHACO_VARS ${CHACO_VARS} LDFLAGS=${LDFLAGS} )


# Build chaco
ADD_TPL(
    CHACO
    URL                 "${CHACO_CMAKE_URL}"
    DOWNLOAD_DIR        "${CHACO_CMAKE_DOWNLOAD_DIR}"
    SOURCE_DIR          "${CHACO_CMAKE_SOURCE_DIR}"
    UPDATE_COMMAND      ""
    CONFIGURE_COMMAND   ""
    BUILD_COMMAND       $(MAKE) ${CHACO_VARS} AR=ar lib  VERBOSE=1
    BUILD_IN_SOURCE     1
    INSTALL_COMMAND     ${CMAKE_COMMAND} -E copy_directory "${CHACO_SRC_DIR}/code/libchaco.a" "${CMAKE_INSTALL_PREFIX}/chaco/libchaco.a"
    LOG_DOWNLOAD 1   LOG_UPDATE 1   LOG_CONFIGURE 1   LOG_BUILD 1   LOG_TEST 1   LOG_INSTALL 1
)

ELSE()
    ADD_TPL_EMPTY( CHACO )
ENDIF()

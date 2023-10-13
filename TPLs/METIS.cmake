# This will configure and build metis
# User can configure the source path by specifying METIS_SRC_DIR,
#    the download path by specifying METIS_URL, or the installed 
#    location by specifying METIS_INSTALL_DIR


# Intialize download/src/install vars
SET( METIS_BUILD_DIR "${CMAKE_BINARY_DIR}/METIS-prefix/src/METIS-build" )
IF ( METIS_URL ) 
    MESSAGE("   METIS_URL = ${METIS_URL}")
    SET( METIS_CMAKE_URL            "${METIS_URL}"       )
    SET( METIS_CMAKE_DOWNLOAD_DIR   "${METIS_BUILD_DIR}" )
    SET( METIS_CMAKE_SOURCE_DIR     "${METIS_BUILD_DIR}" )
    SET( METIS_CMAKE_INSTALL_DIR "${CMAKE_INSTALL_PREFIX}/metis" )
    SET( CMAKE_BUILD_METIS TRUE )
ELSEIF ( METIS_SRC_DIR )
    VERIFY_PATH("${METIS_SRC_DIR}")
    MESSAGE("   METIS_SRC_DIR = ${METIS_SRC_DIR}")
    SET( METIS_CMAKE_URL            "${METIS_SRC_DIR}"   )
    SET( METIS_CMAKE_DOWNLOAD_DIR   "${METIS_BUILD_DIR}" )
    SET( METIS_CMAKE_SOURCE_DIR     "${METIS_BUILD_DIR}" )
    SET( METIS_CMAKE_INSTALL_DIR "${CMAKE_INSTALL_PREFIX}/metis" )
    SET( CMAKE_BUILD_METIS TRUE )
ELSEIF ( METIS_INSTALL_DIR ) 
    SET( METIS_CMAKE_INSTALL_DIR "${METIS_INSTALL_DIR}" )
    SET( CMAKE_BUILD_METIS FALSE )
ELSE()
    MESSAGE(FATAL_ERROR "Please specify METIS_SRC_DIR, METIS_URL, or METIS_INSTALL_DIR")
ENDIF()
SET( METIS_INSTALL_DIR "${METIS_CMAKE_INSTALL_DIR}" )
MESSAGE( "   METIS_INSTALL_DIR = ${METIS_INSTALL_DIR}" )


# Configure metis
IF ( CMAKE_BUILD_METIS )
    IF ( ENABLE_SHARED AND ENABLE_STATIC )
        MESSAGE(FATAL_ERROR "Compiling metis with both static and shared libraries is not yet supported")
    ELSEIF ( ENABLE_SHARED )
        SET( METIS_CFLAGS "${CMAKE_C_FLAGS} -shared" )
        SET( METIS_CXXFLAGS "${CMAKE_CXX_FLAGS} -shared" )
        SET( METIS_FFLAGS "${CMAKE_Fortran_FLAGS} -shared" )
    ELSEIF ( ENABLE_STATIC )
        SET( METIS_CFLAGS "${CMAKE_C_FLAGS} -static" )
        SET( METIS_CXXFLAGS "${CMAKE_CXX_FLAGS} -static" )
        SET( METIS_FFLAGS "${CMAKE_Fortran_FLAGS} -static" )
    ENDIF()
    SET( METIS_VARS CC=${CMAKE_C_COMPILER} CFLAGS=${METIS_CFLAGS} )
    SET( METIS_VARS ${METIS_VARS} CXX=${CMAKE_CXX_COMPILER} CXXFLAGS=${METIS_CXXFLAGS} )
    SET( METIS_VARS ${METIS_VARS} FC=${CMAKE_Fortran_COMPILER} FCFLAGS=${METIS_FFLAGS} )
    SET( METIS_VARS ${METIS_VARS} LDFLAGS=${LDFLAGS} )


    # Build metis
    ADD_TPL(
        METIS
        URL                 "${METIS_CMAKE_URL}"
        DOWNLOAD_DIR        "${METIS_CMAKE_DOWNLOAD_DIR}"
        SOURCE_DIR          "${METIS_CMAKE_SOURCE_DIR}"
        UPDATE_COMMAND      ""
        CONFIGURE_COMMAND   make config CC=${CMAKE_C_COMPILER} CXX=${CMAKE_CXX_COMPILER} 
                            FC=${CMAKE_Fortran_COMPILER} prefix=${METIS_INSTALL_DIR} VERBOSE=1
        BUILD_COMMAND       make ${METIS_VARS} -i
        BUILD_IN_SOURCE     1
        INSTALL_COMMAND     make install -i
        LOG_DOWNLOAD 1   LOG_UPDATE 1   LOG_CONFIGURE 1   LOG_BUILD 1   LOG_TEST 1   LOG_INSTALL 1
    )
ELSE()
    ADD_TPL_EMPTY( METIS )
ENDIF()



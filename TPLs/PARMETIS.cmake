# This will configure and build parmetis
# User can configure the source path by specifying PARMETIS_SRC_DIR,
#    the download path by specifying PARMETIS_URL, or the installed 
#    location by specifying PARMETIS_INSTALL_DIR


# Intialize download/src/install vars
SET( PARMETIS_BUILD_DIR "${CMAKE_BINARY_DIR}/PARMETIS-prefix/src/PARMETIS-build" )
IF ( PARMETIS_URL ) 
    MESSAGE("   PARMETIS_URL = ${PARMETIS_URL}")
    SET( PARMETIS_CMAKE_URL            "${PARMETIS_URL}"       )
    SET( PARMETIS_CMAKE_DOWNLOAD_DIR   "${PARMETIS_BUILD_DIR}" )
    SET( PARMETIS_CMAKE_SOURCE_DIR     "${PARMETIS_BUILD_DIR}" )
    SET( PARMETIS_CMAKE_INSTALL_DIR "${CMAKE_INSTALL_PREFIX}/parmetis" )
    SET( CMAKE_BUILD_PARMETIS TRUE )
ELSEIF ( PARMETIS_SRC_DIR )
    VERIFY_PATH("${PARMETIS_SRC_DIR}")
    MESSAGE("   PARMETIS_SRC_DIR = ${PARMETIS_SRC_DIR}")
    SET( PARMETIS_CMAKE_URL            "${PARMETIS_SRC_DIR}"   )
    SET( PARMETIS_CMAKE_DOWNLOAD_DIR   "${PARMETIS_BUILD_DIR}" )
    SET( PARMETIS_CMAKE_SOURCE_DIR     "${PARMETIS_BUILD_DIR}" )
    SET( PARMETIS_CMAKE_INSTALL_DIR "${CMAKE_INSTALL_PREFIX}/parmetis" )
    SET( CMAKE_BUILD_PARMETIS TRUE )
ELSEIF ( PARMETIS_INSTALL_DIR ) 
    SET( PARMETIS_CMAKE_INSTALL_DIR "${PARMETIS_INSTALL_DIR}" )
    SET( CMAKE_BUILD_PARMETIS FALSE )
ELSE()
    MESSAGE(FATAL_ERROR "Please specify PARMETIS_SRC_DIR, PARMETIS_URL, or PARMETIS_INSTALL_DIR")
ENDIF()
SET( PARMETIS_INSTALL_DIR "${PARMETIS_CMAKE_INSTALL_DIR}" )
MESSAGE( "   PARMETIS_INSTALL_DIR = ${PARMETIS_INSTALL_DIR}" )

# Configure parmetis
IF ( CMAKE_BUILD_PARMETIS )
    IF ( ENABLE_SHARED AND ENABLE_STATIC )
        MESSAGE(FATAL_ERROR "Compiling parmetis with both static and shared libraries is not yet supported")
    ELSEIF ( ENABLE_SHARED )
        SET( PARMETIS_CFLAGS "${CMAKE_C_FLAGS} -shared" )
        SET( PARMETIS_CXXFLAGS "${CMAKE_CXX_FLAGS} -shared" )
        SET( PARMETIS_FFLAGS "${CMAKE_Fortran_FLAGS} -shared" )
    ELSEIF ( ENABLE_STATIC )
        SET( PARMETIS_CFLAGS "${CMAKE_C_FLAGS} -static" )
        SET( PARMETIS_CXXFLAGS "${CMAKE_CXX_FLAGS} -static" )
        SET( PARMETIS_FFLAGS "${CMAKE_Fortran_FLAGS} -static" )
    ENDIF()
    SET( PARMETIS_VARS CC=${CMAKE_C_COMPILER} CFLAGS=${PARMETIS_CFLAGS} )
    SET( PARMETIS_VARS ${PARMETIS_VARS} CXX=${CMAKE_CXX_COMPILER} CXXFLAGS=${PARMETIS_CXXFLAGS} )
    SET( PARMETIS_VARS ${PARMETIS_VARS} FC=${CMAKE_Fortran_COMPILER} FCFLAGS=${PARMETIS_FFLAGS} )
    SET( PARMETIS_VARS ${PARMETIS_VARS} LDFLAGS=${LDFLAGS} )
ENDIF()


# Build parmetis
# Note: a bug in the parmetis cmake scripts results in parmetis not installing the metis headers and libs
# The current fix is to modify the Parmetis CMakeLists.txt to run the metis install also
# Currently this might not be portable due to the use of sed
IF ( CMAKE_BUILD_PARMETIS )
    EXTERNALPROJECT_ADD(
        PARMETIS
        URL                 "${PARMETIS_CMAKE_URL}"
        DOWNLOAD_DIR        "${PARMETIS_CMAKE_DOWNLOAD_DIR}"
        SOURCE_DIR          "${PARMETIS_CMAKE_SOURCE_DIR}"
        UPDATE_COMMAND      ""
        PATCH_COMMAND       sed -e "s|add_subdirectory\(\${METIS_PATH}\\/libmetis \${CMAKE_BINARY_DIR}\\/libmetis\)|add_subdirectory\(\${METIS_PATH}\)|" ${PARMETIS_CMAKE_SOURCE_DIR}/CMakeLists.txt > tmp
                            COMMAND mv tmp ${PARMETIS_CMAKE_SOURCE_DIR}/CMakeLists.txt
        CONFIGURE_COMMAND   make config CC=${CMAKE_C_COMPILER} CXX=${CMAKE_CXX_COMPILER} 
                            FC=${CMAKE_Fortran_COMPILER} prefix=${PARMETIS_INSTALL_DIR} VERBOSE=1
        BUILD_COMMAND       make ${PARMETIS_VARS} -i
        BUILD_IN_SOURCE     1
        INSTALL_COMMAND     make install -i
        LOG_DOWNLOAD 1   LOG_UPDATE 1   LOG_CONFIGURE 1   LOG_BUILD 1   LOG_TEST 1   LOG_INSTALL 1
    )
    ADD_TPL_SAVE_LOGS( PARMETIS )
    ADD_TPL_CLEAN( PARMETIS )
ELSE()
    ADD_TPL_EMPTY( PARMETIS )
ENDIF()



# This will configure and build SAMRUtils
# User can configure the source path by specifying SAMRUTILS_SRC_DIR,
#    the download path by specifying SAMRUTILS_URL, or the installed 
#    location by specifying SAMRUTILS_INSTALL_DIR


# Intialize download/src/install vars
SET( SAMRUTILS_BUILD_DIR "${CMAKE_BINARY_DIR}/SAMRUTILS-prefix/src/SAMRUTILS-build" )
IF ( SAMRUTILS_URL ) 
    MESSAGE("   SAMRUTILS_URL = ${SAMRUTILS_URL}")
    SET( SAMRUTILS_SRC_DIR "${CMAKE_BINARY_DIR}/SAMRUTILS-prefix/src/SAMRUTILS-src" )
    SET( SAMRUTILS_CMAKE_URL            "${SAMRUTILS_URL}"     )
    SET( SAMRUTILS_CMAKE_DOWNLOAD_DIR   "${SAMRUTILS_SRC_DIR}" )
    SET( SAMRUTILS_CMAKE_DOWNLOAD_CMD   URL                 )
    SET( SAMRUTILS_CMAKE_SOURCE_DIR     "${SAMRUTILS_SRC_DIR}" )
    SET( SAMRUTILS_CMAKE_INSTALL_DIR "${CMAKE_INSTALL_PREFIX}/samrutils" )
    SET( CMAKE_BUILD_SAMRUTILS TRUE )
ELSEIF ( SAMRUTILS_SRC_DIR )
    VERIFY_PATH("${SAMRUTILS_SRC_DIR}")
    MESSAGE("   SAMRUTILS_SRC_DIR = ${SAMRUTILS_SRC_DIR}")
    SET( SAMRUTILS_CMAKE_URL            ""                  )
    SET( SAMRUTILS_CMAKE_DOWNLOAD_DIR   ""                  )
    SET( SAMRUTILS_CMAKE_DOWNLOAD_CMD   URL                 )
    SET( SAMRUTILS_CMAKE_SOURCE_DIR     "${SAMRUTILS_SRC_DIR}" )
    SET( SAMRUTILS_CMAKE_INSTALL_DIR "${CMAKE_INSTALL_PREFIX}/samrutils" )
    SET( CMAKE_BUILD_SAMRUTILS TRUE )
ELSEIF ( SAMRUTILS_INSTALL_DIR ) 
    SET( SAMRUTILS_CMAKE_INSTALL_DIR "${SAMRUTILS_INSTALL_DIR}" )
    SET( CMAKE_BUILD_SAMRUTILS FALSE )
ELSE()
    MESSAGE(FATAL_ERROR "Please specify SAMRUTILS_SRC_DIR, SAMRUTILS_URL, or SAMRUTILS_INSTALL_DIR")
ENDIF()
FILE( MAKE_DIRECTORY "${SAMRUTILS_CMAKE_INSTALL_DIR}" )
SET( SAMRUTILS_INSTALL_DIR "${SAMRUTILS_CMAKE_INSTALL_DIR}" )
MESSAGE( "   SAMRUTILS_INSTALL_DIR = ${SAMRUTILS_INSTALL_DIR}" )


# Configure optional/required TPLs
CONFIGURE_DEPENDENCIES( SAMRUTILS REQUIRED SAMRAI AMP OPTIONAL LAPACK ZLIB HYPRE PETSC HDF5 CATCH2 THRUST RAJA KOKKOS UMPIRE )


# Configure SAMRUtils
IF ( CMAKE_BUILD_SAMRUTILS )
    SET( SAMRUTILS_CONFIGURE_OPTIONS "${CMAKE_ARGS}" )
    SET( SAMRUTILS_CONFIGURE_OPTIONS "${SAMRUTILS_CONFIGURE_OPTIONS};-DCMAKE_BUILD_TYPE=${CMAKE_BUILD_TYPE}" )
    SET( SAMRUTILS_CONFIGURE_OPTIONS "${SAMRUTILS_CONFIGURE_OPTIONS};-DSAMRUTILS_INSTALL_DIR=${SAMRUTILS_INSTALL_DIR}" )
    SET( SAMRUTILS_CONFIGURE_OPTIONS "${SAMRUTILS_CONFIGURE_OPTIONS};-DAMP_DIRECTORY=${AMP_INSTALL_DIR}" )
    IF ( DISABLE_THREAD_CHANGES )
        SET( SAMRUTILS_CONFIGURE_OPTIONS "${SAMRUTILS_CONFIGURE_OPTIONS};-DDISABLE_THREAD_CHANGES=${DISABLE_THREAD_CHANGES}" )
    ENDIF()
    IF ( TEST_MAX_PROCS )
        SET( SAMRUTILS_CONFIGURE_OPTIONS "${SAMRUTILS_CONFIGURE_OPTIONS};-DTEST_MAX_PROCS=${TEST_MAX_PROCS}" )
    ENDIF()
    IF ( SAMRUTILS_DISABLE_THRUST )
        SET( SAMRUTILS_CONFIGURE_OPTIONS "${SAMRUTILS_CONFIGURE_OPTIONS};-DDISABLE_THRUST=${SAMRUTILS_DISABLE_THRUST}" )
    ENDIF()
    IF ( SAMRUTILS_DISABLE_KOKKOS )
        SET( SAMRUTILS_CONFIGURE_OPTIONS "${SAMRUTILS_CONFIGURE_OPTIONS};-DDISABLE_KOKKOS:BOOL=TRUE" )
	    SET( SAMRUTILS_CONFIGURE_OPTIONS "${SAMRUTILS_CONFIGURE_OPTIONS};-DDISABLE_CABANA:BOOL=TRUE" )
    ENDIF()
    MESSAGE( "SAMRUTILS configure options: " "${SAMRUTILS_CONFIGURE_OPTIONS}" )  


    # Build SAMRUtils
    ADD_TPL(
        SAMRUTILS
        URL                 "${SAMRUTILS_CMAKE_URL}"
        DOWNLOAD_DIR        "${SAMRUTILS_CMAKE_DOWNLOAD_DIR}"
        SOURCE_DIR          "${SAMRUTILS_CMAKE_SOURCE_DIR}"
        UPDATE_COMMAND      ""
        CMAKE_ARGS          "${SAMRUTILS_CONFIGURE_OPTIONS}"
        BUILD_COMMAND       $(MAKE) VERBOSE=1
        BUILD_IN_SOURCE     0
        INSTALL_COMMAND     $(MAKE) install
        LOG_DOWNLOAD 1   LOG_UPDATE 1   LOG_CONFIGURE 1   LOG_BUILD 1   LOG_TEST 1   LOG_INSTALL 1
        )

ELSE()
    ADD_TPL_EMPTY( SAMRUTILS )
ENDIF()

# Add the appropriate fields to FindTPLs.cmake
FILE( APPEND "${FIND_TPLS_CMAKE}" "\n# Find SAMRUTILS\n" )
FILE( APPEND "${FIND_TPLS_CMAKE}" "IF ( TPLs_FIND_SAMRUTILS AND NOT TPLs_SAMRUTILS_FOUND )\n" )
FILE( APPEND "${FIND_TPLS_CMAKE}" "    FIND_PACKAGE( SAMRUTILS REQUIRED PATHS \"${SAMRUTILS_INSTALL_DIR}\" )\n" )
FILE( APPEND "${FIND_TPLS_CMAKE}" "    ADD_TPL_LIBRARY( SAMRUTILS SAMRUTILS::samrutils )\n" )
FILE( APPEND "${FIND_TPLS_CMAKE}" "ENDIF()\n" )
FILE( APPEND "${FIND_TPLS_CMAKE}" "\n" )

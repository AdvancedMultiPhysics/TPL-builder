# This will configure and build amp
# User can configure the source path by specifying AMP_SRC_DIR,
#    the download path by specifying AMP_URL, or the installed 
#    location by specifying AMP_INSTALL_DIR


# Intialize download/src/install vars
SET( AMP_BUILD_DIR "${CMAKE_BINARY_DIR}/AMP-prefix/src/AMP-build" )
IF ( AMP_URL ) 
    MESSAGE("   AMP_URL = ${AMP_URL}")
    SET( AMP_SRC_DIR "${CMAKE_BINARY_DIR}/AMP-prefix/src/AMP-src" )
    SET( AMP_CMAKE_URL            "${AMP_URL}"     )
    SET( AMP_CMAKE_DOWNLOAD_DIR   "${AMP_SRC_DIR}" )
    SET( AMP_CMAKE_SOURCE_DIR     "${AMP_SRC_DIR}" )
    SET( AMP_CMAKE_INSTALL_DIR "${CMAKE_INSTALL_PREFIX}/amp" )
    SET( CMAKE_BUILD_AMP TRUE )
ELSEIF ( AMP_SRC_DIR )
    VERIFY_PATH("${AMP_SRC_DIR}")
    MESSAGE("   AMP_SRC_DIR = ${AMP_SRC_DIR}")
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
MESSAGE( "   AMP_INSTALL_DIR = ${AMP_INSTALL_DIR}" )

# Configure optional/required TPLs
CONFIGURE_DEPENDENCIES( AMP REQUIRED STACKTRACE OPTIONAL CPPCHECK TIMER LAPACK LAPACK_WRAPPERS TRILINOS PETSC HYPRE SUNDIALS HDF5 SILO SAMRAI LIBMESH KOKKOS THRUST RAJA UMPIRE )

# Configure amp
IF ( CMAKE_BUILD_AMP )
    SET( AMP_CONFIGURE_OPTIONS "${CMAKE_ARGS}" )
    SET( AMP_CONFIGURE_OPTIONS "${AMP_CONFIGURE_OPTIONS};-DAMP_INSTALL_DIR=${CMAKE_INSTALL_PREFIX}/amp" )
    SET( AMP_CONFIGURE_OPTIONS "${AMP_CONFIGURE_OPTIONS};-DCMAKE_INSTALL_PREFIX=${CMAKE_INSTALL_PREFIX}/amp" )
    SET( AMP_CONFIGURE_OPTIONS "${AMP_CONFIGURE_OPTIONS};-DTPL_DIRECTORY=${CMAKE_INSTALL_PREFIX}" )
    SET( AMP_CONFIGURE_OPTIONS "${AMP_CONFIGURE_OPTIONS};-DDISABLE_GXX_DEBUG:BOOL=true" )
    SET( AMP_CONFIGURE_OPTIONS "${AMP_CONFIGURE_OPTIONS};-DAMP_DATA:PATH=${AMP_DATA}" )
    IF ( ${CMAKE_BUILD_TYPE} STREQUAL "Debug" )
        SET( AMP_CONFIGURE_OPTIONS "${AMP_CONFIGURE_OPTIONS};-DCOMPILE_MODE=debug" )
    ELSEIF ( ${CMAKE_BUILD_TYPE} STREQUAL "Release" )
        SET( AMP_CONFIGURE_OPTIONS "${AMP_CONFIGURE_OPTIONS};-DCOMPILE_MODE=optimized" )
    ELSE()
        MESSAGE ( FATAL_ERROR "Unknown CMAKE_BUILD_TYPE=${CMAKE_BUILD_TYPE}" )
    ENDIF()
    STRING(REGEX REPLACE ";AMP.*" "" AMP_DEPENDS "${TPL_LIST}" )
    CHECK_ENABLE_FLAG( AMP_DOCS 1 )
    IF ( AMP_DOCS )
        SET( AMP_DOC_COMMAND  DOC_COMMAND $(MAKE) doc )
    ENDIF()


    # Build amp
    ADD_TPL(
        AMP
        URL                 "${AMP_CMAKE_URL}"
        DOWNLOAD_DIR        "${AMP_CMAKE_DOWNLOAD_DIR}"
        SOURCE_DIR          "${AMP_CMAKE_SOURCE_DIR}"
        UPDATE_COMMAND      ""
        BUILD_IN_SOURCE     0
        INSTALL_DIR         ${CMAKE_INSTALL_PREFIX}/amp
        CMAKE_ARGS          "${AMP_CONFIGURE_OPTIONS}"
        BUILD_COMMAND       $(MAKE) install VERBOSE=1
        ${AMP_DOC_COMMAND}
        LOG_DOWNLOAD 1   LOG_UPDATE 1   LOG_CONFIGURE 1   LOG_BUILD 1   LOG_TEST 1   LOG_INSTALL 1
    )

ELSE()
    ADD_TPL_EMPTY( AMP )
ENDIF()

# Add the appropriate fields to FindTPLs.cmake
FILE( APPEND "${FIND_TPLS_CMAKE}" "\n# Find AMP\n" )
FILE( APPEND "${FIND_TPLS_CMAKE}" "IF ( TPLs_FIND_AMP AND NOT TPLs_AMP_FOUND )\n" )
FILE( APPEND "${FIND_TPLS_CMAKE}" "    FIND_PACKAGE( AMP REQUIRED PATHS \"${AMP_INSTALL_DIR}/lib/cmake\" )\n" )
FILE( APPEND "${FIND_TPLS_CMAKE}" "    ADD_TPL_LIBRARY( AMP AMP::amp )\n" )
FILE( APPEND "${FIND_TPLS_CMAKE}" "ENDIF()\n" )
FILE( APPEND "${FIND_TPLS_CMAKE}" "\n" )

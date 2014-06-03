# This will configure and build samrai
# User can configure the source path by speficfying SAMRAI_SRC_DIR,
#    the download path by specifying SAMRAI_URL, or the installed 
#    location by specifying SAMRAI_INSTALL_DIR


# Intialize download/src/install vars
SET( SAMRAI_BUILD_DIR "${CMAKE_BINARY_DIR}/SAMRAI-prefix/src/SAMRAI-build" )
IF ( SAMRAI_URL ) 
    MESSAGE_TPL("   SAMRAI_URL = ${SAMRAI_URL}")
    SET( SAMRAI_SRC_DIR "${CMAKE_BINARY_DIR}/SAMRAI-prefix/src/SAMRAI-src" )
    SET( SAMRAI_CMAKE_URL            "${SAMRAI_URL}"     )
    SET( SAMRAI_CMAKE_DOWNLOAD_DIR   "${SAMRAI_SRC_DIR}" )
    SET( SAMRAI_CMAKE_SOURCE_DIR     "${SAMRAI_SRC_DIR}" )
    SET( SAMRAI_CMAKE_INSTALL_DIR "${CMAKE_INSTALL_PREFIX}/samrai" )
    SET( CMAKE_BUILD_SAMRAI TRUE )
ELSEIF ( SAMRAI_SRC_DIR )
    VERIFY_PATH("${SAMRAI_SRC_DIR}")
    MESSAGE_TPL("   SAMRAI_SRC_DIR = ${SAMRAI_SRC_DIR}")
    SET( SAMRAI_CMAKE_URL            ""                  )
    SET( SAMRAI_CMAKE_DOWNLOAD_DIR   ""                  )
    SET( SAMRAI_CMAKE_SOURCE_DIR     "${SAMRAI_SRC_DIR}" )
    SET( SAMRAI_CMAKE_INSTALL_DIR "${CMAKE_INSTALL_PREFIX}/samrai" )
    SET( CMAKE_BUILD_SAMRAI TRUE )
ELSEIF ( SAMRAI_INSTALL_DIR ) 
    SET( SAMRAI_CMAKE_INSTALL_DIR "${SAMRAI_INSTALL_DIR}" )
    SET( CMAKE_BUILD_SAMRAI FALSE )
ELSE()
    MESSAGE(FATAL_ERROR "Please specify SAMRAI_SRC_DIR, SAMRAI_URL, or SAMRAI_INSTALL_DIR")
ENDIF()
SET( SAMRAI_INSTALL_DIR "${SAMRAI_CMAKE_INSTALL_DIR}" )
MESSAGE_TPL( "   SAMRAI_INSTALL_DIR = ${SAMRAI_INSTALL_DIR}" )
FILE( APPEND "${CMAKE_INSTALL_PREFIX}/TPLs.cmake" "SET(SAMRAI_INSTALL_DIR \"${SAMRAI_INSTALL_DIR}\")\n" )


# Configure samrai
IF ( CMAKE_BUILD_SAMRAI )
    SET( CONFIGURE_OPTIONS )
    SET( CONFIGURE_OPTIONS ${CONFIGURE_OPTIONS} --with-boost=${BOOST_INSTALL_DIR} )
    SET( CONFIGURE_OPTIONS ${CONFIGURE_OPTIONS} --with-hdf5=${HDF5_INSTALL_DIR} )
    SET( CONFIGURE_OPTIONS ${CONFIGURE_OPTIONS} --with-petsc=${PETSC_INSTALL_DIR} )
    SET( CONFIGURE_OPTIONS ${CONFIGURE_OPTIONS} --with-hypre=${HYPRE_INSTALL_DIR} )
    SET( CONFIGURE_OPTIONS ${CONFIGURE_OPTIONS} --with-zlib=${ZLIB_INSTALL_DIR} )
    SET( CONFIGURE_OPTIONS ${CONFIGURE_OPTIONS} --with-blas-libs=${BLAS_LIBS} --with-lapack-libs=${LAPACK_LIBS} )
    SET( CONFIGURE_OPTIONS ${CONFIGURE_OPTIONS} --prefix=${SAMRAI_INSTALL_DIR}  )
    IF ( ${CMAKE_BUILD_TYPE} STREQUAL "Debug" )
        SET( CONFIGURE_OPTIONS ${CONFIGURE_OPTIONS} --enable-debug )
    ELSEIF ( ${CMAKE_BUILD_TYPE} STREQUAL "Release" )
        SET( CONFIGURE_OPTIONS ${CONFIGURE_OPTIONS} --enable-optimize )
    ELSE()
        MESSAGE ( FATAL_ERROR "Unknown CMAKE_BUILD_TYPE=${CMAKE_BUILD_TYPE}" )
    ENDIF()
    IF ( ENABLE_SHARED )
        SET( CONFIGURE_OPTIONS ${CONFIGURE_OPTIONS} --enable-shared )
    ELSE()
        SET( CONFIGURE_OPTIONS ${CONFIGURE_OPTIONS} --disable-shared )
    ENDIF()
ENDIF()


# Build samrai
IF ( CMAKE_BUILD_SAMRAI )
    SET( SAMRAI_CMAKE_TEST )
    IF ( SAMRAI_TEST )
        SET( SAMRAI_CMAKE_TEST   TEST_AFTER_INSTALL 1   TEST_COMMAND make check )
    ENDIF()
    EXTERNALPROJECT_ADD(
        SAMRAI
        URL                 "${SAMRAI_CMAKE_URL}"
        DOWNLOAD_DIR        "${SAMRAI_CMAKE_DOWNLOAD_DIR}"
        SOURCE_DIR          "${SAMRAI_CMAKE_SOURCE_DIR}"
        UPDATE_COMMAND      ""
        CONFIGURE_COMMAND   "${SAMRAI_CMAKE_SOURCE_DIR}/configure" ${CONFIGURE_OPTIONS} ${ENV_VARS} 
        BUILD_COMMAND       make -j ${PROCS_INSTALL} VERBOSE=1
        BUILD_IN_SOURCE     0
        INSTALL_COMMAND     make install
        ${SAMRAI_CMAKE_TEST}
        DEPENDS             LAPACK HDF5 HYPRE PETSC ZLIB BOOST
        LOG_DOWNLOAD 1   LOG_UPDATE 1   LOG_CONFIGURE 1   LOG_BUILD 1   LOG_TEST 1   LOG_INSTALL 1
    )
    IF ( SAMRAI_TEST )
        EXTERNALPROJECT_ADD_STEP(
            SAMRAI
            build-test
            COMMENT             "Compiling tests"
            COMMAND             make checkcompile -j ${PROCS_INSTALL} 
            COMMENT             ""
            DEPENDEES           build
            DEPENDERS           test
            WORKING_DIRECTORY   "${SAMRAI_BUILD_DIR}"
            LOG                 1
        )
    ENDIF()
    IF ( SAMRAI_TEST )
        EXTERNALPROJECT_ADD_STEP(
            SAMRAI
            check-test
            COMMENT             "Checking test results"
            COMMAND             ! grep "FAILED" SAMRAI-test-out.log > /dev/null 
            COMMENT             ""
            DEPENDEES           test
            WORKING_DIRECTORY   "${CMAKE_BINARY_DIR}/SAMRAI-prefix/src/SAMRAI-stamp"
            LOG                 0
        )
    ENDIF()
    ADD_TPL_SAVE_LOGS( SAMRAI )
    ADD_TPL_CLEAN( SAMRAI )
ELSE()
    ADD_TPL_EMPTY( SAMRAI )
ENDIF()



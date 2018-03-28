# This will configure and build samrai
# User can configure the source path by specifying SAMRAI_SRC_DIR,
#    the download path by specifying SAMRAI_URL, or the installed 
#    location by specifying SAMRAI_INSTALL_DIR


# Intialize download/src/install vars
SET( SAMRAI_BUILD_DIR "${CMAKE_BINARY_DIR}/SAMRAI-prefix/src/SAMRAI-build" )
IF ( SAMRAI_URL ) 
    MESSAGE("   SAMRAI_URL = ${SAMRAI_URL}")
    SET( SAMRAI_SRC_DIR "${CMAKE_BINARY_DIR}/SAMRAI-prefix/src/SAMRAI-src" )
    SET( SAMRAI_CMAKE_URL            "${SAMRAI_URL}"     )
    SET( SAMRAI_CMAKE_DOWNLOAD_DIR   "${SAMRAI_SRC_DIR}" )
    SET( SAMRAI_CMAKE_SOURCE_DIR     "${SAMRAI_SRC_DIR}" )
    SET( SAMRAI_CMAKE_INSTALL_DIR "${CMAKE_INSTALL_PREFIX}/samrai" )
    SET( CMAKE_BUILD_SAMRAI TRUE )
ELSEIF ( SAMRAI_SRC_DIR )
    VERIFY_PATH("${SAMRAI_SRC_DIR}")
    MESSAGE("   SAMRAI_SRC_DIR = ${SAMRAI_SRC_DIR}")
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
MESSAGE( "   SAMRAI_INSTALL_DIR = ${SAMRAI_INSTALL_DIR}" )


# Configure samrai
IF ( CMAKE_BUILD_SAMRAI )
    STRING( REPLACE ";" " " SAMRAI_BLAS_LIBS "${BLAS_LIBS}")
    STRING( REPLACE ";" " " SAMRAI_LAPACK_LIBS "${LAPACK_LIBS}")
    SET( CONFIGURE_OPTIONS )
    #SET( CONFIGURE_OPTIONS ${CONFIGURE_OPTIONS} --disable-timers )
    IF ( USE_MPI )
        SET( CONFIGURE_OPTIONS ${CONFIGURE_OPTIONS} --with-mpi )
        SET( CONFIGURE_OPTIONS ${CONFIGURE_OPTIONS} --with-MPICC=${CMAKE_C_COMPILER}  )
    ELSE()
        SET( CONFIGURE_OPTIONS ${CONFIGURE_OPTIONS} --without-mpi )
    ENDIF()
    SET( CONFIGURE_OPTIONS ${CONFIGURE_OPTIONS} --with-boost=${BOOST_INSTALL_DIR} )
    SET( CONFIGURE_OPTIONS ${CONFIGURE_OPTIONS} --with-hdf5=${HDF5_INSTALL_DIR}   )
    SET( CONFIGURE_OPTIONS ${CONFIGURE_OPTIONS} --with-zlib=${ZLIB_INSTALL_DIR}   )
    SET( CONFIGURE_OPTIONS ${CONFIGURE_OPTIONS} --with-blas-libs=${SAMRAI_BLAS_LIBS} )
    SET( CONFIGURE_OPTIONS ${CONFIGURE_OPTIONS} --with-lapack-libs=${SAMRAI_LAPACK_LIBS} )
    SET( CONFIGURE_OPTIONS ${CONFIGURE_OPTIONS} --prefix=${SAMRAI_INSTALL_DIR}    )
    IF ( ${CMAKE_BUILD_TYPE} STREQUAL "Debug" )
        SET( CONFIGURE_OPTIONS ${CONFIGURE_OPTIONS} --enable-debug )
    ELSEIF ( ${CMAKE_BUILD_TYPE} STREQUAL "Release" )
        SET( CONFIGURE_OPTIONS ${CONFIGURE_OPTIONS} --enable-opt )
        SET( CONFIGURE_OPTIONS ${CONFIGURE_OPTIONS} --disable-check-assertions )
    ELSE()
        MESSAGE ( FATAL_ERROR "Unknown CMAKE_BUILD_TYPE=${CMAKE_BUILD_TYPE}" )
    ENDIF()
    IF ( ENABLE_SHARED )
        SET( CONFIGURE_OPTIONS ${CONFIGURE_OPTIONS} --enable-shared )
    ELSE()
        SET( CONFIGURE_OPTIONS ${CONFIGURE_OPTIONS} --disable-shared )
    ENDIF()
    SET( SAMR_C_FLAGS "${CMAKE_C_FLAGS} -I${TIMER_CMAKE_INSTALL_DIR}/include" )
    SET( SAMR_CXX_FLAGS "${CMAKE_CXX_FLAGS} -I${TIMER_CMAKE_INSTALL_DIR}/include" )
    SET( SAMR_LDFLAGS "-L${TIMER_CMAKE_INSTALL_DIR}/lib ${LDFLAGS}" )
    SET( SAMR_LDLIBS "-ltimerutility -lpthread ${LDLIBS}" )
    SET( ENV_SAMR CC=${CMAKE_C_COMPILER} CFLAGS=${SAMR_C_FLAGS} )
    SET( ENV_SAMR ${ENV_SAMR} CXX=${CMAKE_CXX_COMPILER} CXXFLAGS=${SAMR_CXX_FLAGS} )
    SET( ENV_SAMR ${ENV_SAMR} F77=${CMAKE_Fortran_COMPILER} FFLAGS=${CMAKE_Fortran_FLAGS} )
    SET( ENV_SAMR ${ENV_SAMR} FC=${CMAKE_Fortran_COMPILER} FCFLAGS=${CMAKE_Fortran_FLAGS} )
    SET( ENV_SAMR ${ENV_SAMR} LDFLAGS=${SAMR_LDFLAGS} LIBS=${SAMR_LDLIBS} )
    SET( ENV_SAMR ${ENV_SAMR} DYLD_LIBRARY_PATH=${TIMER_CMAKE_INSTALL_DIR}/lib )
    CHECK_ENABLE_FLAG( SAMRAI_DOCS 1 )
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
        CONFIGURE_COMMAND   "${SAMRAI_CMAKE_SOURCE_DIR}/configure" ${CONFIGURE_OPTIONS} ${ENV_SAMR} 
        BUILD_COMMAND       make -j ${PROCS_INSTALL} VERBOSE=1
        BUILD_IN_SOURCE     0
        INSTALL_COMMAND     make install
        ${SAMRAI_CMAKE_TEST}
        DEPENDS             LAPACK HDF5 ZLIB BOOST TIMER
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
    IF ( SAMRAI_DOCS )
        EXTERNALPROJECT_ADD_STEP(
            SAMRAI
            build-docs
            COMMENT             "Compiling documentation"
            COMMAND             make dox -j ${PROCS_INSTALL} VERBOSE=1
            COMMAND             ${CMAKE_COMMAND} -E copy_directory docs/samrai-dox/html "${SAMRAI_INSTALL_DIR}/doxygen"
            COMMENT             ""
            DEPENDEES           install
            DEPENDERS           
            WORKING_DIRECTORY   "${SAMRAI_BUILD_DIR}"
            LOG                 1
        )

    ENDIF()
    ADD_TPL_SAVE_LOGS( SAMRAI )
    ADD_TPL_CLEAN( SAMRAI )
ELSE()
    ADD_TPL_EMPTY( SAMRAI )
ENDIF()


# Add the appropriate fields to FindTPLs.cmake
FILE( APPEND "${FIND_TPLS_CMAKE}" "\n# Find SAMRAI\n" )
FILE( APPEND "${FIND_TPLS_CMAKE}" "IF ( TPLs_FIND_SAMRAI AND NOT TPL_FOUND_SAMRAI )\n" )
FILE( APPEND "${FIND_TPLS_CMAKE}" "    SET( SAMRAI_DIR \"${SAMRAI_INSTALL_DIR}\" )\n" )
FILE( APPEND "${FIND_TPLS_CMAKE}" "    SET( SAMRAI_DIRECTORY \"${SAMRAI_INSTALL_DIR}\" )\n" )
FILE( APPEND "${FIND_TPLS_CMAKE}" "    SET( SAMRAI_INCLUDE \"${SAMRAI_INSTALL_DIR}/include\" )\n" )
FILE( APPEND "${FIND_TPLS_CMAKE}" "    SET( SAMRAI_LIB_DIR \"${SAMRAI_INSTALL_DIR}/lib\" )\n" )
FILE( APPEND "${FIND_TPLS_CMAKE}" "    FIND_LIBRARY ( SAMRAI_ALGS_LIB  NAMES SAMRAI_algs  PATHS $\{SAMRAI_LIB_DIR}  NO_DEFAULT_PATH )\n" )
FILE( APPEND "${FIND_TPLS_CMAKE}" "    FIND_LIBRARY ( SAMRAI_APPU_LIB  NAMES SAMRAI_appu  PATHS $\{SAMRAI_LIB_DIR}  NO_DEFAULT_PATH )\n" )
FILE( APPEND "${FIND_TPLS_CMAKE}" "    FIND_LIBRARY ( SAMRAI_GEOM_LIB  NAMES SAMRAI_geom  PATHS $\{SAMRAI_LIB_DIR}  NO_DEFAULT_PATH )\n" )
FILE( APPEND "${FIND_TPLS_CMAKE}" "    FIND_LIBRARY ( SAMRAI_HIER_LIB  NAMES SAMRAI_hier  PATHS $\{SAMRAI_LIB_DIR}  NO_DEFAULT_PATH )\n" )
FILE( APPEND "${FIND_TPLS_CMAKE}" "    FIND_LIBRARY ( SAMRAI_MATH_LIB  NAMES SAMRAI_math  PATHS $\{SAMRAI_LIB_DIR}  NO_DEFAULT_PATH )\n" )
FILE( APPEND "${FIND_TPLS_CMAKE}" "    FIND_LIBRARY ( SAMRAI_MESH_LIB  NAMES SAMRAI_mesh  PATHS $\{SAMRAI_LIB_DIR}  NO_DEFAULT_PATH )\n" )
FILE( APPEND "${FIND_TPLS_CMAKE}" "    FIND_LIBRARY ( SAMRAI_PDAT_LIB  NAMES SAMRAI_pdat  PATHS $\{SAMRAI_LIB_DIR}  NO_DEFAULT_PATH )\n" )
FILE( APPEND "${FIND_TPLS_CMAKE}" "    FIND_LIBRARY ( SAMRAI_SOLV_LIB  NAMES SAMRAI_solv  PATHS $\{SAMRAI_LIB_DIR}  NO_DEFAULT_PATH )\n" )
FILE( APPEND "${FIND_TPLS_CMAKE}" "    FIND_LIBRARY ( SAMRAI_TBOX_LIB  NAMES SAMRAI_tbox  PATHS $\{SAMRAI_LIB_DIR}  NO_DEFAULT_PATH )\n" )
FILE( APPEND "${FIND_TPLS_CMAKE}" "    FIND_LIBRARY ( SAMRAI_XFER_LIB  NAMES SAMRAI_xfer  PATHS $\{SAMRAI_LIB_DIR}  NO_DEFAULT_PATH )\n" )
FILE( APPEND "${FIND_TPLS_CMAKE}" "    SET ( SAMRAI_LIBS $\{SAMRAI_APPU_LIB} $\{SAMRAI_ALGS_LIB} $\{SAMRAI_SOLV_LIB} $\{SAMRAI_GEOM_LIB} $\{SAMRAI_MESH_LIB} $\{SAMRAI_MATH_LIB} $\{SAMRAI_PDAT_LIB} $\{SAMRAI_XFER_LIB} $\{SAMRAI_HIER_LIB} $\{SAMRAI_TBOX_LIB} )\n" )
FILE( APPEND "${FIND_TPLS_CMAKE}" "    IF ( (NOT SAMRAI_APPU_LIB) OR (NOT SAMRAI_ALGS_LIB) OR (NOT SAMRAI_SOLV_LIB) OR (NOT SAMRAI_GEOM_LIB) OR \n" )
FILE( APPEND "${FIND_TPLS_CMAKE}" "        (NOT SAMRAI_MESH_LIB) OR (NOT SAMRAI_MATH_LIB) OR (NOT SAMRAI_PDAT_LIB) OR (NOT SAMRAI_XFER_LIB) OR \n" )
FILE( APPEND "${FIND_TPLS_CMAKE}" "        (NOT SAMRAI_HIER_LIB) OR (NOT SAMRAI_TBOX_LIB) )\n" )
FILE( APPEND "${FIND_TPLS_CMAKE}" "        MESSAGE( FATAL_ERROR \"SAMRAI contribution libraries not found in $\{SAMRAI_LIB_DIR}\" )\n" )
FILE( APPEND "${FIND_TPLS_CMAKE}" "    ENDIF()\n" )
FILE( APPEND "${FIND_TPLS_CMAKE}" "    SET( SAMRAI_FORTDIR $\{SAMRAI_DIRECTORY}/include )\n" )
FILE( APPEND "${FIND_TPLS_CMAKE}" "    SET( TPL_INCLUDE_DIRS $\{TPL_INCLUDE_DIRS} $\{SAMRAI_INCLUDE} )\n" )
FILE( APPEND "${FIND_TPLS_CMAKE}" "    SET( TPL_LIBRARIES $\{SAMRAI_LIBS} $\{TPL_LIBRARIES} )\n" )
FILE( APPEND "${FIND_TPLS_CMAKE}" "    SET( SAMRAI_FOUND TRUE )\n" )
FILE( APPEND "${FIND_TPLS_CMAKE}" "    SET( TPL_FOUND_SAMRAI TRUE )\n" )
FILE( APPEND "${FIND_TPLS_CMAKE}" "ENDIF()\n" )
FILE( APPEND "${FIND_TPLS_CMAKE}" "\n" )



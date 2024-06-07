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


# Configure optional/required TPLs
CONFIGURE_DEPENDENCIES( SAMRAI REQUIRED LAPACK OPTIONAL ZLIB HDF5 UMPIRE RAJA TIMER )
# CONFIGURE_DEPENDENCIES( SARMAI REQUIRED LAPACK OPTIONAL ZLIB HDF5 UMPIRE RAJA TIMER HYPRE PETSC SILO SUNDIALS CONDUIT )


# Configure samrai
IF ( NOT DEFINED SAMRAI_USE_CUDA )
    SET( SAMRAI_USE_CUDA ${USE_CUDA} )
ENDIF()
IF ( NOT DEFINED SAMRAI_USE_HIP )
    SET( SAMRAI_USE_HIP ${USE_HIP} )
ENDIF()
IF ( NOT DEFINED SAMRAI_USE_OPENMP )
    SET( SAMRAI_USE_OPENMP ${USE_OPENMP} )
ENDIF()

IF ( CMAKE_BUILD_SAMRAI )
    STRING( REPLACE ";" " " SAMRAI_BLAS_LIBS "${BLAS_LIBS}")
    STRING( REPLACE ";" " " SAMRAI_LAPACK_LIBS "${LAPACK_LIBS}")
    IF ( NOT SAMRAI_VERSION )
        SET( SAMRAI_VERSION "0.0.0" )
    ENDIF()
    # Include the configure file
    SET( SAMRAI_CONFIGURE_OPTIONS ${CMAKE_ARGS} -DCMAKE_INSTALL_PREFIX=${CMAKE_INSTALL_PREFIX}/samrai )
    SET( SAMRAI_CONFIGURE_OPTIONS ${SAMRAI_CONFIGURE_OPTIONS} -DCMAKE_BUILD_TYPE=${CMAKE_BUILD_TYPE} )
    IF ( SAMRAI_USE_CUDA )
        MESSAGE( "Enabling CUDA support for SAMRAI" )
        IF ( SAMRAI_CUDA_ARCH_FLAGS )
             SET( SAMRAI_CONFIGURE_OPTIONS ${SAMRAI_CONFIGURE_OPTIONS} -DENABLE_CUDA=ON -DCUDA_ARCH=${SAMRAI_CUDA_ARCH_FLAGS} )
        ELSE()
             SET( SAMRAI_CONFIGURE_OPTIONS ${SAMRAI_CONFIGURE_OPTIONS} -DENABLE_CUDA=ON -DCUDA_ARCH=${CUDA_ARCH_FLAGS} )
        ENDIF()
        IF ( NOT DEFINED SAMRAI_USE_RAJA )
            SET( SAMRAI_USE_RAJA TRUE )
        ENDIF()
        IF ( NOT DEFINED SAMRAI_USE_UMPIRE )
            SET( SAMRAI_USE_UMPIRE TRUE )
        ENDIF()
    ENDIF()
    IF ( SAMRAI_USE_HIP )
        MESSAGE( "Enabling HIP support for SAMRAI" )
        IF ( SAMRAI_HIP_ARCH_FLAGS )
             SET( SAMRAI_CONFIGURE_OPTIONS ${SAMRAI_CONFIGURE_OPTIONS} -DENABLE_HIP=ON -DHIP_ARCH=${SAMRAI_HIP_ARCH_FLAGS} )
        ELSE()
             SET( SAMRAI_CONFIGURE_OPTIONS ${SAMRAI_CONFIGURE_OPTIONS} -DENABLE_HIP=ON -DHIP_ARCH=${HIP_ARCH_FLAGS} )
        ENDIF()
        IF ( NOT DEFINED SAMRAI_USE_RAJA )
            SET( SAMRAI_USE_RAJA TRUE )
        ENDIF()
        IF ( NOT DEFINED SAMRAI_USE_UMPIRE )
            SET( SAMRAI_USE_UMPIRE TRUE )
        ENDIF()
    ENDIF()
    IF ( SAMRAI_USE_OPENMP )
        MESSAGE( "Enabling OpenMP support for SAMRAI" )
        SET( SAMRAI_CONFIGURE_OPTIONS ${SAMRAI_CONFIGURE_OPTIONS} -DENABLE_OPENMP=ON )
    ELSE()
        SET( SAMRAI_CONFIGURE_OPTIONS ${SAMRAI_CONFIGURE_OPTIONS} -DENABLE_OPENMP=OFF )
    ENDIF()
    IF ( SAMRAI_USE_UMPIRE )
        MESSAGE( "Building SAMRAI with Umpire support" )
        SET( SAMRAI_CONFIGURE_OPTIONS ${SAMRAI_CONFIGURE_OPTIONS} -DENABLE_UMPIRE=ON  )
    ELSE()
        SET( SAMRAI_CONFIGURE_OPTIONS ${SAMRAI_CONFIGURE_OPTIONS} -DENABLE_UMPIRE=OFF  )
    ENDIF()
    IF ( SAMRAI_USE_UMPIRE AND SAMRAI_USE_RAJA )
        MESSAGE( "Building SAMRAI with RAJA support" )
        SET( SAMRAI_CONFIGURE_OPTIONS ${SAMRAI_CONFIGURE_OPTIONS} -DENABLE_RAJA=ON  )
    ELSE()
        SET( SAMRAI_CONFIGURE_OPTIONS ${SAMRAI_CONFIGURE_OPTIONS} -DENABLE_RAJA=OFF  )
    ENDIF()
    IF ( USE_MPI )
        SET( SAMRAI_CONFIGURE_OPTIONS ${SAMRAI_CONFIGURE_OPTIONS} -DENABLE_MPI=ON )
    ELSE()
        SET( SAMRAI_CONFIGURE_OPTIONS ${SAMRAI_CONFIGURE_OPTIONS} -DENABLE_MPI=OFF )
    ENDIF()
    IF ( HDF5_INSTALL_DIR )
        SET( ENV{HDF5_ROOT} "${HDF5_INSTALL_DIR}" )
        SET( SAMRAI_CONFIGURE_OPTIONS ${SAMRAI_CONFIGURE_OPTIONS} -DENABLE_HDF5=ON )
        SET( SAMRAI_CONFIGURE_OPTIONS ${SAMRAI_CONFIGURE_OPTIONS} -DHDF5_DIR=${HDF5_INSTALL_DIR} )
        SET( SAMRAI_CONFIGURE_OPTIONS ${SAMRAI_CONFIGURE_OPTIONS} -DHDF5_ROOT=${HDF5_INSTALL_DIR} )
    ELSE()
        SET( SAMRAI_CONFIGURE_OPTIONS ${SAMRAI_CONFIGURE_OPTIONS} -DENABLE_HDF5=OFF )
    ENDIF()
    LIST(FIND TPL_LIST "TIMER" index)
    SET( SAMRAI_CONFIGURE_OPTIONS ${SAMRAI_CONFIGURE_OPTIONS} -DENABLE_CPPCHECK=OFF )
    SET( SAMRAI_CONFIGURE_OPTIONS ${SAMRAI_CONFIGURE_OPTIONS} -DENABLE_HYPRE=OFF )
    SET( SAMRAI_CONFIGURE_OPTIONS ${SAMRAI_CONFIGURE_OPTIONS} -DENABLE_PETSC=OFF )
    SET( SAMRAI_CONFIGURE_OPTIONS ${SAMRAI_CONFIGURE_OPTIONS} -DENABLE_SILO=OFF )
    SET( SAMRAI_CONFIGURE_OPTIONS ${SAMRAI_CONFIGURE_OPTIONS} -DENABLE_SUNDIALS=OFF )
    SET( SAMRAI_CONFIGURE_OPTIONS ${SAMRAI_CONFIGURE_OPTIONS} -DENABLE_CONDUIT=OFF )
    # Enable the tests
    IF ( DEFINED SAMRAI_TEST )
        MESSAGE( WARNING "SAMRAI_TEST is deprecated, use SAMRAI_ENABLE_TESTS" )
    ENDIF()
    IF ( ( ENABLE_ALL_TESTS OR SAMRAI_ENABLE_TESTS ) AND NOT DISABLE_ALL_TESTS )
        SET( SAMRAI_CONFIGURE_OPTIONS ${SAMRAI_CONFIGURE_OPTIONS} -DENABLE_SAMRAI_TESTS=ON )
    ELSE()
        SET( SAMRAI_CONFIGURE_OPTIONS ${SAMRAI_CONFIGURE_OPTIONS} -DENABLE_SAMRAI_TESTS=OFF )
    ENDIF()
    IF ( SAMRAI_TOOLS )
        SET( SAMRAI_CONFIGURE_OPTIONS ${SAMRAI_CONFIGURE_OPTIONS} -DENABLE_TOOLS=ON )
    ELSE()
        SET( SAMRAI_CONFIGURE_OPTIONS ${SAMRAI_CONFIGURE_OPTIONS} -DENABLE_TOOLS=OFF )
    ENDIF()
    # Enable the docs
    CHECK_ENABLE_FLAG( SAMRAI_DOCS 0 )
    IF ( SAMRAI_DOCS )
        SET( SAMRAI_CONFIGURE_OPTIONS ${SAMRAI_CONFIGURE_OPTIONS} -DENABLE_DOCS=ON )
    ELSE()
        SET( SAMRAI_CONFIGURE_OPTIONS ${SAMRAI_CONFIGURE_OPTIONS} -DENABLE_DOCS=OFF )
    ENDIF()
    MESSAGE("   SAMRAI configure options: ${SAMRAI_CONFIGURE_OPTIONS}")

    # Build samrai
    SET( SAMRAI_CMAKE_TEST )
    SET( SAMRAI_DOC_COMMAND )
    IF ( ( ENABLE_ALL_TESTS OR SAMRAI_ENABLE_TESTS ) AND NOT DISABLE_ALL_TESTS )
        SET( SAMRAI_CMAKE_TEST
            TEST_AFTER_INSTALL  1
            TEST_COMMAND        $(MAKE) check
            BUILD_TEST          $(MAKE) checkcompile
            CHECK_TEST          ! grep "FAILED" SAMRAI-test-out.log > /dev/null
        )
    ENDIF()
    IF ( SAMRAI_DOCS )
        SET( SAMRAI_DOC_COMMAND
            DOC_COMMAND         $(MAKE) docs VERBOSE=1
            COMMAND             ${CMAKE_COMMAND} -E copy_directory docs/samrai-dox/html "${SAMRAI_INSTALL_DIR}/doxygen"
        )
    ENDIF()
    ADD_TPL(
        SAMRAI
        URL                 "${SAMRAI_CMAKE_URL}"
        DOWNLOAD_DIR        "${SAMRAI_CMAKE_DOWNLOAD_DIR}"
        SOURCE_DIR          "${SAMRAI_CMAKE_SOURCE_DIR}"
        UPDATE_COMMAND      ""
        CMAKE_ARGS          ${SAMRAI_CONFIGURE_OPTIONS}
        PREFIX_PATH         ${UMPIRE_INSTALL_DIR} ${RAJA_INSTALL_DIR}
        BUILD_COMMAND       $(MAKE) VERBOSE=1
        BUILD_IN_SOURCE     0
        INSTALL_COMMAND     $(MAKE) install
        ${SAMRAI_DOC_COMMAND}
        ${SAMRAI_CMAKE_TEST}
        CLEAN_COMMAND       $(MAKE) clean
        LOG_DOWNLOAD 1   LOG_UPDATE 1   LOG_CONFIGURE 1   LOG_BUILD 1   LOG_TEST 1   LOG_INSTALL 1
    )

ELSE()
    ADD_TPL_EMPTY( SAMRAI )
ENDIF()
# Add the appropriate fields to FindTPLs.cmake
FILE( APPEND "${FIND_TPLS_CMAKE}" "\n# Find SAMRAI\n" )
FILE( APPEND "${FIND_TPLS_CMAKE}" "IF ( TPLs_FIND_SAMRAI AND NOT TPLs_SAMRAI_FOUND )\n" )
FILE( APPEND "${FIND_TPLS_CMAKE}" "    SET( SAMRAI_DIR \"${SAMRAI_INSTALL_DIR}\" )\n" )
FILE( APPEND "${FIND_TPLS_CMAKE}" "    SET( SAMRAI_DIRECTORY \"${SAMRAI_INSTALL_DIR}\" )\n" )
FILE( APPEND "${FIND_TPLS_CMAKE}" "    SET( SAMRAI_INCLUDE \"${SAMRAI_INSTALL_DIR}/include\" )\n" )
FILE( APPEND "${FIND_TPLS_CMAKE}" "    SET( SAMRAI_LIB_DIR \"${SAMRAI_INSTALL_DIR}/lib\" )\n" )
FILE( APPEND "${FIND_TPLS_CMAKE}" "    SET( CMAKE_INSTALL_RPATH $\{CMAKE_INSTALL_RPATH} \"$\{SAMRAI_LIB_DIR}\" )\n" )
FILE( APPEND "${FIND_TPLS_CMAKE}" "    FIND_LIBRARY( SAMRAI_ALGS_LIB  NAMES SAMRAI_algs  PATHS $\{SAMRAI_LIB_DIR}  NO_DEFAULT_PATH )\n" )
FILE( APPEND "${FIND_TPLS_CMAKE}" "    FIND_LIBRARY( SAMRAI_APPU_LIB  NAMES SAMRAI_appu  PATHS $\{SAMRAI_LIB_DIR}  NO_DEFAULT_PATH )\n" )
FILE( APPEND "${FIND_TPLS_CMAKE}" "    FIND_LIBRARY( SAMRAI_GEOM_LIB  NAMES SAMRAI_geom  PATHS $\{SAMRAI_LIB_DIR}  NO_DEFAULT_PATH )\n" )
FILE( APPEND "${FIND_TPLS_CMAKE}" "    FIND_LIBRARY( SAMRAI_HIER_LIB  NAMES SAMRAI_hier  PATHS $\{SAMRAI_LIB_DIR}  NO_DEFAULT_PATH )\n" )
FILE( APPEND "${FIND_TPLS_CMAKE}" "    FIND_LIBRARY( SAMRAI_MATH_LIB  NAMES SAMRAI_math  PATHS $\{SAMRAI_LIB_DIR}  NO_DEFAULT_PATH )\n" )
FILE( APPEND "${FIND_TPLS_CMAKE}" "    FIND_LIBRARY( SAMRAI_MESH_LIB  NAMES SAMRAI_mesh  PATHS $\{SAMRAI_LIB_DIR}  NO_DEFAULT_PATH )\n" )
FILE( APPEND "${FIND_TPLS_CMAKE}" "    FIND_LIBRARY( SAMRAI_PDAT_LIB  NAMES SAMRAI_pdat  PATHS $\{SAMRAI_LIB_DIR}  NO_DEFAULT_PATH )\n" )
FILE( APPEND "${FIND_TPLS_CMAKE}" "    FIND_LIBRARY( SAMRAI_SOLV_LIB  NAMES SAMRAI_solv  PATHS $\{SAMRAI_LIB_DIR}  NO_DEFAULT_PATH )\n" )
FILE( APPEND "${FIND_TPLS_CMAKE}" "    FIND_LIBRARY( SAMRAI_TBOX_LIB  NAMES SAMRAI_tbox  PATHS $\{SAMRAI_LIB_DIR}  NO_DEFAULT_PATH )\n" )
FILE( APPEND "${FIND_TPLS_CMAKE}" "    FIND_LIBRARY( SAMRAI_XFER_LIB  NAMES SAMRAI_xfer  PATHS $\{SAMRAI_LIB_DIR}  NO_DEFAULT_PATH )\n" )
FILE( APPEND "${FIND_TPLS_CMAKE}" "    SET ( SAMRAI_LIBS $\{SAMRAI_APPU_LIB} $\{SAMRAI_ALGS_LIB} $\{SAMRAI_SOLV_LIB} $\{SAMRAI_GEOM_LIB} $\{SAMRAI_MESH_LIB} $\{SAMRAI_MATH_LIB} $\{SAMRAI_PDAT_LIB} $\{SAMRAI_XFER_LIB} $\{SAMRAI_HIER_LIB} $\{SAMRAI_TBOX_LIB} )\n" )
FILE( APPEND "${FIND_TPLS_CMAKE}" "    IF ( (NOT SAMRAI_APPU_LIB) OR (NOT SAMRAI_ALGS_LIB) OR (NOT SAMRAI_SOLV_LIB) OR (NOT SAMRAI_GEOM_LIB) OR \n" )
FILE( APPEND "${FIND_TPLS_CMAKE}" "        (NOT SAMRAI_MESH_LIB) OR (NOT SAMRAI_MATH_LIB) OR (NOT SAMRAI_PDAT_LIB) OR (NOT SAMRAI_XFER_LIB) OR \n" )
FILE( APPEND "${FIND_TPLS_CMAKE}" "        (NOT SAMRAI_HIER_LIB) OR (NOT SAMRAI_TBOX_LIB) )\n" )
FILE( APPEND "${FIND_TPLS_CMAKE}" "        MESSAGE( FATAL_ERROR \"SAMRAI contribution libraries not found in $\{SAMRAI_LIB_DIR}\" )\n" )
FILE( APPEND "${FIND_TPLS_CMAKE}" "    ENDIF()\n" )
FILE( APPEND "${FIND_TPLS_CMAKE}" "    SET( SAMRAI_FORTDIR $\{SAMRAI_DIRECTORY}/include )\n" )
FILE( APPEND "${FIND_TPLS_CMAKE}" "    ADD_TPL_LIBRARY( SAMRAI $\{SAMRAI_LIBS} )\n" )
FILE( APPEND "${FIND_TPLS_CMAKE}" "ENDIF()\n" )
FILE( APPEND "${FIND_TPLS_CMAKE}" "\n" )



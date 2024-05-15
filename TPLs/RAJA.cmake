# This will configure and build RAJA
# User can configure the source path by specifying RAJA_SRC_DIR,
#    the download path by specifying RAJA_URL, or the installed 
#    location by specifying RAJA_INSTALL_DIR


# Intialize download/src/install vars
SET( RAJA_BUILD_DIR "${CMAKE_BINARY_DIR}/RAJA-prefix/src/RAJA-build" )
IF ( RAJA_URL ) 
    MESSAGE("   RAJA_URL = ${RAJA_URL}")
    SET( RAJA_SRC_DIR "${CMAKE_BINARY_DIR}/RAJA-prefix/src/RAJA-src" )
    SET( RAJA_CMAKE_URL            "${RAJA_URL}"       )
    SET( RAJA_CMAKE_DOWNLOAD_DIR   "${RAJA_SRC_DIR}" )
    SET( RAJA_CMAKE_SOURCE_DIR     "${RAJA_SRC_DIR}" )
    SET( RAJA_CMAKE_INSTALL_DIR "${CMAKE_INSTALL_PREFIX}/RAJA" )
    SET( CMAKE_BUILD_RAJA TRUE )
ELSEIF ( RAJA_SRC_DIR )
    VERIFY_PATH("${RAJA_SRC_DIR}")
    MESSAGE("   RAJA_SRC_DIR = ${RAJA_SRC_DIR}")
    SET( RAJA_CMAKE_URL            ""   )
    SET( RAJA_CMAKE_DOWNLOAD_DIR   "" )
    SET( RAJA_CMAKE_SOURCE_DIR     "${RAJA_SRC_DIR}" )
    SET( RAJA_CMAKE_INSTALL_DIR "${CMAKE_INSTALL_PREFIX}/RAJA" )
    SET( CMAKE_BUILD_RAJA TRUE )
ELSEIF ( RAJA_INSTALL_DIR ) 
    SET( RAJA_CMAKE_INSTALL_DIR "${RAJA_INSTALL_DIR}" )
    SET( CMAKE_BUILD_RAJA FALSE )
ELSE()
    MESSAGE(FATAL_ERROR "Please specify RAJA_SRC_DIR, RAJA_URL, or RAJA_INSTALL_DIR")
ENDIF()
SET( RAJA_INSTALL_DIR "${RAJA_CMAKE_INSTALL_DIR}" )
MESSAGE( "   RAJA_INSTALL_DIR = ${RAJA_INSTALL_DIR}" )


# Configure RAJA
IF ( NOT DEFINED RAJA_USE_CUDA )
    SET( RAJA_USE_CUDA ${USE_CUDA} )
ENDIF()
IF ( NOT DEFINED RAJA_USE_HIP )
    SET( RAJA_USE_HIP ${USE_HIP} )
ENDIF()
IF ( NOT DEFINED RAJA_USE_OPENMP )
    SET( RAJA_USE_OPENMP ${USE_OPENMP} )
ENDIF()
IF ( CMAKE_BUILD_RAJA )
    # Include the configure file
    SET( RAJA_CONFIGURE_OPTIONS
        ${CMAKE_ARGS}
        -DCMAKE_INSTALL_PREFIX=${RAJA_CMAKE_INSTALL_DIR}
    )
    SET( RAJA_CONFIGURE_OPTIONS ${RAJA_CONFIGURE_OPTIONS} -DCMAKE_BUILD_TYPE=${CMAKE_BUILD_TYPE} )
    SET( RAJA_CONFIGURE_OPTIONS ${RAJA_CONFIGURE_OPTIONS}  -DENABLE_EXAMPLES=OFF -DENABLE_BENCHMARKS=OFF -DENABLE_TESTS=OFF )
    IF ( USE_MPI )
        SET( RAJA_CONFIGURE_OPTS ${RAJA_CONFIGURE_OPTIONS} -DENABLE_MPI=ON )
    ELSE()
        SET( RAJA_CONFIGURE_OPTS ${RAJA_CONFIGURE_OPTIONS} -DENABLE_MPI=OFF )
    ENDIF()
     IF ( RAJA_USE_OPENMP )
        MESSAGE( "Enabling OpenMP support for RAJA" )
        SET( RAJA_CONFIGURE_OPTIONS ${RAJA_CONFIGURE_OPTIONS} -DENABLE_OPENMP=ON )
    ELSE()
        SET( RAJA_CONFIGURE_OPTIONS ${RAJA_CONFIGURE_OPTIONS} -DENABLE_OPENMP=OFF )
    ENDIF()
    IF ( RAJA_USE_CUDA )
        MESSAGE( "Enabling CUDA support for RAJA" )
        IF ( RAJA_CUDA_ARCH_FLAGS )
             SET( RAJA_CONFIGURE_OPTIONS ${RAJA_CONFIGURE_OPTIONS} -DENABLE_CUDA=ON -DCUDA_ARCH=${RAJA_CUDA_ARCH_FLAGS} )
        ELSE()
             SET( RAJA_CONFIGURE_OPTIONS ${RAJA_CONFIGURE_OPTIONS} -DENABLE_CUDA=ON -DCUDA_ARCH=${CUDA_ARCH_FLAGS} )
        ENDIF()
        # Set more options
        # On Cray's Raja still seems to get confused about CUB (note we will probably fail with cuda < 11.0)
        SET( RAJA_CONFIGURE_OPTIONS ${RAJA_CONFIGURE_OPTIONS} -DRAJA_ENABLE_EXTERNAL_CUB=ON )
        SET( RAJA_CONFIGURE_OPTIONS ${RAJA_CONFIGURE_OPTIONS} -DCMAKE_CXX_COMPILER=${CMAKE_CXX_COMPILER} )
        MESSAGE("   RAJA configured with cuda:")
    ELSE()
        SET( RAJA_CONFIGURE_OPTIONS ${RAJA_CONFIGURE_OPTIONS} -DENABLE_CUDA=OFF )
        SET( RAJA_CONFIGURE_OPTIONS ${RAJA_CONFIGURE_OPTIONS} -DCMAKE_CXX_COMPILER=${CMAKE_CXX_COMPILER} )
        MESSAGE("   RAJA configured without cuda")
    ENDIF()
    IF ( RAJA_USE_HIP )
        MESSAGE( "Enabling HIP support for RAJA" )
        IF ( RAJA_HIP_ARCH_FLAGS )
             SET( RAJA_CONFIGURE_OPTIONS ${RAJA_CONFIGURE_OPTIONS} -DENABLE_HIP=ON -DHIP_ARCH=${RAJA_HIP_ARCH_FLAGS} )
        ELSE()
             SET( RAJA_CONFIGURE_OPTIONS ${RAJA_CONFIGURE_OPTIONS} -DENABLE_HIP=ON -DHIP_ARCH=${HIP_ARCH_FLAGS} )
        ENDIF()
        # Set more options
        # RAJA doesn't need an external cub or external rocprim with c++17
        SET( RAJA_CONFIGURE_OPTIONS ${RAJA_CONFIGURE_OPTIONS} -DCMAKE_CXX_COMPILER=${CMAKE_CXX_COMPILER} )
        MESSAGE("   RAJA configured with cuda:")
    ELSE()
        SET( RAJA_CONFIGURE_OPTIONS ${RAJA_CONFIGURE_OPTIONS} -DENABLE_HIP=OFF )
        SET( RAJA_CONFIGURE_OPTIONS ${RAJA_CONFIGURE_OPTIONS} -DCMAKE_CXX_COMPILER=${CMAKE_CXX_COMPILER} )
        MESSAGE("   RAJA configured without cuda")
    ENDIF()
    IF ( ENABLE_SHARED AND ENABLE_STATIC )
        MESSAGE(FATAL_ERROR "Compiling RAJA with both static and shared libraries is not yet supported")
    ELSEIF ( ENABLE_SHARED )
        SET( RAJA_CONFIGURE_OPTIONS ${RAJA_CONFIGURE_OPTIONS} )
    ELSEIF ( ENABLE_STATIC )
        SET( RAJA_CONFIGURE_OPTIONS ${RAJA_CONFIGURE_OPTIONS} )
    ENDIF()
    MESSAGE("   RAJA configure options: ${RAJA_CONFIGURE_OPTIONS}")
ENDIF()


# Build RAJA
IF ( CMAKE_BUILD_RAJA )
    ADD_TPL( 
        RAJA
        URL                 "${RAJA_CMAKE_URL}"
        DOWNLOAD_DIR        "${RAJA_CMAKE_DOWNLOAD_DIR}"
        SOURCE_DIR          "${RAJA_CMAKE_SOURCE_DIR}"
        UPDATE_COMMAND      ""
        CMAKE_ARGS          ${RAJA_CONFIGURE_OPTIONS}
        BUILD_COMMAND       $(MAKE) VERBOSE=1
        BUILD_IN_SOURCE     0
        INSTALL_COMMAND     $(MAKE) install; 
        LOG_DOWNLOAD 1   LOG_UPDATE 1   LOG_CONFIGURE 1   LOG_BUILD 1   LOG_TEST 1   LOG_INSTALL 1
    )
ELSE()
    ADD_TPL_EMPTY( RAJA )
ENDIF()


# Add the appropriate fields to FindTPLs.cmake
FILE( APPEND "${FIND_TPLS_CMAKE}" "\n# Find RAJA\n" )
FILE( APPEND "${FIND_TPLS_CMAKE}" "IF ( TPLs_FIND_RAJA AND NOT TPL_FOUND_RAJA )\n" )
FILE( APPEND "${FIND_TPLS_CMAKE}" "    SET( RAJA_DIR \"${RAJA_INSTALL_DIR}\" )\n" )
FILE( APPEND "${FIND_TPLS_CMAKE}" "    SET( RAJA_DIRECTORY \"${RAJA_INSTALL_DIR}\" )\n" )
FILE( APPEND "${FIND_TPLS_CMAKE}" "    SET( RAJA_INCLUDE \"${RAJA_INSTALL_DIR}/include\" )\n" )
FILE( APPEND "${FIND_TPLS_CMAKE}" "    FIND_LIBRARY( RAJA_LIB  NAMES RAJA  PATHS \"$\{RAJA_DIRECTORY}/lib\"  NO_DEFAULT_PATH )\n" )
FILE( APPEND "${FIND_TPLS_CMAKE}" "    IF ( NOT RAJA_LIB )\n" )
FILE( APPEND "${FIND_TPLS_CMAKE}" "        MESSAGE(FATAL_ERROR \"RAJA library not found in $\{RAJA_DIRECTORY}/lib\")\n" )
FILE( APPEND "${FIND_TPLS_CMAKE}" "    ENDIF()\n" )
FILE( APPEND "${FIND_TPLS_CMAKE}" "    SET( CMAKE_CXX_FLAGS \"$\{CMAKE_CXX_FLAGS} -Wno-unused-parameter -fopenmp\" )\n" )
FILE( APPEND "${FIND_TPLS_CMAKE}" "    SET( TPL_INCLUDE_DIRS $\{TPL_INCLUDE_DIRS} $\{RAJA_INCLUDE} )\n" )
FILE( APPEND "${FIND_TPLS_CMAKE}" "    SET( TPL_LIBRARIES $\{RAJA_LIB} $\{TPL_LIBRARIES} )\n" )
FILE( APPEND "${FIND_TPLS_CMAKE}" "    SET( RAJA_FOUND TRUE )\n" )
FILE( APPEND "${FIND_TPLS_CMAKE}" "    SET( TPL_FOUND_RAJA TRUE )\n" )
FILE( APPEND "${FIND_TPLS_CMAKE}" "ENDIF()\n" )
FILE( APPEND "${FIND_TPLS_CMAKE}" "\n" )


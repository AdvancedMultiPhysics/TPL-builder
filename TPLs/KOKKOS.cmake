# This will configure and build kokkos
# User can configure the source path by specifying KOKKOS_SRC_DIR,
#    the download path by specifying KOKKOS_URL, or the installed 
#    location by specifying KOKKOS_INSTALL_DIR


# Intialize download/src/install vars
SET( KOKKOS_BUILD_DIR "${CMAKE_BINARY_DIR}/KOKKOS-prefix/src/KOKKOS-build" )
IF ( KOKKOS_URL ) 
    MESSAGE("   KOKKOS_URL = ${KOKKOS_URL}")
    SET( KOKKOS_SRC_DIR "${CMAKE_BINARY_DIR}/KOKKOS-prefix/src/KOKKOS-src" )
    SET( KOKKOS_CMAKE_URL            "${KOKKOS_URL}"       )
    SET( KOKKOS_CMAKE_DOWNLOAD_DIR   "${KOKKOS_SRC_DIR}" )
    SET( KOKKOS_CMAKE_SOURCE_DIR     "${KOKKOS_SRC_DIR}" )
    SET( KOKKOS_CMAKE_INSTALL_DIR "${CMAKE_INSTALL_PREFIX}/kokkos" )
    SET( CMAKE_BUILD_KOKKOS TRUE )
ELSEIF ( KOKKOS_SRC_DIR )
    VERIFY_PATH("${KOKKOS_SRC_DIR}")
    MESSAGE("   KOKKOS_SRC_DIR = ${KOKKOS_SRC_DIR}")
    SET( KOKKOS_CMAKE_URL            ""   )
    SET( KOKKOS_CMAKE_DOWNLOAD_DIR   "" )
    SET( KOKKOS_CMAKE_SOURCE_DIR     "${KOKKOS_SRC_DIR}" )
    SET( KOKKOS_CMAKE_INSTALL_DIR "${CMAKE_INSTALL_PREFIX}/kokkos" )
    SET( CMAKE_BUILD_KOKKOS TRUE )
ELSEIF ( KOKKOS_INSTALL_DIR ) 
    SET( KOKKOS_CMAKE_INSTALL_DIR "${KOKKOS_INSTALL_DIR}" )
    SET( CMAKE_BUILD_KOKKOS FALSE )
ELSE()
    MESSAGE(FATAL_ERROR "Please specify KOKKOS_SRC_DIR, KOKKOS_URL, or KOKKOS_INSTALL_DIR")
ENDIF()
SET( KOKKOS_INSTALL_DIR "${KOKKOS_CMAKE_INSTALL_DIR}" )
MESSAGE( "   KOKKOS_INSTALL_DIR = ${KOKKOS_INSTALL_DIR}" )


# Configure kokkos
IF ( NOT DEFINED KOKKOS_USE_CUDA )
    SET( KOKKOS_USE_CUDA ${USE_CUDA} )
ENDIF()
IF ( NOT DEFINED KOKKOS_USE_OPENMP )
    SET( KOKKOS_USE_OPENMP ${USE_OPENMP} )
ENDIF()
IF ( NOT DEFINED KOKKOS_CXX_STD )
    SET( KOKKOS_CXX_STD ${CXX_STD} )
ENDIF()

IF ( CMAKE_BUILD_KOKKOS )
    SET( KOKKOS_CONFIGURE_OPTIONS -DCMAKE_INSTALL_PREFIX=${KOKKOS_CMAKE_INSTALL_DIR} )
    SET( KOKKOS_CONFIGURE_OPTIONS ${KOKKOS_CONFIGURE_OPTIONS} -DKokkos_CXX_STANDARD=${KOKKOS_CXX_STD} )
    SET( KOKKOS_CONFIGURE_OPTIONS ${KOKKOS_CONFIGURE_OPTIONS} -DCMAKE_BUILD_TYPE=${CMAKE_BUILD_TYPE} )
    SET( KOKKOS_CONFIGURE_OPTIONS ${KOKKOS_CONFIGURE_OPTIONS} -DKokkos_ENABLE_SERIAL=ON )
    IF ( KOKKOS_USE_OPENMP )
        SET( KOKKOS_CONFIGURE_OPTIONS ${KOKKOS_CONFIGURE_OPTIONS} -DKokkos_ENABLE_OPENMP=ON )
    ENDIF()
    IF ( KOKKOS_USE_CUDA )
        SET( KOKKOS_CONFIGURE_OPTIONS ${KOKKOS_CONFIGURE_OPTIONS} -DKokkos_ENABLE_CUDA=ON )
        IF ( NOT KOKKOS_CUDA_ARCH )
            SET( KOKKOS_CUDA_ARCH ${CUDA_ARCH} )
        ENDIF()
        IF ( NOT KOKKOS_HOST_COMPILER )
            SET( KOKKOS_HOST_COMPILER ${CMAKE_CXX_COMPILER} )
        ENDIF()
        IF ( KOKKOS_ARCH_FLAGS )
            SET( KOKKOS_CONFIGURE_OPTIONS ${KOKKOS_CONFIGURE_OPTIONS} ${KOKKOS_ARCH_FLAGS} )
        ENDIF()
        # Set more options
        SET( KOKKOS_CONFIGURE_OPTIONS ${KOKKOS_CONFIGURE_OPTIONS} -DCMAKE_CXX_COMPILER=${CMAKE_CXX_COMPILER} )
        #SET( KOKKOS_CONFIGURE_OPTIONS ${KOKKOS_CONFIGURE_OPTIONS} -DCMAKE_CXX_COMPILER=${KOKKOS_BUILD_DIR}/nvcc_wrapper )
        SET( KOKKOS_CONFIGURE_OPTIONS ${KOKKOS_CONFIGURE_OPTIONS} -DKokkos_USE_ATOMICS=OFF )
        SET( KOKKOS_CONFIGURE_OPTIONS ${KOKKOS_CONFIGURE_OPTIONS} -DKokkos_ENABLE_CUDA_LAMBDA=ON )
        SET( KOKKOS_CONFIGURE_OPTIONS ${KOKKOS_CONFIGURE_OPTIONS} -DKokkos_ENABLE_CUDA_CONSTEXPR=ON )
        MESSAGE("   KOKKOS configured with cuda:")
        MESSAGE("      KOKKOS_CUDA_ARCH=${KOKKOS_CUDA_ARCH}")
        MESSAGE("      KOKKOS_ARCH_FLAGS=${KOKKOS_ARCH_FLAGS}")
        MESSAGE("      KOKKOS_HOST_COMPILER=${KOKKOS_HOST_COMPILER}")
        MESSAGE("      KOKKOS_CUDA_CXX_FLAGS=${KOKKOS_CUDA_CXX_FLAGS}")
    ELSE()
        SET( KOKKOS_CONFIGURE_OPTIONS ${KOKKOS_CONFIGURE_OPTIONS} -DCMAKE_CXX_COMPILER=${CMAKE_CXX_COMPILER} )
        MESSAGE("   KOKKOS configured without cuda")
    ENDIF()
    IF ( ENABLE_SHARED AND ENABLE_STATIC )
        MESSAGE(FATAL_ERROR "Compiling kokkos with both static and shared libraries is not yet supported")
    ELSEIF ( ENABLE_SHARED )
        SET( KOKKOS_CONFIGURE_OPTIONS ${KOKKOS_CONFIGURE_OPTIONS} )
    ELSEIF ( ENABLE_STATIC )
        SET( KOKKOS_CONFIGURE_OPTIONS ${KOKKOS_CONFIGURE_OPTIONS} )
    ENDIF()
    MESSAGE("   KOKKOS configure options: ${KOKKOS_CONFIGURE_OPTIONS}")
ENDIF()


# Build kokkos
IF ( CMAKE_BUILD_KOKKOS )
    ADD_TPL( 
        KOKKOS
        URL                 "${KOKKOS_CMAKE_URL}"
        DOWNLOAD_DIR        "${KOKKOS_CMAKE_DOWNLOAD_DIR}"
        SOURCE_DIR          "${KOKKOS_CMAKE_SOURCE_DIR}"
        UPDATE_COMMAND      ""
        CMAKE_ARGS          ${KOKKOS_CONFIGURE_OPTIONS}
        BUILD_COMMAND       ${CMAKE_MAKE_PROGRAM} -j ${PROCS_INSTALL} VERBOSE=1
        BUILD_IN_SOURCE     0
        INSTALL_COMMAND     ${CMAKE_MAKE_PROGRAM} install; 
        DEPENDS             
        LOG_DOWNLOAD 1   LOG_UPDATE 1   LOG_CONFIGURE 1   LOG_BUILD 1   LOG_TEST 1   LOG_INSTALL 1
    )
    IF ( KOKKOS_USE_CUDA )
        CONFIGURE_FILE( "${CMAKE_CURRENT_LIST_DIR}/KOKKOS-nvcc.cmake" "${CMAKE_BINARY_DIR}/KOKKOS-prefix/src/KOKKOS-nvcc.cmake" @ONLY )
        EXTERNALPROJECT_ADD_STEP(
            KOKKOS
            create-nvcc_wrapper
            COMMENT             "Creating nvcc_wrapper"
            COMMAND             ${CMAKE_COMMAND} -P "${CMAKE_BINARY_DIR}/KOKKOS-prefix/src/KOKKOS-nvcc.cmake"
            COMMENT             ""
            DEPENDEES           download
            DEPENDERS           build
            WORKING_DIRECTORY   "${KOKKOS_BUILD_DIR}"
            LOG                 1
        )
        EXTERNALPROJECT_ADD_STEP(
            KOKKOS
            install-nvcc_wrapper
            COMMENT             "Installing nvcc_wrapper"
            COMMAND             ${CMAKE_COMMAND} -E copy "${KOKKOS_BUILD_DIR}/nvcc_wrapper" "${KOKKOS_INSTALL_DIR}/bin"
            COMMENT             ""
            DEPENDEES           install
            DEPENDERS           
            WORKING_DIRECTORY   "${KOKKOS_BUILD_DIR}"
            LOG                 1
        )
    ENDIF()
ELSE()
    ADD_TPL_EMPTY( KOKKOS )
ENDIF()

IF ( EXISTS "${KOKKOS_INSTALL_DIR}/lib64" )
  SET( KOKKOS_CMAKE_CONFIG_DIR "${KOKKOS_INSTALL_DIR}/lib64/cmake/Kokkos/" )
ELSE()
  SET( KOKKOS_CMAKE_CONFIG_DIR "${KOKKOS_INSTALL_DIR}/lib/cmake/Kokkos/" )
ENDIF()
MESSAGE( "KOKKOS_CMAKE_CONFIG_DIR ${KOKKOS_CMAKE_CONFIG_DIR}" )

# Add the appropriate fields to FindTPLs.cmake
FILE( APPEND "${FIND_TPLS_CMAKE}" "\n# Find KOKKOS\n" )
FILE( APPEND "${FIND_TPLS_CMAKE}" "IF ( TPLs_FIND_KOKKOS AND NOT TPL_FOUND_KOKKOS )\n" )
FILE( APPEND "${FIND_TPLS_CMAKE}" "    SET( KOKKOS_DIR \"${KOKKOS_INSTALL_DIR}\" )\n" )
FILE( APPEND "${FIND_TPLS_CMAKE}" "    SET( Kokkos_DIR \"${KOKKOS_CMAKE_CONFIG_DIR}\" )\n" )
FILE( APPEND "${FIND_TPLS_CMAKE}" "    SET( KOKKOS_DIRECTORY \"${KOKKOS_INSTALL_DIR}\" )\n" )
FILE( APPEND "${FIND_TPLS_CMAKE}" "    SET( KOKKOS_INCLUDE \"${KOKKOS_INSTALL_DIR}/include\" )\n" )
FILE( APPEND "${FIND_TPLS_CMAKE}" "    FIND_LIBRARY( KOKKOS_LIB  NAMES kokkoscore  PATHS \"$\{KOKKOS_DIRECTORY}/lib\" \"$\{KOKKOS_DIRECTORY}/lib64\"  NO_DEFAULT_PATH )\n" )
FILE( APPEND "${FIND_TPLS_CMAKE}" "    IF ( NOT KOKKOS_LIB )\n" )
FILE( APPEND "${FIND_TPLS_CMAKE}" "        MESSAGE(FATAL_ERROR \"kokkos library not found in $\{KOKKOS_DIRECTORY}/lib\")\n" )
FILE( APPEND "${FIND_TPLS_CMAKE}" "    ENDIF()\n" )
FILE( APPEND "${FIND_TPLS_CMAKE}" "    SET( CMAKE_CXX_FLAGS \"$\{CMAKE_CXX_FLAGS} -Wno-unused-parameter -fopenmp\" )\n" )
FILE( APPEND "${FIND_TPLS_CMAKE}" "    # IF ( EXISTS \"$\{KOKKOS_DIRECTORY}/nvcc_wrapper\" )\n" )
FILE( APPEND "${FIND_TPLS_CMAKE}" "    #    SET( CMAKE_CXX_COMPILER \"$\{KOKKOS_DIRECTORY}/nvcc_wrapper\" )\n" )
FILE( APPEND "${FIND_TPLS_CMAKE}" "    # ENDIF()\n" )
FILE( APPEND "${FIND_TPLS_CMAKE}" "    SET( TPL_INCLUDE_DIRS $\{TPL_INCLUDE_DIRS} $\{KOKKOS_INCLUDE} )\n" )
FILE( APPEND "${FIND_TPLS_CMAKE}" "    SET( TPL_LIBRARIES $\{KOKKOS_LIB} $\{TPL_LIBRARIES} )\n" )
FILE( APPEND "${FIND_TPLS_CMAKE}" "    SET( KOKKOS_FOUND TRUE )\n" )
FILE( APPEND "${FIND_TPLS_CMAKE}" "    SET( TPL_FOUND_KOKKOS TRUE )\n" )
FILE( APPEND "${FIND_TPLS_CMAKE}" "ENDIF()\n" )
FILE( APPEND "${FIND_TPLS_CMAKE}" "\n" )


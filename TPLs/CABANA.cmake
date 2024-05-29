# This will configure and build Cabana
# User can configure the source path by specifying CABANA_SRC_DIR,
#    the download path by specifying CABANA_URL, or the installed 
#    location by specifying CABANA_INSTALL_DIR


# Intialize download/src/install vars
SET( CABANA_BUILD_DIR "${CMAKE_BINARY_DIR}/CABANA-prefix/src/CABANA-build" )
IF ( CABANA_URL ) 
    MESSAGE("   CABANA_URL = ${CABANA_URL}")
    SET( CABANA_SRC_DIR "${CMAKE_BINARY_DIR}/CABANA-prefix/src/CABANA-src" )
    SET( CABANA_CMAKE_URL            "${CABANA_URL}"     )
    SET( CABANA_CMAKE_DOWNLOAD_DIR   "${CABANA_SRC_DIR}" )
    SET( CABANA_CMAKE_SOURCE_DIR     "${CABANA_SRC_DIR}" )
    SET( CABANA_CMAKE_INSTALL_DIR "${CMAKE_INSTALL_PREFIX}/cabana" )
    SET( CMAKE_BUILD_CABANA TRUE )
ELSEIF ( CABANA_SRC_DIR )
    VERIFY_PATH("${CABANA_SRC_DIR}")
    MESSAGE("   CABANA_SRC_DIR = ${CABANA_SRC_DIR}")
    SET( CABANA_CMAKE_URL            ""                  )
    SET( CABANA_CMAKE_DOWNLOAD_DIR   ""                  )
    SET( CABANA_CMAKE_SOURCE_DIR     "${CABANA_SRC_DIR}" )
    SET( CABANA_CMAKE_INSTALL_DIR "${CMAKE_INSTALL_PREFIX}/cabana" )
    SET( CMAKE_BUILD_CABANA TRUE )
ELSEIF ( CABANA_INSTALL_DIR ) 
    SET( CABANA_CMAKE_INSTALL_DIR "${CABANA_INSTALL_DIR}" )
    SET( CMAKE_BUILD_CABANA FALSE )
ELSE()
    MESSAGE(FATAL_ERROR "Please specify CABANA_SRC_DIR, CABANA_URL, or CABANA_INSTALL_DIR")
ENDIF()
SET( CABANA_INSTALL_DIR "${CABANA_CMAKE_INSTALL_DIR}" )
MESSAGE( "   CABANA_INSTALL_DIR = ${CABANA_INSTALL_DIR}" )


# Configure optional/required TPLs
CONFIGURE_DEPENDENCIES( CABANA OPTIONAL KOKKOS TRILINOS )


# Configure cabana
IF ( NOT DEFINED CABANA_USE_CUDA )
    SET( CABANA_USE_CUDA ${USE_CUDA} )
ENDIF()
IF ( NOT DEFINED CABANA_USE_OPENMP )
    SET( CABANA_USE_OPENMP ${USE_OPENMP} )
ENDIF()
IF ( CMAKE_BUILD_CABANA )

    # Include the configure file
    SET( CABANA_CONFIGURE_OPTS
        -DCMAKE_INSTALL_PREFIX=${CABANA_CMAKE_INSTALL_DIR}
    )
    IF ( NOT CABANA_VERSION )
        SET( CABANA_VERSION "0.0.0" )
    ENDIF()
    # Set third party library includes
    IF ( KOKKOS_INSTALL_DIR )
        MESSAGE( "Using standalone build of Kokkos")
    ELSEIF ( TRILINOS_INSTALL_DIR )
        SET( KOKKOS_INSTALL_DIR ${TRILINOS_INSTALL_DIR} )
        MESSAGE( "Using Trilinos build of Kokkos")
        MESSAGE( "Setting KOKKOS_INSTALL_DIR to ${KOKKOS_INSTALL_DIR}" )
    ELSE()
        MESSAGE(FATAL_ERROR "Please specify either Kokkos or Trilinos" )
    ENDIF()
    IF ( USE_MPI )
        SET( CABANA_CONFIGURE_OPTS ${CABANA_CONFIGURE_OPTS} -DCabana_ENABLE_MPI=ON )
        SET( CABANA_CONFIGURE_OPTS ${CABANA_CONFIGURE_OPTS} -DMPI_C_COMPILER=${MPI_C_COMPILER} )
        SET( CABANA_CONFIGURE_OPTS ${CABANA_CONFIGURE_OPTS} -DMPI_CXX_COMPILER=${MPI_CXX_COMPILER} )
        SET( CABANA_CONFIGURE_OPTS ${CABANA_CONFIGURE_OPTS} -DMPI_C_COMPILER_FLAGS=${MPI_C_COMPILER_FLAGS} )
        SET( CABANA_CONFIGURE_OPTS ${CABANA_CONFIGURE_OPTS} -DMPI_CXX_COMPILER_FLAGS=${MPI_CXX_COMPILER_FLAGS} )
    ELSE()
        SET( CABANA_CONFIGURE_OPTS ${CABANA_CONFIGURE_OPTS} -DCabana_ENABLE_MPI=OFF )
    ENDIF()
    IF ( KOKKOS_INSTALL_DIR )
       MESSAGE( "Kokkos installed at ${KOKKOS_INSTALL_DIR}")
       SET( CABANA_CONFIGURE_OPTS ${CABANA_CONFIGURE_OPTS} -DCMAKE_PREFIX_PATH=${KOKKOS_INSTALL_DIR} )
    ELSE()
       MESSAGE( "Kokkos dependency not installed!!" )
    ENDIF()
    SET( CABANA_CONFIGURE_OPTS ${CABANA_CONFIGURE_OPTS} -DCabana_ENABLE_EXAMPLES=ON )
    SET( CABANA_CONFIGURE_OPTS ${CABANA_CONFIGURE_OPTS} -DCabana_ENABLE_PERFORMANCE_TESTING=OFF )
    SET( CABANA_CONFIGURE_OPTS ${CABANA_CONFIGURE_OPTS} -DCabana_ENABLE_CAJITA=OFF )
    IF ( "${CABANA_VERSION}" VERSION_GREATER "0.5.0" )
        SET( CABANA_CONFIGURE_OPTS ${CABANA_CONFIGURE_OPTS} -DCabana_ENABLE_HDF5=OFF )
    ENDIF()  
    IF ( CABANA_USE_OPENMP )
        SET( CABANA_CONFIGURE_OPTS ${CABANA_CONFIGURE_OPTS} -DCabana_REQUIRE_OPENMP=ON )
    ENDIF()
    IF ( CABANA_USE_CUDA )
         SET( CABANA_CONFIGURE_OPTS ${CABANA_CONFIGURE_OPTS} -DCabana_REQUIRE_CUDA=ON )
         SET( CABANA_CONFIGURE_OPTS ${CABANA_CONFIGURE_OPTS} -DCMAKE_C_COMPILER=${CMAKE_C_COMPILER} )
         SET( CABANA_CONFIGURE_OPTS ${CABANA_CONFIGURE_OPTS} -DCMAKE_C_FLAGS=${DCMAKE_C_FLAGS} )
         SET( CABANA_CONFIGURE_OPTS ${CABANA_CONFIGURE_OPTS} -DCMAKE_CXX_COMPILER=${KOKKOS_INSTALL_DIR}/bin/nvcc_wrapper )
         SET( CABANA_CONFIGURE_OPTS ${CABANA_CONFIGURE_OPTS} -DCMAKE_CXX_FLAGS=${DCMAKE_CXX_FLAGS} )
    ELSE()
         SET( CABANA_CONFIGURE_OPTS ${CABANA_CONFIGURE_OPTS} -DCMAKE_C_COMPILER=${CMAKE_C_COMPILER} )   
         SET( CABANA_CONFIGURE_OPTS ${CABANA_CONFIGURE_OPTS} -DCMAKE_CXX_COMPILER=${CMAKE_CXX_COMPILER} )
         SET( CABANA_CONFIGURE_OPTS ${CABANA_CONFIGURE_OPTS} -DCMAKE_C_FLAGS=${DCMAKE_C_FLAGS} )
         SET( CABANA_CONFIGURE_OPTS ${CABANA_CONFIGURE_OPTS} -DCMAKE_CXX_FLAGS=${DCMAKE_CXX_FLAGS} )
    ENDIF()
    IF ( ( ENABLE_ALL_TESTS OR CABANA_ENABLE_TESTS ) AND NOT DISABLE_ALL_TESTS )
        SET( CABANA_CONFIGURE_OPTS ${CABANA_CONFIGURE_OPTS} -DCabana_ENABLE_TESTING=ON )
    ELSE()
        SET( CABANA_CONFIGURE_OPTS ${CABANA_CONFIGURE_OPTS} -DCabana_ENABLE_TESTING=OFF )
    ENDIF()
    # Enable the docs
    # CHECK_ENABLE_FLAG( CABANA_DOCS 0 )
    # IF ( CABANA_DOCS )
    #    SET( CABANA_CONFIGURE_OPTS ${CABANA_CONFIGURE_OPTS} -DENABLE_DOCS=ON )
    # ELSE()
    #    SET( CABANA_CONFIGURE_OPTS ${CABANA_CONFIGURE_OPTS} -DENABLE_DOCS=OFF )
    # ENDIF()
    MESSAGE("   CABANA configure options: ${CABANA_CONFIGURE_OPTS}")
ENDIF()


# Build Cabana
SET( CABANA_CMAKE_TEST )
SET( CABANA_DOC_COMMAND )
IF ( ( ENABLE_ALL_TESTS OR CABANA_ENABLE_TESTS ) AND NOT DISABLE_ALL_TESTS )
    SET( CABANA_CMAKE_TEST
        TEST_AFTER_INSTALL  1
        TEST_COMMAND        $(MAKE) check
        BUILD_TEST          $(MAKE) checkcompile
        CHECK_TEST          ! grep "FAILED" CABANA-test-out.log > /dev/null
    )
ENDIF()
#IF ( CABANA_DOCS )
#    SET( CABANA_DOC_COMMAND
#        DOC_COMMAND         $(MAKE) docs VERBOSE=1
#        COMMAND             ${CMAKE_COMMAND} -E copy_directory docs/cabana-dox/html "${CABANA_INSTALL_DIR}/doxygen"
#    )
#ENDIF()
IF ( CMAKE_BUILD_CABANA )

      ADD_TPL(
        CABANA
        URL                 "${CABANA_CMAKE_URL}"
        DOWNLOAD_DIR        "${CABANA_CMAKE_DOWNLOAD_DIR}"
        SOURCE_DIR          "${CABANA_CMAKE_SOURCE_DIR}"
        UPDATE_COMMAND      ""
        CMAKE_ARGS          ${CABANA_CONFIGURE_OPTS}
        BUILD_COMMAND       $(MAKE) VERBOSE=1
        BUILD_IN_SOURCE     0
        INSTALL_COMMAND     $(MAKE) install
        CLEAN_COMMAND       $(MAKE) clean
        ${CABANA_DOC_COMMAND}
        ${CABANA_CMAKE_TEST}
        LOG_DOWNLOAD 1   LOG_UPDATE 1   LOG_CONFIGURE 1   LOG_BUILD 1   LOG_TEST 1   LOG_INSTALL 1
    )

ELSE()
    ADD_TPL_EMPTY( CABANA )
ENDIF()
  
IF ( EXISTS "${CABANA_INSTALL_DIR}/lib64" )
  SET( CABANA_CMAKE_CONFIG_DIR "${CABANA_INSTALL_DIR}/lib64/cmake/Cabana/" )
ELSE()
  SET( CABANA_CMAKE_CONFIG_DIR "${CABANA_INSTALL_DIR}/lib/cmake/Cabana/" )
ENDIF()


# Add the appropriate fields to FindTPLs.cmake
FILE( APPEND "${FIND_TPLS_CMAKE}" "\n# Find CABANA\n" )
FILE( APPEND "${FIND_TPLS_CMAKE}" "IF ( TPLs_FIND_CABANA AND NOT TPLs_CABANA_FOUND )\n" )
FILE( APPEND "${FIND_TPLS_CMAKE}" "    SET( CABANA_DIR \"${CABANA_INSTALL_DIR}\" )\n" )
FILE( APPEND "${FIND_TPLS_CMAKE}" "    SET( Cabana_DIR \"${CABANA_CMAKE_CONFIG_DIR}\" )\n" )
FILE( APPEND "${FIND_TPLS_CMAKE}" "    SET( CABANA_DIRECTORY \"${CABANA_INSTALL_DIR}\" )\n" )
FILE( APPEND "${FIND_TPLS_CMAKE}" "    SET( CABANA_INCLUDE \"${CABANA_INSTALL_DIR}/include\" )\n" )
FILE( APPEND "${FIND_TPLS_CMAKE}" "    SET( CABANA_LIB_DIR \"${CABANA_INSTALL_DIR}/lib${LIB_SUFFIX}\" )\n" )
FILE( APPEND "${FIND_TPLS_CMAKE}" "    IF( \"${CABANA_VERSION}\" VERSION_LESS \"0.4.0\" )\n" )
FILE( APPEND "${FIND_TPLS_CMAKE}" "       FIND_LIBRARY( CABANA_CORE_LIB  NAMES cabanacore  PATHS \"$\{CABANA_DIRECTORY}/lib\" \"$\{CABANA_DIRECTORY}/lib64\" NO_DEFAULT_PATH )\n" )
FILE( APPEND "${FIND_TPLS_CMAKE}" "       SET ( CABANA_LIBS $\{CABANA_CORE_LIB} )\n" )
FILE( APPEND "${FIND_TPLS_CMAKE}" "       IF ( (NOT CABANA_CORE_LIB) )\n" )
FILE( APPEND "${FIND_TPLS_CMAKE}" "           MESSAGE( FATAL_ERROR \"CABANA contribution libraries not found in $\{CABANA_LIB_DIR}\" )\n" )
FILE( APPEND "${FIND_TPLS_CMAKE}" "       ENDIF()\n" )
FILE( APPEND "${FIND_TPLS_CMAKE}" "    ENDIF()\n" )
FILE( APPEND "${FIND_TPLS_CMAKE}" "    ADD_TPL_LIBRARY( CABANA $\{CABANA_LIBS} )\n" )
FILE( APPEND "${FIND_TPLS_CMAKE}" "ENDIF()\n" )
FILE( APPEND "${FIND_TPLS_CMAKE}" "\n" )



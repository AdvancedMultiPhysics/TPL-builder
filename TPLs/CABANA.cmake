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


# Configure cabana
IF ( CMAKE_BUILD_CABANA )

    # Include the configure file
    SET( CABANA_CONFIGURE_OPTS
        ${CMAKE_ARGS}
        -DCMAKE_INSTALL_PREFIX=${CMAKE_INSTALL_PREFIX}/cabana
    )
    # Set third party library includes
    SET( CABANA_DEPENDS KOKKOS )
    IF ( USE_MPI )
        SET( CABANA_CONFIGURE_OPTS ${CABANA_CONFIGURE_OPTS} -DCabana_ENABLE_MPI=ON )
    ELSE()
        SET( CABANA_CONFIGURE_OPTS ${CABANA_CONFIGURE_OPTS} -DCabana_ENABLE_MPI=OFF )
    ENDIF()
    IF ( KOKKOS_INSTALL_DIR )
       MESSAGE( "Kokkos installed at ${KOKKOS_INSTALL_DIR}")
       SET( CABANA_CONFIGURE_OPTS ${CABANA_CONFIGURE_OPTS} -DCMAKE_INSTALL_PREFIX=${KOKKOS_INSTALL_DIR} )
    ELSE()
       MESSAGE( "Kokkos dependency not installed!!" )
    ENDIF()
    SET( CABANA_CONFIGURE_OPTS ${CABANA_CONFIGURE_OPTS} -DCabana_REQUIRE_OPENMP=ON )
    SET( CABANA_CONFIGURE_OPTS ${CABANA_CONFIGURE_OPTS} -DCabana_ENABLE_EXAMPLES=ON )
    SET( CABANA_CONFIGURE_OPTS ${CABANA_CONFIGURE_OPTS} -DCabana_ENABLE_PERFORMANCE_TESTING=OFF )
    SET( CABANA_CONFIGURE_OPTS ${CABANA_CONFIGURE_OPTS} -DCabana_ENABLE_CAJITA=ON )
    IF ( CABANA_TEST )
        SET( CABANA_CONFIGURE_OPTS ${CABANA_CONFIGURE_OPTS} -DCabana_ENABLE_TESTING=ON )
    ELSE()
        SET( CABANA_CONFIGURE_OPTS ${CABANA_CONFIGURE_OPTS} -DCabana_ENABLE_TESTING=OFF )
    ENDIF()
    # Enable the docs
#    CHECK_ENABLE_FLAG( CABANA_DOCS 0 )
#    IF ( CABANA_DOCS )
#        SET( CABANA_CONFIGURE_OPTS ${CABANA_CONFIGURE_OPTS} -DENABLE_DOCS=ON )
#    ELSE()
#        SET( CABANA_CONFIGURE_OPTS ${CABANA_CONFIGURE_OPTS} -DENABLE_DOCS=OFF )
#    ENDIF()
     MESSAGE("   CABANA configure options: ${CABANA_CONFIGURE_OPTS}")
ENDIF()


# Build cabana
IF ( CMAKE_BUILD_CABANA )
    SET( CABANA_CMAKE_TEST )
    IF ( CABANA_TEST )
        SET( CABANA_CMAKE_TEST   TEST_AFTER_INSTALL 1   TEST_COMMAND make check )
    ENDIF()
    EXTERNALPROJECT_ADD(
        CABANA
        URL                 "${CABANA_CMAKE_URL}"
        DOWNLOAD_DIR        "${CABANA_CMAKE_DOWNLOAD_DIR}"
        SOURCE_DIR          "${CABANA_CMAKE_SOURCE_DIR}"
        UPDATE_COMMAND      ""
        CMAKE_ARGS          ${CABANA_CONFIGURE_OPTS}
        BUILD_COMMAND       make -j ${PROCS_INSTALL} VERBOSE=1
        BUILD_IN_SOURCE     0
        INSTALL_COMMAND     ${CMAKE_MAKE_PROGRAM} install
        ${CABANA_CMAKE_TEST}
        DEPENDS             ${CABANA_DEPENDS}
        LOG_DOWNLOAD 1   LOG_UPDATE 1   LOG_CONFIGURE 1   LOG_BUILD 1   LOG_TEST 1   LOG_INSTALL 1
    )
    SET( CABANA_CLEAN_DEPENDENCIES install )
    IF ( CABANA_TEST )
        EXTERNALPROJECT_ADD_STEP(
            CABANA
            build-test
            COMMENT             "Compiling tests"
            COMMAND             make checkcompile -j ${PROCS_INSTALL} 
            COMMENT             ""
            DEPENDEES           build
            DEPENDERS           test
            WORKING_DIRECTORY   "${CABANA_BUILD_DIR}"
            LOG                 1
        )
        EXTERNALPROJECT_ADD_STEP(
            CABANA
            check-test
            COMMENT             "Checking test results"
            COMMAND             ! grep "FAILED" CABANA-test-out.log > /dev/null 
            COMMENT             ""
            DEPENDEES           test
            WORKING_DIRECTORY   "${CMAKE_BINARY_DIR}/CABANA-prefix/src/CABANA-stamp"
            LOG                 0
        )
        SET( CABANA_CLEAN_DEPENDENCIES ${CABANA_CLEAN_DEPENDENCIES} check-test )
    ENDIF()
#    IF ( CABANA_DOCS )
#        EXTERNALPROJECT_ADD_STEP(
#            CABANA
#            build-docs
#            COMMENT             "Compiling documentation"
#            COMMAND             make docs -j ${PROCS_INSTALL} VERBOSE=1
#            COMMAND             ${CMAKE_COMMAND} -E copy_directory docs/cabana-dox/html "${CABANA_INSTALL_DIR}/doxygen"
#            COMMENT             ""
#            DEPENDEES           install
#            DEPENDERS           
#            WORKING_DIRECTORY   "${CABANA_BUILD_DIR}"
#            LOG                 1
#        )
#        SET( CABANA_CLEAN_DEPENDENCIES ${CABANA_CLEAN_DEPENDENCIES} build-docs )
#    ENDIF()
    EXTERNALPROJECT_ADD_STEP(
        CABANA
        clean
        COMMAND             make clean
        DEPENDEES           ${CABANA_CLEAN_DEPENDENCIES}
        WORKING_DIRECTORY   "${CABANA_BUILD_DIR}"
        LOG                 1
    )
    ADD_TPL_SAVE_LOGS( CABANA )
    ADD_TPL_CLEAN( CABANA )
ELSE()
    ADD_TPL_EMPTY( CABANA )
ENDIF()


# Add the appropriate fields to FindTPLs.cmake
FILE( APPEND "${FIND_TPLS_CMAKE}" "\n# Find CABANA\n" )
FILE( APPEND "${FIND_TPLS_CMAKE}" "IF ( TPLs_FIND_CABANA AND NOT TPL_FOUND_CABANA )\n" )
FILE( APPEND "${FIND_TPLS_CMAKE}" "    SET( CABANA_DIR \"${CABANA_INSTALL_DIR}\" )\n" )
FILE( APPEND "${FIND_TPLS_CMAKE}" "    SET( CABANA_DIRECTORY \"${CABANA_INSTALL_DIR}\" )\n" )
FILE( APPEND "${FIND_TPLS_CMAKE}" "    SET( CABANA_INCLUDE \"${CABANA_INSTALL_DIR}/include\" )\n" )
FILE( APPEND "${FIND_TPLS_CMAKE}" "    SET( CABANA_LIB_DIR \"${CABANA_INSTALL_DIR}/lib\" )\n" )
FILE( APPEND "${FIND_TPLS_CMAKE}" "    FIND_LIBRARY( CABANA_ALGS_LIB  NAMES CABANA_algs  PATHS $\{CABANA_LIB_DIR}  NO_DEFAULT_PATH )\n" )
FILE( APPEND "${FIND_TPLS_CMAKE}" "    SET ( CABANA_LIBS $\{CABANA_APPU_LIB} )\n" )
FILE( APPEND "${FIND_TPLS_CMAKE}" "    IF ( (NOT CABANA_APPU_LIB) )\n" )
FILE( APPEND "${FIND_TPLS_CMAKE}" "        MESSAGE( FATAL_ERROR \"CABANA contribution libraries not found in $\{CABANA_LIB_DIR}\" )\n" )
FILE( APPEND "${FIND_TPLS_CMAKE}" "    ENDIF()\n" )
FILE( APPEND "${FIND_TPLS_CMAKE}" "    SET( TPL_INCLUDE_DIRS $\{TPL_INCLUDE_DIRS} $\{CABANA_INCLUDE} )\n" )
FILE( APPEND "${FIND_TPLS_CMAKE}" "    SET( TPL_LIBRARIES $\{CABANA_LIBS} $\{TPL_LIBRARIES} )\n" )
FILE( APPEND "${FIND_TPLS_CMAKE}" "    SET( CABANA_FOUND TRUE )\n" )
FILE( APPEND "${FIND_TPLS_CMAKE}" "    SET( TPL_FOUND_CABANA TRUE )\n" )
FILE( APPEND "${FIND_TPLS_CMAKE}" "ENDIF()\n" )
FILE( APPEND "${FIND_TPLS_CMAKE}" "\n" )



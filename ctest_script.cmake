# ctest script for building, running, and submitting the test results 
# Usage:  ctest -S script,build
#   build = debug / optimized / weekly / valgrind / valgrind-matlab
# Note: this test will use use the number of processors defined in the variable N_PROCS,
#   the enviornmental variable N_PROCS, or the number of processors availible (if not specified)

# Macro to load an enviornmental variable
MACRO( LOAD_VAR VAR )
    SET( ${VAR} $ENV{${VAR}} )
ENDMACRO()
MACRO( LOAD_LIST VAR )
    SET( ${VAR} $ENV{${VAR}} )
    STRING( REPLACE "," ";" ${VAR} ${${VAR}} )
ENDMACRO()


# Set platform specific variables
SITE_NAME( HOSTNAME )
STRING(REGEX REPLACE "-ext."   "" HOSTNAME "${HOSTNAME}")
STRING(REGEX REPLACE "-login." "" HOSTNAME "${HOSTNAME}")
LOAD_VAR( USE_MPI )
LOAD_VAR( CC )
LOAD_VAR( CXX )
LOAD_VAR( FORTRAN )
LOAD_VAR( CFLAGS )
LOAD_VAR( CXXFLAGS )
LOAD_VAR( CXX_STD )
LOAD_VAR( FFLAGS )
LOAD_VAR( LDLIBS )
LOAD_VAR( LDFLAGS )
LOAD_VAR( ENABLE_STATIC )
LOAD_VAR( ENABLE_SHARED )
LOAD_VAR( INSTALL_DIR )
LOAD_VAR( MPIEXEC )
LOAD_VAR( CMAKE_MAKE_PROGRAM )
LOAD_VAR( CTEST_CMAKE_GENERATOR )
LOAD_VAR( LANGUAGES )
LOAD_VAR( CTEST_SITE )
LOAD_VAR( CTEST_URL )
LOAD_VAR( BUILD_SERIAL )
IF ( NOT CXX_STD )
    SET( CXX_STD 11 )
ENDIF()


# Get the list of projects
LOAD_LIST( TPL_LIST )
STRING( REPLACE ";" "," TPL_LIST2 "${TPL_LIST}" )


# For each TPL load default variables
FOREACH( tpl ${TPL_LIST} )
    LOAD_VAR( ${tpl}_URL )
    LOAD_VAR( ${tpl}_SRC_DIR )
    LOAD_VAR( ${tpl}_INSTALL_DIR )
ENDFOREACH()


# Load TPL specific flags
LOAD_VAR( BOOST_ONLY_COPY_HEADERS )
LOAD_VAR( AMP_DATA )
LOAD_VAR( BLAS_INSTALL_DIR)
LOAD_VAR( LAPACK_INSTALL_DIR )
LOAD_VAR( BLAS_LIB )
LOAD_VAR( LAPACK_LIB )
LOAD_VAR( TRILINOS_PACKAGES )
LOAD_VAR( TRILINOS_EXTRA_PACKAGES )
LOAD_VAR( TRILINOS_EXTRA_REPOSITORIES )
LOAD_VAR( TRILINOS_EXTRA_FLAGS )
LOAD_VAR( TRILINOS_EXTRA_FLAGS )
LOAD_VAR( TRILINOS_EXTRA_LINK_FLAGS )


# Get the source directory based on the current directory
IF ( NOT TPL_SOURCE_DIR )
    SET( TPL_SOURCE_DIR "${CMAKE_CURRENT_LIST_DIR}" )
ENDIF()
IF ( NOT CMAKE_MAKE_PROGRAM )
    SET( CMAKE_MAKE_PROGRAM make )
ENDIF()


# Check that we specified the build type to run
SET( RUN_WEEKLY FALSE )
IF( NOT CTEST_SCRIPT_ARG )
    MESSAGE(FATAL_ERROR "No build specified: ctest -S /path/to/script,build (debug/optimized/valgrind")
ELSEIF( ${CTEST_SCRIPT_ARG} STREQUAL "debug" )
    SET( CTEST_BUILD_NAME "TPL-debug" )
    SET( CMAKE_BUILD_TYPE "Debug" )
    SET( CTEST_COVERAGE_COMMAND ${COVERAGE_COMMAND} )
    SET( ENABLE_GCOV "true" )
    SET( USE_VALGRIND FALSE )
    SET( USE_VALGRIND_MATLAB FALSE )
ELSEIF( (${CTEST_SCRIPT_ARG} STREQUAL "optimized") OR (${CTEST_SCRIPT_ARG} STREQUAL "opt") )
    SET( CTEST_BUILD_NAME "TPL-opt" )
    SET( CMAKE_BUILD_TYPE "Release" )
    SET( CTEST_COVERAGE_COMMAND )
    SET( ENABLE_GCOV "false" )
    SET( USE_VALGRIND FALSE )
    SET( USE_VALGRIND_MATLAB FALSE )
ELSEIF( (${CTEST_SCRIPT_ARG} STREQUAL "weekly") )
    SET( CTEST_BUILD_NAME "TPL-Weekly" )
    SET( CMAKE_BUILD_TYPE "Release" )
    SET( CTEST_COVERAGE_COMMAND )
    SET( ENABLE_GCOV "false" )
    SET( USE_VALGRIND FALSE )
    SET( USE_VALGRIND_MATLAB FALSE )
    SET( RUN_WEEKLY TRUE )
ELSEIF( ${CTEST_SCRIPT_ARG} STREQUAL "valgrind" )
    SET( CTEST_BUILD_NAME "TPL-valgrind" )
    SET( CMAKE_BUILD_TYPE "Debug" )
    SET( CTEST_COVERAGE_COMMAND )
    SET( ENABLE_GCOV "false" )
    SET( USE_VALGRIND TRUE )
    SET( USE_VALGRIND_MATLAB FALSE )
    SET( USE_MATLAB 0 )
ELSEIF( ${CTEST_SCRIPT_ARG} STREQUAL "valgrind-matlab" )
    SET( CTEST_BUILD_NAME "TPL-valgrind-matlab" )
    SET( CMAKE_BUILD_TYPE "Debug" )
    SET( CTEST_COVERAGE_COMMAND )
    SET( ENABLE_GCOV "false" )
    SET( USE_VALGRIND FALSE )
    SET( USE_VALGRIND_MATLAB TRUE )
ELSE()
    MESSAGE(FATAL_ERROR "Invalid build (${CTEST_SCRIPT_ARG}): ctest -S /path/to/script,build (debug/opt/valgrind")
ENDIF()
SET( BUILDNAME_POSTFIX "$ENV{BUILDNAME_POSTFIX}" )
IF ( BUILDNAME_POSTFIX )
    SET( CTEST_BUILD_NAME "${CTEST_BUILD_NAME}-${BUILDNAME_POSTFIX}" )
ENDIF()
IF ( NOT COVERAGE_COMMAND )
    SET( ENABLE_GCOV "false" )
ENDIF()


# Set the number of processors
IF( NOT DEFINED N_PROCS )
    SET( N_PROCS $ENV{N_PROCS} )
ENDIF()
IF ( NOT DEFINED N_PROCS )
    SET(N_PROCS 1)
    # Linux:
    SET(cpuinfo_file "/proc/cpuinfo")
    IF(EXISTS "${cpuinfo_file}")
        FILE(STRINGS "${cpuinfo_file}" procs REGEX "^processor.: [0-9]+$")
        list(LENGTH procs N_PROCS)
    ENDIF()
    # Mac:
    IF(APPLE)
        find_program(cmd_sys_pro "system_profiler")
        if(cmd_sys_pro)
            execute_process(COMMAND ${cmd_sys_pro} OUTPUT_VARIABLE info)
            STRING(REGEX REPLACE "^.*Total Number of Cores: ([0-9]+).*$" "\\1" N_PROCS "${info}")
        ENDIF()
    ENDIF()
    # Windows:
    IF(WIN32)
        SET(N_PROCS "$ENV{NUMBER_OF_PROCESSORS}")
    ENDIF()
ENDIF()


# Set basic variables
SET( CTEST_PROJECT_NAME "TPLs" )
SET( CTEST_SOURCE_DIRECTORY "${TPL_SOURCE_DIR}" )
SET( CTEST_BINARY_DIRECTORY "." )
SET( CTEST_DASHBOARD "Nightly" )
SET( CTEST_CUSTOM_MAXIMUM_NUMBER_OF_ERRORS 500 )
SET( CTEST_CUSTOM_MAXIMUM_NUMBER_OF_WARNINGS 500 )
SET( CTEST_CUSTOM_MAXIMUM_PASSED_TEST_OUTPUT_SIZE 50000 )
SET( CTEST_CUSTOM_MAXIMUM_FAILED_TEST_OUTPUT_SIZE 50000 )
SET( NIGHTLY_START_TIME "17:00:00 EDT" )
SET( CTEST_NIGHTLY_START_TIME ${NIGHTLY_START_TIME} )
SET( CTEST_COMMAND "\"${CTEST_EXECUTABLE_NAME}\" -D ${CTEST_DASHBOARD}" )
SET( CTEST_USE_LAUNCHERS 1 )
SET( CTEST_BUILD_COMMAND "${CMAKE_MAKE_PROGRAM} -j ${N_PROCS}" )
SET( CTEST_CUSTOM_WARNING_EXCEPTION 
    "Manually-specified variables were not used by the project" 
)
IF ( BUILD_SERIAL )
    SET( CTEST_BUILD_COMMAND "${CMAKE_MAKE_PROGRAM} -i" )
ELSE()
    SET( CTEST_BUILD_COMMAND "${CMAKE_MAKE_PROGRAM} -i -j ${N_PROCS}" )
ENDIF()


# Set timeouts: 1 hour to build the project
SET( CTEST_TEST_TIMEOUT 3600 )


# Clear the binary directory and create an initial cache
EXECUTE_PROCESS( COMMAND ${CMAKE_COMMAND} -E remove -f CMakeCache.txt )
EXECUTE_PROCESS( COMMAND ${CMAKE_COMMAND} -E remove_directory CMakeFiles )
FILE(WRITE "${CTEST_BINARY_DIRECTORY}/CMakeCache.txt" "CTEST_TEST_CTEST:BOOL=1")


# Set the configure options
SET( CTEST_OPTIONS "-DCMAKE_BUILD_TYPE=${CMAKE_BUILD_TYPE}" )
SET( CTEST_OPTIONS "${CTEST_OPTIONS};-DUSE_MPI=${USE_MPI}" )
IF ( CC AND CXX )
    SET( CTEST_OPTIONS "${CTEST_OPTIONS};-DC_COMPILER=${CC};-DCXX_COMPILER=${CXX}" )
ENDIF()
IF ( FORTRAN )
    SET( CTEST_OPTIONS "${CTEST_OPTIONS};-DFortran_COMPILER=${FORTRAN}" )
ENDIF()
SET( CTEST_OPTIONS "${CTEST_OPTIONS};-DCFLAGS='${CFLAGS}';-DCXXFLAGS='${CXXFLAGS}';-DCXX_STD='${CXX_STD}';-DFFLAGS='${FFLAGS}'" )
SET( CTEST_OPTIONS "${CTEST_OPTIONS};-DLDFLAGS:STRING='${LDFLAGS}';-DLDLIBS:STRING='${LDLIBS}'" )
SET( CTEST_OPTIONS "${CTEST_OPTIONS};-DENABLE_STATIC=${ENABLE_STATIC};-DENABLE_SHARED=${ENABLE_SHARED}" )
SET( CTEST_OPTIONS "${CTEST_OPTIONS};-DMPIEXEC='${MPIEXEC}'" )
SET( CTEST_OPTIONS "${CTEST_OPTIONS};-DINSTALL_DIR=${INSTALL_DIR}" )
SET( CTEST_OPTIONS "${CTEST_OPTIONS};-DTPL_LIST=${TPL_LIST2}" )
FOREACH ( tpl ${TPL_LIST} )
    SET( CTEST_OPTIONS "${CTEST_OPTIONS};-D${tpl}_URL=${${tpl}_URL}" )
    SET( CTEST_OPTIONS "${CTEST_OPTIONS};-D${tpl}_SRC_DIR=${${tpl}_SRC_DIR}" )
    SET( CTEST_OPTIONS "${CTEST_OPTIONS};-D${tpl}_INSTALL_DIR=${${tpl}_INSTALL_DIR}" )
    IF ( ${tpl} STREQUAL "AMP" )
        SET( CTEST_OPTIONS "${CTEST_OPTIONS};-DAMP_DATA=${AMP_DATA}" )
    ELSEIF ( ${tpl} STREQUAL "BOOST" )
        SET( CTEST_OPTIONS "${CTEST_OPTIONS};-DBOOST_ONLY_COPY_HEADERS=${BOOST_ONLY_COPY_HEADERS}" )
    ELSEIF ( ${tpl} STREQUAL "LAPACK" )
        SET( CTEST_OPTIONS "${CTEST_OPTIONS};-DBLAS_INSTALL_DIR=${BLAS_INSTALL_DIR}" )
        SET( CTEST_OPTIONS "${CTEST_OPTIONS};-DLAPACK_INSTALL_DIR=${LAPACK_INSTALL_DIR}" )
        SET( CTEST_OPTIONS "${CTEST_OPTIONS};-DBLAS_LIB=${BLAS_LIB}" )
        SET( CTEST_OPTIONS "${CTEST_OPTIONS};-DLAPACK_LIB=${LAPACK_LIB}" )
    ELSEIF ( ${tpl} STREQUAL "TRILINOS" )
        SET( CTEST_OPTIONS "${CTEST_OPTIONS};-DTRILINOS_PACKAGES=${TRILINOS_PACKAGES}" )
        SET( CTEST_OPTIONS "${CTEST_OPTIONS};-DTRILINOS_EXTRA_PACKAGES=${TRILINOS_EXTRA_PACKAGES}" )
        SET( CTEST_OPTIONS "${CTEST_OPTIONS};-DTRILINOS_EXTRA_REPOSITORIES=${TRILINOS_EXTRA_REPOSITORIES}" )
        SET( CTEST_OPTIONS "${CTEST_OPTIONS};-DTRILINOS_EXTRA_FLAGS=${TRILINOS_EXTRA_FLAGS}" )
        SET( CTEST_OPTIONS "${CTEST_OPTIONS};-DTRILINOS_EXTRA_LINK_FLAGS=${TRILINOS_EXTRA_LINK_FLAGS}" )
    ENDIF()
    LOAD_VAR( ${tpl}_VERSION )
    IF ( ${tpl}_VERSION )
        SET( CTEST_OPTIONS "${CTEST_OPTIONS};-D${tpl}_VERSION=${${tpl}_VERSION}" )
    ENDIF()
ENDFOREACH()
STRING( REPLACE ";" "," LANGUAGES "${LANGUAGES}" )
SET( CTEST_OPTIONS "${CTEST_OPTIONS};-DLANGUAGES=${LANGUAGES}" )
SET( CTEST_OPTIONS "${CTEST_OPTIONS};-DENABLE_TESTS:BOOL=ON;-DDISABLE_TESTS_AFTER_INSTALL:BOOL=ON" )
MESSAGE("Configure options:")
MESSAGE("   ${CTEST_OPTIONS}")


# Configure the drop site
IF ( NOT CTEST_SITE )
    SET( CTEST_SITE ${HOSTNAME} )
ENDIF()
IF ( NOT CTEST_URL )
    SET( CTEST_DROP_METHOD "http" )
    SET( CTEST_DROP_LOCATION "/CDash/submit.php?project=CTest-Builder" )
    SET( CTEST_DROP_SITE_CDASH TRUE )
    SET( DROP_SITE_CDASH TRUE )
    SET( CTEST_DROP_SITE ${CTEST_SITE} )
ELSE()
    STRING( REPLACE "PROJECT" "CTest-Builder" CTEST_URL "${CTEST_URL}" )
    SET( CTEST_SUBMIT_URL "${CTEST_URL}" )
ENDIF()


# Configure and run the tests
CTEST_START( "${CTEST_DASHBOARD}" )
CTEST_UPDATE()
CTEST_CONFIGURE(
    BUILD   ${CTEST_BINARY_DIRECTORY}
    SOURCE  ${CTEST_SOURCE_DIRECTORY}
    OPTIONS "${CTEST_OPTIONS}"
)


# Run the configure/build/test
CTEST_BUILD()
CTEST_TEST()
CTEST_SUBMIT()


# Write a message to test for success in the ctest-builder
MESSAGE( "ctest_script ran to completion" )



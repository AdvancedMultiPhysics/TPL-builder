# ctest script for building, running, and submitting the test results 
# Usage:  ctest -S script,build
#   build = debug / optimized / weekly / valgrind / valgrind-matlab
# Note: this test will use use the number of processors defined in the variable N_PROCS,
#   the enviornmental variable N_PROCS, or the number of processors availible (if not specified)


# Macros to load environmental variables
MACRO( LOAD_VAR VAR ${ARGN} )
    SET( ${VAR} $ENV{${VAR}} )
    SET( DEFAULT ${ARGN} )
    IF ( NOT ${VAR} AND DEFAULT )
        SET( ${VAR} ${DEFAULT} )
    ENDIF()
ENDMACRO()
MACRO( LOAD_LIST VAR )
    SET( ${VAR} $ENV{${VAR}} )
    STRING( REPLACE "," ";" ${VAR} "${${VAR}}" )
ENDMACRO()
MACRO ( SET_OPTIONAL FLAG ${ARGN} )
    LOAD_VAR( ${FLAG} ${ARGN} )
    IF ( ${FLAG} )
        SET( CTEST_OPTIONS "${CTEST_OPTIONS};-D${FLAG}=${${FLAG}}" )
    ENDIF()
ENDMACRO()


# Set platform specific variables
SITE_NAME( HOSTNAME )
STRING(REGEX REPLACE "-ext."   "" HOSTNAME "${HOSTNAME}")
STRING(REGEX REPLACE "-login." "" HOSTNAME "${HOSTNAME}")
LOAD_VAR( CMAKE_MAKE_PROGRAM )
LOAD_VAR( CTEST_CMAKE_GENERATOR )


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
LOAD_VAR( N_PROCS )
IF ( NOT DEFINED N_PROCS )
    SET( N_PROCS 4 ) # Default number of processor if all else fails
    IF ( EXISTS "/proc/cpuinfo" )
        # Linux
        FILE( STRINGS "/proc/cpuinfo" procs REGEX "^processor.: [0-9]+$" )
        LIST( LENGTH procs N_PROCS )
    ELSEIF( APPLE )
        FIND_PROGRAM( cmd_sys_pro "system_profiler" )
        IF ( cmd_sys_pro )
            EXECUTE_PROCESS( COMMAND ${cmd_sys_pro} OUTPUT_VARIABLE info )
            STRING( REGEX REPLACE "^.*Total Number of Cores: ([0-9]+).*$" "\\1" N_PROCS "${info}" )
        ENDIF()
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
LOAD_VAR( BUILD_SERIAL )
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


# Set global configure options
LOAD_VAR( CC )
LOAD_VAR( CXX )
LOAD_VAR( FORTRAN )
LOAD_LIST( LANGUAGES )
SET( CTEST_OPTIONS "-DCMAKE_BUILD_TYPE=${CMAKE_BUILD_TYPE}" )
SET_OPTIONAL( USE_MPI )
IF ( CC )
    SET( CTEST_OPTIONS "${CTEST_OPTIONS};-DC_COMPILER=${CC}" )
    SET_OPTIONAL( CFLAGS )
ENDIF()
IF ( CXX )
    SET( CTEST_OPTIONS "${CTEST_OPTIONS};-DCXX_COMPILER=${CXX}" )
    SET_OPTIONAL( CXXFLAGS )
    SET_OPTIONAL( CXX_STD 17 )
ENDIF()
IF ( FORTRAN )
    SET( CTEST_OPTIONS "${CTEST_OPTIONS};-DFortran_COMPILER=${FORTRAN}" )
    SET_OPTIONAL( FFLAGS )
ENDIF()
SET_OPTIONAL( LDLIBS )
SET_OPTIONAL( LDFLAGS )
SET_OPTIONAL( ENABLE_STATIC )
SET_OPTIONAL( ENABLE_SHARED )
SET_OPTIONAL( MPIEXEC )
SET_OPTIONAL( INSTALL_DIR )
SET( CTEST_OPTIONS "${CTEST_OPTIONS};-DINSTALL_DIR=${INSTALL_DIR}" )
STRING( REPLACE ";" "," LANGUAGES "${LANGUAGES}" )
SET( CTEST_OPTIONS "${CTEST_OPTIONS};-DLANGUAGES=${LANGUAGES}" )


# Set package specific options
LOAD_LIST( TPL_LIST )
STRING( REPLACE ";" "," TPL_LIST2 "${TPL_LIST}" )
SET( CTEST_OPTIONS "${CTEST_OPTIONS};-DTPL_LIST=${TPL_LIST2}" )
FOREACH ( tpl ${TPL_LIST} )
    # Set common variables
    SET_OPTIONAL( ${tpl}_URL )
    SET_OPTIONAL( ${tpl}_SRC_DIR )
    SET_OPTIONAL( ${tpl}_INSTALL_DIR )
    SET_OPTIONAL( ${tpl}_VERSION )
    # Set package specific variables
    IF ( ${tpl} STREQUAL "AMP" )
        SET_OPTIONAL( AMP_DATA )
    ELSEIF ( ${tpl} STREQUAL "BOOST" )
        SET_OPTIONAL( BOOST_ONLY_COPY_HEADERS )
    ELSEIF ( ${tpl} STREQUAL "LAPACK" )
        SET_OPTIONAL( BLAS_INSTALL_DIR )
        SET_OPTIONAL( LAPACK_INSTALL_DIR )
        SET_OPTIONAL( BLAS_LIB )
        SET_OPTIONAL( LAPACK_LIB )
    ELSEIF ( ${tpl} STREQUAL "TRILINOS" )
        SET_OPTIONAL( TRILINOS_PACKAGES )
        SET_OPTIONAL( TRILINOS_EXTRA_PACKAGES )
        SET_OPTIONAL( TRILINOS_EXTRA_REPOSITORIES )
        SET_OPTIONAL( TRILINOS_EXTRA_FLAGS )
        SET_OPTIONAL( TRILINOS_EXTRA_FLAGS )
        SET_OPTIONAL( TRILINOS_EXTRA_LINK_FLAGS )
    ENDIF()
ENDFOREACH()
MESSAGE("Configure options:")
MESSAGE("   ${CTEST_OPTIONS}")


# Configure the drop site
LOAD_VAR( CTEST_SITE )
LOAD_VAR( CTEST_URL )
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



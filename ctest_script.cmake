# ctest script for building, running, and submitting the test results 
# Usage:  ctest -s script,build
#   build = debug / optimized / weekly / valgrind / valgrind-matlab
# Note: this test will use use the number of processors defined in the variable N_PROCS,
#   the enviornmental variable N_PROCS, or the number of processors availible (if not specified)

# Macro to load an enviornmental variable
MACRO( LOAD_VAR VAR )
    SET( ${VAR} $ENV{${VAR}} )
ENDMACRO()



# Set platform specific variables
SITE_NAME( HOSTNAME )
LOAD_VAR( CC )
LOAD_VAR( CXX )
LOAD_VAR( FORTRAN )
LOAD_VAR( CFLAGS )
LOAD_VAR( CXX_FLAGS )
LOAD_VAR( FFLAGS )
LOAD_VAR( LDFLAGS )
LOAD_VAR( ENABLE_STATIC )
LOAD_VAR( ENABLE_SHARED )
LOAD_VAR( INSTALL_DIR )
LOAD_VAR( PROCS_INSTALL )
LOAD_VAR( CMAKE_MAKE_PROGRAM )
LOAD_VAR( CTEST_CMAKE_GENERATOR )


# Get the list of projects assuming a comma seperate list (we will convert to CMake list)
LOAD_VAR( TPL_LIST )
STRING( REPLACE "," ";" TPL_LIST ${TPL_LIST} )


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
IF ( NOT COVERAGE_COMMAND )
    SET( ENABLE_GCOV "false" )
ENDIF()


# Set the number of processors
IF ( PROCS_INSTALL )
    SET( N_PROCS ${PROCS_INSTALL} )
ELSEIF ( NOT DEFINED N_PROCS )
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
SET( PROCS_INSTALL ${N_PROCS} )


# Set basic variables
SET( CTEST_PROJECT_NAME "TPLs" )
SET( CTEST_SOURCE_DIRECTORY "${TPL_SOURCE_DIR}" )
SET( CTEST_BINARY_DIRECTORY "." )
SET( CTEST_DASHBOARD "Nightly" )
SET( CTEST_CUSTOM_MAXIMUM_NUMBER_OF_ERRORS 500 )
SET( CTEST_CUSTOM_MAXIMUM_NUMBER_OF_WARNINGS 500 )
SET( CTEST_CUSTOM_MAXIMUM_PASSED_TEST_OUTPUT_SIZE 10000 )
SET( CTEST_CUSTOM_MAXIMUM_FAILED_TEST_OUTPUT_SIZE 10000 )
SET( NIGHTLY_START_TIME "18:00:00 EST" )
SET( CTEST_NIGHTLY_START_TIME "22:00:00 EST" )
SET( CTEST_COMMAND "\"${CTEST_EXECUTABLE_NAME}\" -D ${CTEST_DASHBOARD}" )
SET( CTEST_BUILD_COMMAND "${CMAKE_MAKE_PROGRAM}" )
SET( CTEST_USE_LAUNCHERS 1 )


# Set timeouts: 1 hour to build the project
SET( CTEST_TEST_TIMEOUT 3600 )


# Clear the binary directory and create an initial cache
EXECUTE_PROCESS( COMMAND ${CMAKE_COMMAND} -E remove -f CMakeCache.txt )
EXECUTE_PROCESS( COMMAND ${CMAKE_COMMAND} -E remove_directory CMakeFiles )
FILE(WRITE "${CTEST_BINARY_DIRECTORY}/CMakeCache.txt" "CTEST_TEST_CTEST:BOOL=1")


# Set the configure options
SET( CTEST_OPTIONS "-DCMAKE_BUILD_TYPE=${CMAKE_BUILD_TYPE}" )
IF ( CC AND CXX )
    SET( CTEST_OPTIONS "${CTEST_OPTIONS};-DC_COMPILER=${CC};-DCXX_COMPILER=${CXX};-DFortran_COMPILER=${FORTRAN}" )
ENDIF()
SET( CTEST_OPTIONS "${CTEST_OPTIONS};-DCFLAGS='${_FLAGS}';-DCXXFLAGS='${CXXFLAGS}';-DFFLAGS='${FFLAGS}'" )
SET( CTEST_OPTIONS "${CTEST_OPTIONS};-LDFLAGS:STRING=\"${LDFLAGS}\";-DLDLIBS:STRING=\"${LDLIBS}\"" )
SET( CTEST_OPTIONS "${CTEST_OPTIONS};-DENABLE_STATIC=${ENABLE_STATIC};-DENABLE_SHARED=${ENABLE_SHARED}" )
SET( CTEST_OPTIONS "${CTEST_OPTIONS};-DINSTALL_DIR=${INSTALL_DIR}" )
SET( CTEST_OPTIONS "${CTEST_OPTIONS};-DPROCS_INSTALL=${PROCS_INSTALL}" )
STRING( REPLACE ";" "," TPL_LIST2 "${TPL_LIST}" )
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
    ENDIF()
ENDFOREACH()
MESSAGE("Configure options:")
MESSAGE("   ${CTEST_OPTIONS}")


# Configure and run the tests
SET( CTEST_SITE ${HOSTNAME} )
CTEST_START("${CTEST_DASHBOARD}")
CTEST_UPDATE()
CTEST_CONFIGURE(
    BUILD   ${CTEST_BINARY_DIRECTORY}
    SOURCE  ${CTEST_SOURCE_DIRECTORY}
    OPTIONS "${CTEST_OPTIONS}"
)

# Run the configure/build 
CTEST_BUILD()
CTEST_TEST()



# Submit the results to oblivion
SET( CTEST_DROP_METHOD "http" )
SET( CTEST_DROP_SITE "oblivion.engr.colostate.edu" )
SET( CTEST_DROP_LOCATION "/CDash/submit.php?project=CTest-Builder" )
SET( CTEST_DROP_SITE_CDASH TRUE )
SET( DROP_SITE_CDASH TRUE )
CTEST_SUBMIT()


# Write a message to test for success in the ctest-builder
MESSAGE( "ctest_script ran to completion" )


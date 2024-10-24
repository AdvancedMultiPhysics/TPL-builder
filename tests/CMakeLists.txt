# Set some CMake properties
CMAKE_MINIMUM_REQUIRED(VERSION 3.1)
CMAKE_POLICY( SET CMP0057 NEW )


# Print a banner
MESSAGE("================")
MESSAGE("Run TPLS tests")
MESSAGE("================")


# Set the project name
SET( PROJ TPLS_Tests )


# Initialize the project (should disable langagues that the TPL builder will enable)
PROJECT( ${PROJ} LANGUAGES )


# Set the install path
IF( PREFIX )
    SET( CMAKE_INSTALL_PREFIX ${PREFIX} )
ELSEIF( INSTALL_DIR )
    SET( CMAKE_INSTALL_PREFIX ${INSTALL_DIR} )
ELSEIF( TPL_INSTALL_DIR )
    SET( CMAKE_INSTALL_PREFIX ${TPL_INSTALL_DIR} )
ELSE()
    SET( CMAKE_INSTALL_PREFIX ${CMAKE_CURRENT_BINARY_DIR} )
ENDIF()
SET( ${PROJ}_INSTALL_DIR ${CMAKE_INSTALL_PREFIX} )
SET( ${PROJ}_SOURCE_DIR ${CMAKE_CURRENT_SOURCE_DIR} )
MESSAGE("Installing TPLs tests in: ${${PROJ}_INSTALL_DIR}")


# Load the TPL package
IF ( NOT TPL_DIRECTORY )
    MESSAGE( FATAL_ERROR "TPL_DIRECTORY must be specified")
ENDIF()
FIND_PACKAGE( TPLs REQUIRED PATHS "${TPL_DIRECTORY}" )
MESSAGE("TPLs Found")
MESSAGE("  TPLs List: ${TPLs_LIST}")
MESSAGE("  Include Paths: ${TPLs_INCLUDE_DIRS}")
MESSAGE("  Libraries: ${TPLs_LIBRARIES}")


# Enable tests
ENABLE_TESTING()
INCLUDE( CTest )


# Include the TPL inclde paths and libraries
INCLUDE_DIRECTORIES( ${TPLs_INCLUDE_DIRS} )
MESSAGE("  Include Paths: ${TPLs_INCLUDE_DIRS}")
MESSAGE("  Libraries: ${TPLs_LIBRARIES}")
SET( TPL_LIBS ${TPLs_LIBRARIES} )


# Add the tests
ADD_TPLS_Tests_EXECUTABLE( hello_world )
ADD_TPLS_Tests_EXECUTABLE( test_all_libraries )
ADD_TPLS_Tests_TEST( hello_world )
ADD_TPLS_Tests_TEST( test_all_libraries )

get_target_property(OUT_LIBRARIES hello_world LINK_LIBRARIES)
get_target_property(OUT_FLAGS hello_world LINK_FLAGS)
message( "hello_world:" )
message( "   LINK_LIBRARIES: ${OUT_LIBRARIES}")
message( "   LINK_FLAGS: ${OUT_FLAGS}")

IF ( USE_MPI )
    ADD_TPLS_Tests_TEST( test_MPI PROCS 4 )
ENDIF()
IF ( USE_STACKTRACE )
    FIND_PROGRAM( TestStack TestStack PATHS "${STACKTRACE_INSTALL_DIR}/bin" )
    FIND_PROGRAM( TestUtilities TestUtilities PATHS "${STACKTRACE_INSTALL_DIR}/bin" )
    FIND_PROGRAM( TestTerminate TestTerminate PATHS "${STACKTRACE_INSTALL_DIR}/bin" )
    FILE( COPY ${TestStack} DESTINATION ${CMAKE_CURRENT_BINARY_DIR} )
    FILE( COPY ${TestStack} DESTINATION ${CMAKE_INSTALL_PREFIX}/bin )
    FILE( COPY ${TestUtilities} DESTINATION ${CMAKE_CURRENT_BINARY_DIR} )
    FILE( COPY ${TestUtilities} DESTINATION ${CMAKE_INSTALL_PREFIX}/bin )
    FILE( COPY ${TestTerminate} DESTINATION ${CMAKE_CURRENT_BINARY_DIR} )
    FILE( COPY ${TestTerminate} DESTINATION ${CMAKE_INSTALL_PREFIX}/bin )
    CONFIGURE_FILE( "${STACKTRACE_INSTALL_DIR}/bin/ExampleStack.txt" "${CMAKE_CURRENT_BINARY_DIR}/ExampleStack.txt" @ONLY )
    CONFIGURE_FILE( "${STACKTRACE_INSTALL_DIR}/bin/ExampleStack.txt" "${CMAKE_INSTALL_PREFIX}/bin/ExampleStack.txt" @ONLY )
    ADD_TEST( NAME TestStack COMMAND ${TestStack} )
    ADD_TEST( NAME TestUtilities COMMAND ${TestUtilities} )
    SET_TESTS_PROPERTIES( TestStack PROPERTIES PROCESSORS 2 )
    IF ( USE_MPI )
        ADD_TEST( NAME TestStack-4procs COMMAND ${MPIEXEC} ${MPIEXEC_NUMPROC_FLAG} 4 ${TestStack} )
        ADD_TEST( NAME TestUtilities-4procs COMMAND ${MPIEXEC} ${MPIEXEC_NUMPROC_FLAG} 4 ${TestStack} )
        SET_TESTS_PROPERTIES( TestStack-4procs PROPERTIES PROCESSORS 8 )
        SET_TESTS_PROPERTIES( TestUtilities-4procs PROPERTIES PROCESSORS 4 )
    ENDIF()
ENDIF()
IF ( USE_LAPACK_WRAPPERS )
    FIND_PROGRAM( test_LapackWrappers test_LapackWrappers PATHS "${LAPACK_WRAPPERS_INSTALL_DIR}/bin" )
    FILE( COPY ${test_LapackWrappers} DESTINATION ${CMAKE_CURRENT_BINARY_DIR} )
    FILE( COPY ${test_LapackWrappers} DESTINATION ${CMAKE_INSTALL_PREFIX}/bin )
    ADD_TEST( NAME test_LapackWrappers COMMAND ${test_LapackWrappers} )
ENDIF()
IF ( USE_MATLAB )
    ADD_SUBDIRECTORY( matlab )
ENDIF()

# Copy the tests to TPL project
IF ( TPL_TEST_DIR )
    FILE( APPEND "${TPL_TEST_DIR}/CTestTestfile.cmake" "\n" )
    FILE( APPEND "${TPL_TEST_DIR}/CTestTestfile.cmake" "IF ( NOT INCLUDED_TPL_TESTS )\n" )
    FILE( APPEND "${TPL_TEST_DIR}/CTestTestfile.cmake" "    SET( INCLUDED_TPL_TESTS 1 )\n" )
    FILE( APPEND "${TPL_TEST_DIR}/CTestTestfile.cmake" "    INCLUDE( \"${CMAKE_BINARY_DIR}/CTestTestfile.cmake\" )\n" )
    FILE( APPEND "${TPL_TEST_DIR}/CTestTestfile.cmake" "ENDIF()\n" )
ENDIF()

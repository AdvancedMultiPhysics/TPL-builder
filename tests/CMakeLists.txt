# Set some CMake properties
CMAKE_MINIMUM_REQUIRED(VERSION 3.1)
CMAKE_POLICY(SET CMP0014 OLD)
CMAKE_POLICY(SET CMP0026 OLD)
CMAKE_POLICY(SET CMP0042 NEW)


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
SET( CMAKE_MODULE_PATH "${TPL_DIRECTORY}" ${CMAKE_MODULE_PATH} )
FIND_PACKAGE( TPLs REQUIRED )
MESSAGE("TPLs Found")
MESSAGE("  TPLs List: ${TPL_LIST}")
MESSAGE("  Include Paths: ${TPL_INCLUDE_DIRS}")
MESSAGE("  Libraries: ${TPL_LIBRARIES}")


# Enable tests
ENABLE_TESTING()
INCLUDE( CTest )


# Include the macros file
INCLUDE( "${TPL_MACRO_CMAKE}" )
ADD_CUSTOM_TARGET( check )
ADD_CUSTOM_TARGET( build-test )


# Include the TPL inclde paths and libraries
INCLUDE_DIRECTORIES( ${TPL_INCLUDE_DIRS} )
SET( TPL_LIBS ${TPL_LIBRARIES} )


# Add the tests
ADD_TPLS_Tests_EXECUTABLE( hello_world )
ADD_TPLS_Tests_EXECUTABLE( test_all_libraries )
ADD_TPLS_Tests_TEST( hello_world )
ADD_TPLS_Tests_TEST( test_all_libraries )
IF ( USE_MPI )
    ADD_TPLS_Tests_TEST_PARALLEL( test_MPI 4 )
ENDIF()
IF ( USE_LAPACK )
    ADD_TPLS_Tests_EXECUTABLE( test_LapackWrappers )
    ADD_TPLS_Tests_TEST( test_LapackWrappers )
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

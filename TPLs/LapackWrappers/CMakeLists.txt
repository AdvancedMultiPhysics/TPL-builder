# Set some CMake properties
CMAKE_MINIMUM_REQUIRED(VERSION 3.1)


# Print a banner
MESSAGE("================")
MESSAGE("Lapack Wrappers ")
MESSAGE("================")


# Set the project name
SET( PROJ LapackWrappers )


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
MESSAGE("Installing LapackWrappers in: ${CMAKE_INSTALL_PREFIX}")


# Load the TPL package
IF ( NOT TPL_DIRECTORY )
    MESSAGE( FATAL_ERROR "TPL_DIRECTORY must be specified")
ENDIF()
SET( CMAKE_MODULE_PATH "${TPL_DIRECTORY}" ${CMAKE_MODULE_PATH} )
FIND_PACKAGE( TPLs REQUIRED COMPONENTS LAPACK )


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


# Install the library
BEGIN_PACKAGE_CONFIG( LapackWrappers )
INSTALL_LapackWrappers_TARGET( LapackWrappers )



# Set some CMake properties 
CMAKE_MINIMUM_REQUIRED(VERSION 3.9)   

# Configure MATLAB
SET( Matlab_ROOT_DIR ${MATLAB_INSTALL_DIR} )
FIND_PACKAGE( Matlab REQUIRED MAIN_PROGRAM MX_LIBRARY ENG_LIBRARY MEX_COMPILER )

# Add mex file
MATLAB_ADD_MEX(
    NAME hello_world
    SRC hello_world.cpp
)

# Add unit test
INCLUDE( CTest )
MATLAB_ADD_UNIT_TEST(
    NAME hello_world2
    UNITTEST_FILE "${CMAKE_CURRENT_SOURCE_DIR}/hello_world_unittest.m"
    TIMEOUT -1
    ADDITIONAL_PATH ${CMAKE_CURRENT_BINARY_DIR}
    MATLAB_ADDITIONAL_STARTUP_OPTIONS -singleCompThread -nosplash -nodisplay -nojvm
    NO_UNITTEST_FRAMEWORK
)


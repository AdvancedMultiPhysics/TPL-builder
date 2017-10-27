# Add the mex target
ADD_CUSTOM_TARGET( mex ALL )
ADD_MEXCLEAN()

# Add the MATLAB MEX files
ADD_MATLAB_MEX( mex_hello_world.cpp )

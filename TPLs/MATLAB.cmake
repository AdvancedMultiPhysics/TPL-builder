# This will configure MATLAB


# Intialize download/src/install vars
SET( MATLAB_BUILD_DIR "${CMAKE_BINARY_DIR}/MATLAB-prefix/src/MATLAB-build" )
IF ( MATLAB_INSTALL_DIR ) 
    SET( MATLAB_CMAKE_INSTALL_DIR "${MATLAB_INSTALL_DIR}" )
    SET( CMAKE_BUILD_MATLAB FALSE )
ELSE()
    MESSAGE(FATAL_ERROR "Please specify MATLAB_INSTALL_DIR")
ENDIF()


# Configure MATLAB
SET( USE_MATLAB TRUE )
CHECK_ENABLE_FLAG( USE_MATLAB_LAPACK TRUE )
VERIFY_PATH( ${MATLAB_INSTALL_DIR} )
VERIFY_PATH( ${MATLAB_INSTALL_DIR}/extern )
SET( Matlab_ROOT_DIR ${MATLAB_INSTALL_DIR} )
FIND_PACKAGE( Matlab REQUIRED MAIN_PROGRAM MX_LIBRARY ENG_LIBRARY MEX_COMPILER )

# Get the mex extension for the current architecture
IF (CMAKE_SIZEOF_VOID_P MATCHES 8) 
    SET( SYSTEM_NAME "${CMAKE_SYSTEM_NAME}_64" ) 
ELSE()
    SET( SYSTEM_NAME "${CMAKE_SYSTEM_NAME}_32" ) 
ENDIF() 
IF ( ${SYSTEM_NAME} STREQUAL "Linux_32" ) 
ELSEIF ( ${SYSTEM_NAME} STREQUAL "Linux_64" ) 
    SET( MATLAB_EXTERN "${MATLAB_INSTALL_DIR}/bin/glnxa64" )
    SET( MATLAB_OS "${MATLAB_INSTALL_DIR}/sys/os/glnxa64" )
ELSEIF ( ${SYSTEM_NAME} STREQUAL "Darwin_32" ) 
ELSEIF ( ${SYSTEM_NAME} STREQUAL "Darwin_64" ) 
ELSEIF ( ${SYSTEM_NAME} STREQUAL "Windows_32" ) 
ELSEIF ( ${SYSTEM_NAME} STREQUAL "Windows_64" ) 
    SET( MATLAB_EXTERN "${MATLAB_INSTALL_DIR}/extern/lib/win64/microsoft" 
        "${MATLAB_INSTALL_DIR}/bin/win64" )
ELSE ( ) 
    MESSAGE( FATAL_ERROR "Unkown OS ${SYSTEM_NAME}" )
ENDIF()
FOREACH( tmp ${MATLAB_EXTERN} )
    VERIFY_PATH( ${tmp} )
ENDFOREACH()

# Set the initial flags for matlab
SET( MEX_FLAGS )
SET( MEX_LDFLAGS )
SET( MEX_LIBS -leng -lmat -lmx )
IF ( ${CMAKE_BUILD_TYPE} STREQUAL "Debug" )
    SET( MEX_FLAGS ${MEX_FLAGS} -g )
ELSEIF ( ${CMAKE_BUILD_TYPE} STREQUAL "Release" )
    SET( MEX_FLAGS ${MEX_FLAGS} -O )
ELSE()
    MESSAGE ( FATAL_ERROR "Unknown CMAKE_BUILD_TYPE=${CMAKE_BUILD_TYPE}" )
ENDIF()
SET( MEX_FLAGS ${MEX_FLAGS} -largeArrayDims )


# Check if we need to include MATLAB's libstdc++
FIND_LIBRARY( MATLAB_BLAS_LIBRARY   NAMES mwblas          PATHS ${MATLAB_EXTERN}  NO_DEFAULT_PATH )
FIND_LIBRARY( MATLAB_BLAS_LIBRARY   NAMES libmwblas.dll   PATHS ${MATLAB_EXTERN}  NO_DEFAULT_PATH )
FIND_LIBRARY( MATLAB_LAPACK_LIBRARY NAMES mwlapack        PATHS ${MATLAB_EXTERN}  NO_DEFAULT_PATH )
FIND_LIBRARY( MATLAB_LAPACK_LIBRARY NAMES libmwlapack.dll PATHS ${MATLAB_EXTERN}  NO_DEFAULT_PATH )
SET( CMAKE_REQUIRED_FLAGS ${CMAKE_CXX_FLAGS} )
SET( CMAKE_REQUIRED_LIBRARIES ${MATLAB_LAPACK_LIBRARY} ${MATLAB_BLAS_LIBRARY} )
CHECK_CXX_SOURCE_COMPILES(
    "#include \"${MATLAB_INSTALL_DIR}/extern/include/tmwtypes.h\"
     #include \"${MATLAB_INSTALL_DIR}/extern/include/lapack.h\"
     int main() {
        dgesv( nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, nullptr);
        return 0;
     }" MATLAB_LAPACK_LINK )
IF ( MATLAB_LAPACK_LINK )
    # Use system libc++
    FIND_LIBRARY( MEX_LIBCXX  NAMES stdc++ )
    FIND_LIBRARY( MEX_LIBCXX  NAMES libstdc++.so.6 )
    SET( MATLAB_LAPACK ${MATLAB_LAPACK_LIBRARY} ${MATLAB_BLAS_LIBRARY} )
ELSE()
    # Try to link MATLAB's libc++
    FIND_LIBRARY( MEX_LIBCXX  NAMES stdc++          PATHS ${MATLAB_OS}      NO_DEFAULT_PATH )
    FIND_LIBRARY( MEX_LIBCXX  NAMES libstdc++.so.6  PATHS ${MATLAB_OS}      NO_DEFAULT_PATH )
    SET( CMAKE_REQUIRED_LIBRARIES ${MATLAB_LAPACK_LIBRARY} ${MATLAB_BLAS_LIBRARY} ${MEX_LIBCXX} )
    CHECK_CXX_SOURCE_COMPILES(
        "#include \"${MATLAB_INSTALL_DIR}/extern/include/tmwtypes.h\"
         #include \"${MATLAB_INSTALL_DIR}/extern/include/lapack.h\"
         int main() {
            dgesv( nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, nullptr);
            return 0;
         }" MATLAB_LAPACK_LINK2 )
    IF ( NOT MATLAB_LAPACK_LINK2 )
        MESSAGE( FATAL_ERROR "Unable to link with MATLAB's LAPACK" )
    ENDIF()
    SET( MATLAB_LAPACK ${MATLAB_LAPACK_LIBRARY} ${MATLAB_BLAS_LIBRARY} ${MEX_LIBCXX} )
ENDIF()

# Save important variables
MESSAGE( "Using MATLAB" )
MESSAGE( "   MATLAB_INSTALL_DIR = ${MATLAB_INSTALL_DIR}" )
MESSAGE( "   MATLAB_LAPACK = ${MATLAB_LAPACK}" )
MESSAGE( "   MEX_FLAGS = ${MEX_FLAGS}" )
MESSAGE( "   MEX_LIBS  = ${MEX_LIBS}" )
MESSAGE( "   MEX_FLAGS = ${MEX_LDFLAGS}" )
MESSAGE( "   MEX_LIBCXX = ${MEX_LIBCXX}" )


# Create a dummy install
ADD_TPL_EMPTY( MATLAB )


# Add the appropriate fields to FindTPLs.cmake
FILE( APPEND "${FIND_TPLS_CMAKE}" "\n# Find MATLAB\n" )
FILE( APPEND "${FIND_TPLS_CMAKE}" "IF ( TPLs_FIND_MATLAB AND NOT TPL_FOUND_MATLAB )\n" )
FILE( APPEND "${FIND_TPLS_CMAKE}" "    SET( TPL_FOUND_MATLAB TRUE )\n")
FILE( APPEND "${FIND_TPLS_CMAKE}" "    SET( USE_MATLAB TRUE )\n")
FILE( APPEND "${FIND_TPLS_CMAKE}" "    SET( MATLAB_DIRECTORY  \"${MATLAB_INSTALL_DIR}\")\n")
FILE( APPEND "${FIND_TPLS_CMAKE}" "    SET( MATLAB_INSTALL_DIR  \"${MATLAB_INSTALL_DIR}\")\n")
FILE( APPEND "${FIND_TPLS_CMAKE}" "    SET( Matlab_ROOT_DIR \"${MATLAB_INSTALL_DIR}\")\n")
FILE( APPEND "${FIND_TPLS_CMAKE}" "    FIND_PACKAGE( Matlab REQUIRED MAIN_PROGRAM MX_LIBRARY ENG_LIBRARY MEX_COMPILER )\n")
FILE( APPEND "${FIND_TPLS_CMAKE}" "    SET( USE_MATLAB_LAPACK \"${USE_MATLAB_LAPACK}\")\n")
FILE( APPEND "${FIND_TPLS_CMAKE}" "    SET( MATLAB_EXTERN \"${MATLAB_EXTERN}\")\n")
FILE( APPEND "${FIND_TPLS_CMAKE}" "    SET( MEX_LIBCXX \"${MEX_LIBCXX}\")\n")
FILE( APPEND "${FIND_TPLS_CMAKE}" "    SET( CMAKE_INSTALL_RPATH $\{CMAKE_INSTALL_RPATH} \"${MATLAB_EXTERN}\" \"${MATLAB_OS}\" )\n")
FILE( APPEND "${FIND_TPLS_CMAKE}" "    SET( DISABLE_THREAD_LOCAL TRUE )\n" )
FILE( APPEND "${FIND_TPLS_CMAKE}" "    ADD_DEFINITIONS( -DMATLAB_MEXCMD_RELEASE=700 )\n" )
FILE( APPEND "${FIND_TPLS_CMAKE}" "ENDIF()\n" )
FILE( APPEND "${FIND_TPLS_CMAKE}" "\n" )


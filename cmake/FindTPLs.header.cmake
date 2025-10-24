# FindTPLs
# ---------
#
# Find Third Party Libraries (TPLs) configured and installed by the TPL builder
#
# Use this module by invoking find_package with the form:
#
#   find_package(FindTPLs
#     [version] [EXACT]      # Minimum or EXACT version e.g. 1.36.0
#     [REQUIRED]             # Fail with error if the TPLs are not found
#     [COMPONENTS <libs>...] # List of TPLs to include
#   )
#
# This module finds headers and requested component libraries for the TPLs that
# were installed by the builder.
#
#   TPLs_FOUND          - True if headers and requested libraries were found
#   TPLs_LIST           - List of TPLs that are availible
#   TPLs_${TPL}_FOUND   - Was the specified TPL found
#   TPLs_LIBRARIES      - TPL Libraries
#   TPLs_INCLUDE_DIRS   - TPL Include paths
#   TPLs_MACRO_CMAKE    - File to macros.cmake provided by the TPL install
#   TPLs_CPPCHECK_CMAKE - File to cppcheck.cmake provided by the TPL install
#   TPLs_CPPCLEAN_CMAKE - File to cppclean.cmake provided by the TPL install


SET( TPLs_VERSION @TPLs_VERSION@ )

@PACKAGE_INIT@


# Set some cmake policies
CMAKE_POLICY( SET CMP0074 NEW )
CMAKE_POLICY( SET CMP0110 NEW )


# Print a message to indicate we started looking for TPLs
IF ( NOT TPLs_FIND_QUIETLY )
    MESSAGE( "Running FindTPLs" )
ENDIF()


# Macro to set a flag if it does not exist
MACRO( SET_TPL_VAR VAR )
    IF ( NOT ${VAR} )
        SET( ${VAR} ${ARGN} )
    ENDIF()
ENDMACRO()


# Define some basic usage
SET( USE_MPI @USE_MPI@ )
IF ( NOT DEFINED DISABLE_CUDA AND NOT DEFINED USE_CUDA )
    SET( USE_CUDA       @USE_CUDA@ )
ENDIF()
IF ( NOT DEFINED DISABLE_HIP AND NOT DEFINED USE_HIP )
    SET( USE_HIP       @USE_HIP@ )
ENDIF()
IF ( NOT DEFINED DISABLE_OPENMP AND NOT DEFINED USE_OPENMP )
    SET( USE_OPENMP     @USE_OPENMP@ )
  ENDIF()

# flag for GPU aware MPI - requires user to provide
# vendor specific compile and link flags for GPU aware MPI
IF ( ( USE_CUDA OR USE_HIP ) AND NOT DEFINED DISABLE_GPU_AWARE_MPI AND NOT DEFINED ENABLE_GPU_AWARE_MPI )
    SET( ENABLE_GPU_AWARE_MPI     @ENABLE_GPU_AWARE_MPI@ )
ENDIF()

# Set some basic information (should only be called once regardless of the number of calls to find_package(FindTPLs)
IF ( NOT TPLs_COMPILERS_INITIALIZED )

    # Set that we were able to find the TPLs (this file)
    SET( TPLs_COMPILERS_INITIALIZED TRUE )

    # Set the TPL list
    SET( TPLs_LIST @TPL_LIST@ )

    # Include project install directory
    INCLUDE_DIRECTORIES( "${CMAKE_CURRENT_LIST_DIR}" )

    # Include project install directory
    INCLUDE_DIRECTORIES( "${${PROJ}_INSTALL_DIR}/include" )

    # Check that PROJ and ${PROJ}_INSTALL_DIR have been set
    IF ( NOT PROJ )
        MESSAGE( FATAL_ERROR "PROJ must be set before calling FindTPLs")
    ENDIF()
    IF ( NOT ${PROJ}_INSTALL_DIR )
        MESSAGE( FATAL_ERROR "${PROJ}_INSTALL_DIR must be set before calling FindTPLs")
    ENDIF()

    # Initialize the include paths / libraries
    SET( TPLs_INCLUDE_DIRS )
    SET( TPLs_LIBRARIES )

    # Set CMAKE_MODULE_PATH
    SET( CMAKE_MODULE_PATH "@CMAKE_INSTALL_PREFIX@/cmake" ${CMAKE_MODULE_PATH} )

    # Set the compilers and compile flags
    SET_TPL_VAR( CMAKE_BUILD_TYPE           @CMAKE_BUILD_TYPE@           )
    SET_TPL_VAR( ENABLE_STATIC              @ENABLE_STATIC@              )
    SET_TPL_VAR( ENABLE_SHARED              @ENABLE_SHARED@              )
    SET_TPL_VAR( DISABLE_GOLD               @DISABLE_GOLD@               )
    SET_TPL_VAR( BUILD_STATIC_LIBS          @BUILD_STATIC_LIBS@          )
    SET_TPL_VAR( BUILD_SHARED_LIBS          @BUILD_SHARED_LIBS@          )
    SET_TPL_VAR( CMAKE_C_COMPILER          "@CMAKE_C_COMPILER@"          )
    SET_TPL_VAR( CMAKE_C_COMPILER_ID       "@CMAKE_C_COMPILER_ID@"       )
    SET_TPL_VAR( CMAKE_C_FLAGS             "@CMAKE_C_FLAGS@"             )
    SET_TPL_VAR( CMAKE_C_STANDARD          "@CMAKE_C_STANDARD@"          )
    SET_TPL_VAR( CMAKE_C_EXTENSIONS         OFF                          )
    SET_TPL_VAR( CMAKE_CXX_COMPILER        "@CMAKE_CXX_COMPILER@"        )
    SET_TPL_VAR( CMAKE_CXX_COMPILER_ID     "@CMAKE_CXX_COMPILER_ID@"     )
    SET_TPL_VAR( CMAKE_CXX_FLAGS           "@CMAKE_CXX_FLAGS@"           )
    SET_TPL_VAR( CMAKE_CXX_STANDARD        "@CMAKE_CXX_STANDARD@"        )
    SET_TPL_VAR( CMAKE_CXX_EXTENSIONS       OFF                          )
    SET_TPL_VAR( CMAKE_Fortran_COMPILER    "@CMAKE_Fortran_COMPILER@"    )
    SET_TPL_VAR( CMAKE_Fortran_COMPILER_ID "@CMAKE_Fortran_COMPILER_ID@" )
    SET_TPL_VAR( CMAKE_Fortran_FLAGS       "@CMAKE_Fortran_FLAGS@"       )
    SET_TPL_VAR( ENABLE_GXX_DEBUG          "@ENABLE_GXX_DEBUG@"          )
    IF ( ENABLE_SHARED )
        SET( LIB_TYPE SHARED )
    ELSE()
        SET( LIB_TYPE STATIC )
    ENDIF()
    SET( CXX_STD_FLAG ${CMAKE_CXX${CXX_STD}_STANDARD_COMPILE_OPTION} )
    ADD_DEFINITIONS( -DCXX_STD=${CMAKE_CXX_STANDARD} )
    IF ( CMAKE_C_COMPILER AND NOT DISABLE_C )
        ENABLE_LANGUAGE( C )
    ENDIF()
    IF ( CMAKE_CXX_COMPILER AND NOT DISABLE_CXX )
        ENABLE_LANGUAGE( CXX )
    ENDIF()
    IF ( CMAKE_Fortran_COMPILER AND NOT DISABLE_FORTRAN )
        ENABLE_LANGUAGE( Fortran )
    ENDIF()
    IF ( USE_CUDA )
        # Check the CMake version
        IF ( ${CMAKE_VERSION} VERSION_LESS "3.17" )
            MESSAGE( FATAL_ERROR "We require CMake 3.17 or newer when compiling with CUDA" )
        ENDIF()
        # Enable CUDA
        SET( CMAKE_CUDA_COMPILER "@CMAKE_CUDA_COMPILER@" CACHE STRING "Cuda compiler" )
        SET( CMAKE_CUDA_HOST_COMPILER "@CMAKE_CUDA_HOST_COMPILER@" CACHE STRING "Cuda host compiler" )
        SET( CMAKE_CUDA_STANDARD_REQUIRED @CMAKE_CUDA_STANDARD_REQUIRED@ CACHE BOOL "Cuda C++ standard required")
        SET( CMAKE_CUDA_STANDARD @CMAKE_CUDA_STANDARD@ CACHE STRING "Cuda C++ standard" )
        SET( CMAKE_CUDA_ARCHITECTURES "@CMAKE_CUDA_ARCHITECTURES@" CACHE STRING "Cuda architectures" )
        SET( CMAKE_CUDA_FLAGS  "@CMAKE_CUDA_FLAGS@" CACHE STRING "Cuda flags" )
        SET( TPLs_DISABLE_CUDA_SEPARABLE_COMPILATION @TPLs_DISABLE_CUDA_SEPARABLE_COMPILATION@ )
        IF ( NOT DEFINED TPLs_DISABLE_CUDA_SEPARABLE_COMPILATION )
            MESSAGE( STATUS "Enabling CMAKE_CUDA_SEPARABLE_COMPILATION")
            SET( CMAKE_CUDA_SEPARABLE_COMPILATION TRUE CACHE BOOL "Enable Cuda Relocatable Device Code" )
        ENDIF()
        # Set COMPILE_CXX_AS_CUDA
        IF ( NOT DEFINED COMPILE_CXX_AS_CUDA )
            SET( COMPILE_CXX_AS_CUDA @COMPILE_CXX_AS_CUDA@ )
        ENDIF()
        # Enable CUDA
        ENABLE_LANGUAGE( CUDA )
    ENDIF()
    IF ( USE_HIP )
        # Check the CMake version
        IF ( ${CMAKE_VERSION} VERSION_LESS "3.21" )
            MESSAGE( FATAL_ERROR "We require CMake 3.21 or newer when compiling with HIP" )
        ENDIF()
        # Enable HIP
        SET( CMAKE_HIP_COMPILER "@CMAKE_HIP_COMPILER@" CACHE STRING "HIP compiler" )
        SET( CMAKE_HIP_HOST_COMPILER "@CMAKE_HIP_HOST_COMPILER@" CACHE STRING "HIP host compiler" )
        SET( CMAKE_HIP_STANDARD_REQUIRED @CMAKE_HIP_STANDARD_REQUIRED@ CACHE BOOL "HIP C++ standard required")
        SET( CMAKE_HIP_STANDARD @CMAKE_HIP_STANDARD@ CACHE STRING "HIP C++ standard" )
        SET( CMAKE_HIP_ARCHITECTURES "@CMAKE_HIP_ARCHITECTURES@" CACHE STRING "HIP architectures" )
        # Set COMPILE_CXX_AS_HIP
        IF ( NOT DEFINED COMPILE_CXX_AS_HIP )
            SET( COMPILE_CXX_AS_HIP @COMPILE_CXX_AS_HIP@ )
        ENDIF()
        # ensure HIP compiler uses the same GNU headers and libstdc++
        IF (CMAKE_CXX_COMPILER_ID STREQUAL GNU)
            EXECUTE_PROCESS(COMMAND ${CMAKE_CXX_COMPILER} -print-file-name=libgcc.a OUTPUT_VARIABLE GCC_LIBGCC_PATH OUTPUT_STRIP_TRAILING_WHITESPACE)
            EXECUTE_PROCESS(COMMAND ${CMAKE_CXX_COMPILER} -print-file-name=libstdc++.so OUTPUT_VARIABLE GCC_LIBSTDCPP_PATH OUTPUT_STRIP_TRAILING_WHITESPACE)
            GET_FILENAME_COMPONENT(GCC_INSTALL_DIR ${GCC_LIBGCC_PATH} DIRECTORY)
            GET_FILENAME_COMPONENT(GCC_LIB_DIR ${GCC_LIBSTDCPP_PATH} DIRECTORY)
            GET_FILENAME_COMPONENT(GCC_INSTALL_DIR ${GCC_INSTALL_DIR} ABSOLUTE)
            GET_FILENAME_COMPONENT(GCC_LIB_DIR ${GCC_LIB_DIR} ABSOLUTE)
            SET( CMAKE_HIP_FLAGS "@CMAKE_HIP_FLAGS@ --gcc-install-dir=${GCC_INSTALL_DIR}" CACHE STRING "HIP flags" FORCE )
            IF (NOT "${GCC_LIB_DIR}" IN_LIST CMAKE_BUILD_RPATH)
                LIST(APPEND CMAKE_BUILD_RPATH ${GCC_LIB_DIR})
            ENDIF()
        ELSE()
            SET( CMAKE_HIP_FLAGS  "@CMAKE_HIP_FLAGS@" CACHE STRING "HIP flags" )
        ENDIF()
        SET( TPLs_DISABLE_HIP_SEPARABLE_COMPILATION @TPLs_DISABLE_HIP_SEPARABLE_COMPILATION@ )
        IF ( NOT DEFINED TPLs_DISABLE_HIP_SEPARABLE_COMPILATION )
            MESSAGE( STATUS "Enabling CMAKE_HIP_SEPARABLE_COMPILATION")
            SET( CMAKE_HIP_SEPARABLE_COMPILATION TRUE CACHE BOOL "Enable HIP Relocatable Device Code" )
        ENDIF()
        # Enable HIP
        ENABLE_LANGUAGE( HIP )
    ENDIF()
    IF ( NOT DEFINED NUMBER_OF_GPUS )
        SET( NUMBER_OF_GPUS @NUMBER_OF_GPUS@ CACHE STRING "Number of GPUs for testing" )
    ENDIF()

    IF ( USE_OPENMP )
        FIND_PACKAGE( OpenMP )
        SET( CMAKE_C_FLAGS "${CMAKE_C_FLAGS} ${OpenMP_C_FLAGS}" )
        SET( CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} ${OpenMP_CXX_FLAGS}" )
        SET( CMAKE_Fortran_FLAGS "${CMAKE_Fortran_FLAGS} ${OpenMP_Fortran_FLAGS}" )
    ENDIF()
    SET( LDFLAGS "@LDFLAGS@ ${LDFLAGS}" )
    SET( LDLIBS "@LDLIBS@ ${LDLIBS}" )
    SET( ENABLE_GXX_DEBUG @ENABLE_GXX_DEBUG@ )
    SET( DISABLE_GXX_DEBUG @DISABLE_GXX_DEBUG@ )
    IF ( NOT TPLs_FIND_QUIETLY )
        MESSAGE( STATUS "CMAKE_C_COMPILER = ${CMAKE_C_COMPILER}")
        MESSAGE( STATUS "CMAKE_CXX_COMPILER = ${CMAKE_CXX_COMPILER}")
        MESSAGE( STATUS "CMAKE_Fortran_COMPILER = ${CMAKE_Fortran_COMPILER}")
        IF ( USE_CUDA )
            MESSAGE( STATUS "CMAKE_CUDA_COMPILER = ${CMAKE_CUDA_COMPILER}")
            MESSAGE( STATUS "CMAKE_CUDA_HOST_COMPILER = ${CMAKE_CUDA_HOST_COMPILER}")
        ENDIF()
        IF ( USE_HIP )
            MESSAGE( STATUS "CMAKE_HIP_COMPILER = ${CMAKE_HIP_COMPILER}")
            MESSAGE( STATUS "CMAKE_HIP_HOST_COMPILER = ${CMAKE_HIP_HOST_COMPILER}")
        ENDIF()
    ENDIF()

    # Disable LTO
    IF ( NOT DEFINED DISABLE_LTO )
        SET( DISABLE_LTO @DISABLE_LTO@ )
    ENDIF()

    # Set up MPI compiler
    IF ( USE_MPI )
        # Set user flags that control the behavior of FindMPI.cmake (or are used by subsequent projects)
        SET( USE_MPI_FOR_SERIAL_TESTS   @USE_MPI_FOR_SERIAL_TESTS@   )
        SET( MPI_C_FOUND                @MPI_C_FOUND@                )
        SET( MPI_C_COMPILER            "@MPI_C_COMPILER@"            )
        SET( MPI_C_COMPILE_FLAGS       "@MPI_C_COMPILE_FLAGS@"       )
        SET( MPI_C_INCLUDE_DIRS        "@MPI_C_INCLUDE_DIRS@"        )
        SET( MPI_C_LINK_FLAGS          "@MPI_C_LINK_FLAGS@"          )
        SET( MPI_C_LIBRARIES           "@MPI_C_LIBRARIES@"           )
        SET( MPI_CXX_FOUND              @MPI_C_FOUND@                )
        SET( MPI_CXX_COMPILER          "@MPI_CXX_COMPILER@"          )
        SET( MPI_CXX_COMPILE_FLAGS     "@MPI_CXX_COMPILE_FLAGS@"     )
        SET( MPI_CXX_INCLUDE_DIRS      "@MPI_CXX_INCLUDE_DIRS@"      )
        SET( MPI_CXX_LINK_FLAGS        "@MPI_CXX_LINK_FLAGS@"        )
        SET( MPI_CXX_LIBRARIES         "@MPI_CXX_LIBRARIES@"         )
        SET( MPI_Fortran_FOUND          @MPI_Fortran_FOUND@          )
        SET( MPI_Fortran_COMPILER      "@MPI_Fortran_COMPILER@"      )
        SET( MPI_Fortran_COMPILE_FLAGS "@MPI_Fortran_COMPILE_FLAGS@" )
        SET( MPI_Fortran_INCLUDE_DIRS  "@MPI_Fortran_INCLUDE_DIRS@"  )
        SET( MPI_Fortran_LINK_FLAGS    "@MPI_Fortran_LINK_FLAGS@"    )
        SET( MPI_Fortran_LIBRARIES     "@MPI_Fortran_LIBRARIES@"     )
        SET( MPI_CUDA_INCLUDE_DIRS     "@MPI_CUDA_INCLUDE_DIRS@"     )
        SET( MPI_HIP_INCLUDE_DIRS      "@MPI_HIP_INCLUDE_DIRS@"      )
        SET( MPIEXEC                   "@MPIEXEC@"                   )
        SET( MPIEXEC_FLAGS              @MPIEXEC_FLAGS@              )
        SET( MPIEXEC_NUMPROC_FLAG       @MPIEXEC_NUMPROC_FLAG@       )
        SET( MPIEXEC_PREFLAGS           @MPIEXEC_PREFLAGS@           )
        SET( MPIEXEC_POSTFLAGS          @MPIEXEC_POSTFLAGS@          )
        SET( MPI_LINK_FLAGS )
        SET( MPI_LANG C CXX Fortran )
        FOREACH( lang ${MPI_LANG} )
            SET( CMAKE_${lang}_FLAGS "${CMAKE_${lang}_FLAGS} ${MPI_${lang}_COMPILE_FLAGS}" )
            SET( TPLs_INCLUDE_DIRS ${TPLs_INCLUDE_DIRS} ${MPI_${lang}_INCLUDE_DIRS} )
            SET( MPI_LINK_FLAGS "${MPI_${lang}_LINK_FLAGS} ${MPI_LINK_FLAGS}" )
        ENDFOREACH()
    ENDIF()

    # Include additional cmake files
    SET( TPLs_MACRO_CMAKE "@CMAKE_INSTALL_PREFIX@/cmake/macros.cmake" )
    SET( TPLs_WRITE_REPO "@CMAKE_INSTALL_PREFIX@/cmake/WriteRepoVersion.cmake" )
    INCLUDE( "${TPLs_MACRO_CMAKE}" )
    INCLUDE( "${TPLs_WRITE_REPO}" )

    # include the package below for some system dependent paths
    INCLUDE( GNUInstallDirs )
    
    # Get the compiler and set the compiler flags
    CHECK_ENABLE_FLAG( USE_STATIC 0 )
    SET_COMPILER_FLAGS()
    IF ( USE_STATIC )
        SET_STATIC_FLAGS()
    ENDIF()
    IF ( USE_CUDA )
         SET( CMAKE_CXX_FLAGS " ${CMAKE_CXX_FLAGS} -I${CMAKE_CUDA_TOOLKIT_INCLUDE_DIRECTORIES}" )
    ENDIF()

    # Print some flags
    IF ( NOT TPLs_FIND_QUIETLY )
        MESSAGE( STATUS "LDLIBS = ${LDLIBS}" )
        MESSAGE( STATUS "LDFLAGS = ${LDFLAGS}" )
        MESSAGE( STATUS "SYSTEM_LIBS = ${SYSTEM_LIBS}" )
        MESSAGE( STATUS "CMAKE_C_FLAGS = ${CMAKE_C_FLAGS}" )
        MESSAGE( STATUS "CMAKE_CXX_FLAGS = ${CMAKE_CXX_FLAGS}" )
        MESSAGE( STATUS "CMAKE_CUDA_FLAGS = ${CMAKE_CUDA_FLAGS}" )
        MESSAGE( STATUS "CMAKE_HIP_FLAGS = ${CMAKE_HIP_FLAGS}" )
        MESSAGE( STATUS "CMAKE_Fortran_FLAGS = ${CMAKE_Fortran_FLAGS}" )
    ENDIF()

    # Exclude user-specified directors from cmake implicit directories
    FOREACH ( dir ${USER_INCLUDE_DIRS} )
        LIST( REMOVE_ITEM CMAKE_C_IMPLICIT_INCLUDE_DIRECTORIES "${dir}")
        LIST( REMOVE_ITEM CMAKE_CXX_IMPLICIT_INCLUDE_DIRECTORIES "${dir}")
        LIST( REMOVE_ITEM CMAKE_Fortran_IMPLICIT_INCLUDE_DIRECTORIES "${dir}")
    ENDFOREACH()

    # Add user include paths / libraries
    SET( TPLs_INCLUDE_DIRS ${TPLs_INCLUDE_DIRS} ${USER_INCLUDE_DIRS} )
    SET( TPLs_LIBRARIES ${TPLs_LIBRARIES} ${USER_LIBRARIES} )

    # Set the default resource file
    IF ( NOT DEFINED CTEST_RESOURCE_SPEC_FILE )
        SET( CTEST_RESOURCE_SPEC_FILE "@CMAKE_INSTALL_PREFIX@/resources.json" )
    ENDIF()
ENDIF()


# Check which TPLs we want to include and if they are required
IF ( NOT TPLs_FIND_COMPONENTS )
    SET( TPLs_FIND_COMPONENTS ${TPLs_LIST} )
ENDIF()
FOREACH( tmp ${TPLs_LIST} )
    SET( TPLs_FIND_${tmp} FALSE )
ENDFOREACH()
FOREACH( tmp ${TPLs_FIND_COMPONENTS} )
    SET( TPLs_FIND_${tmp} TRUE )
ENDFOREACH()


# Set a quiet variable depending on the desired behavior
SET( quiet )
IF ( TPLs_FIND_QUIETLY )
    SET( quiet QUIET )
ENDIF()


# Function to configure coverage (definition only)
FUNCTION( CONFIGURE_LINE_COVERAGE )
    IF ( ENABLE_GCOV OR ENABLE_COVERAGE )
        FIND_PACKAGE( Coverage )
    ENDIF()
    IF ( COVERAGE_FOUND )
        SET( ENABLE_COVERAGE true PARENT_SCOPE )
        SET( COVERAGE_FLAGS ${COVERAGE_FLAGS} PARENT_SCOPE )
        SET( COVERAGE_LIBS  ${COVERAGE_LIBS}  PARENT_SCOPE )
    ELSE() 
        SET( ENABLE_COVERAGE false PARENT_SCOPE )
        SET( ENABLE_GCOV false PARENT_SCOPE )
    ENDIF()
ENDFUNCTION()


# Function to create a wrapper library
MACRO( ADD_TPL_LIBRARY TPL )
    IF ( NOT TARGET TPLs::${TPL} )
        ADD_LIBRARY( TPLs::${TPL} INTERFACE IMPORTED )
        TARGET_LINK_LIBRARIES( TPLs::${TPL} INTERFACE ${ARGN} )
    ENDIF()
    SET( TPLs_LIBRARIES TPLs::${TPL} ${TPLs_LIBRARIES} )
    LIST( REMOVE_DUPLICATES  TPLs::${TPL} )
    SET( TPLs_${TPL}_FOUND TRUE )
    # Set the install directory
    IF ( NOT DEFINED ${TPL}_INSTALL_DIR )
        IF( DEFINED ${TPL}_DIR )
            SET( ${TPL}_INSTALL_DIR "${${TPL}_DIR}" )
        ELSEIF ( DEFINED ${TPL}_DIRECTORY )
            SET( ${TPL}_INSTALL_DIR "${${TPL}_DIRECTORY}" )
        ELSEIF( DEFINED ${TPL}_INCLUDE_DIRECTORY )
            GET_FILENAME_COMPONENT( ${TPL}_INSTALL_DIR "${${TPL}_INCLUDE_DIRECTORY}/.." ABSOLUTE )
        ELSEIF( DEFINED ${TPL}_INCLUDE_DIR )
            GET_FILENAME_COMPONENT( ${TPL}_INSTALL_DIR "${${TPL}_INCLUDE_DIR}/.." ABSOLUTE )
        ELSE()
            MESSAGE( "Warning: install path of ${TPL} not set" )
        ENDIF()
    ENDIF()
    # Add the appropriate include directories
    IF ( NOT DEFINED ${TPL}_INCLUDE_DIR )
        IF ( DEFINED ${TPL}_INCLUDE_DIRECTORY OR DEFINED ${TPL}_INCLUDE_DIRS OR DEFINED ${TPL}_INCLUDE )
            SET( ${TPL}_INCLUDE_DIR ${${TPL}_INCLUDE_DIRS} ${${TPL}_INCLUDE} )
        ELSEIF ( DEFINED ${TPL}_INSTALL_DIR )
            SET( ${TPL}_INCLUDE_DIR "${${TPL}_INSTALL_DIR}/include" )
        ENDIF()
    ENDIF()
    FOREACH ( path ${${TPL}_INCLUDE_DIR} )
        IF ( EXISTS "${path}" )
            SET( TPLs_INCLUDE_DIRS ${TPLs_INCLUDE_DIRS} ${${TPL}_INCLUDE_DIR} )
        ENDIF()
    ENDFOREACH()
    # Set the library path
    IF ( NOT DEFINED ${TPL}_LIB_DIR AND DEFINED ${TPL}_INSTALL_DIR )
        IF ( NOT EXISTS "${${TPL}_INSTALL_DIR}" )
            MESSAGE( FATAL_ERROR "${TPL}_INSTALL_DIR set but does not exist: ${${TPL}_INSTALL_DIR}" )
        ENDIF()
        IF ( EXISTS "${${TPL}_INSTALL_DIR}/lib" )
            SET( ${TPL}_LIB_DIR "${${TPL}_INSTALL_DIR}/lib" )
        ELSEIF ( EXISTS "${${TPL}_INSTALL_DIR}/lib64" )
            SET( ${TPL}_LIB_DIR "${${TPL}_INSTALL_DIR}/lib64" )
        ELSE()
            MESSAGE( "Warning: No rpath for ${TPL}" )
        ENDIF()
    ENDIF()
    SET( CMAKE_INSTALL_RPATH ${CMAKE_INSTALL_RPATH} ${${TPL}_LIB_DIR} )
ENDMACRO()


# Add CUDA libraries
IF ( USE_CUDA )
    # Enable CUDA toolkit
    FIND_PACKAGE( CUDAToolkit )
    SET( TPLs_LIBRARIES ${TPLs_LIBRARIES} CUDA::cusparse CUDA::cublas CUDA::curand CUDA::cudart CUDA::cuda_driver )
    SET( USE_DEVICE TRUE )
ENDIF()


# Add HIP libraries
IF ( USE_HIP )
    # Enable hip API libraries
    # Note this will force the use of COMPILE_CXX_AS_HIP
    #    hiprand includes target hip::device, hip::device forces the --offload flag which is not supported be GNU
    #    Hopefully this behavior will change in the future
    FIND_PACKAGE( hipblas REQUIRED )
    FIND_PACKAGE( hiprand REQUIRED )
    FIND_PACKAGE( hipcub REQUIRED )
    SET( COMPILE_CXX_AS_HIP TRUE )
    # Enable ROCm API Libraries
    FIND_PACKAGE( rocprim REQUIRED)
    FIND_PACKAGE( rocthrust REQUIRED )
    FIND_PACKAGE( rocrand REQUIRED )
    FIND_PACKAGE( rocsparse REQUIRED )
    SET( TPLs_LIBRARIES ${TPLs_LIBRARIES} roc::rocthrust roc::hipblas hip::hiprand hip::hipcub roc::rocrand roc::rocsparse)
    SET( USE_DEVICE TRUE )
ENDIF()


# Configure MPI
IF ( USE_MPI AND NOT TPLs_MPI_FOUND )
    MESSAGE( "Configuring MPI" )
    SET( TPLs_LIST MPI ${TPLs_LIST} )
    SET( TPLs_MPI_FOUND true )
    SET( USE_EXT_MPI true )
    SET( TPLs_LIBRARIES ${TPLs_LIBRARIES} ${MPI_C_LIBRARIES} ${MPI_CXX_LIBRARIES} ${MPI_Fortran_LIBRARIES} )
ENDIF()


## Begin individual TPL configuration





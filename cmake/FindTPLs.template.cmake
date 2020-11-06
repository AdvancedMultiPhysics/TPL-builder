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
#   TPLs_FOUND            - True if headers and requested libraries were found
#   TPL_LIST              - List of TPLs that are availible
#   TPL_FOUND_${TPL}      - Was the specified TPL found
#   TPL_LIBRARIES         - TPL Libraries
#   TPL_INCLUDE_DIRS      - TPL Include paths
#   TPL_MACRO_CMAKE       - File to macros.cmake provided by the TPL install
#   TPL_CPPCHECK_CMAKE    - File to cppcheck.cmake provided by the TPL install
#   TPL_CPPCLEAN_CMAKE    - File to cppclean.cmake provided by the TPL install


# Set some cmake policies
IF ( ${CMAKE_VERSION} VERSION_GREATER_EQUAL "3.12.0" )
    CMAKE_POLICY( SET CMP0074 OLD )
ENDIF()


# Check that PROJ and ${PROJ}_INSTALL_DIR have been set
IF ( NOT PROJ )
    MESSAGE( FATAL_ERROR "PROJ must be set before calling FindTPLs")
ENDIF()
IF ( NOT ${PROJ}_INSTALL_DIR )
    MESSAGE( FATAL_ERROR "${PROJ}_INSTALL_DIR must be set before calling FindTPLs")
ENDIF()


# Print a message to indicate we started looking for TPLs
IF ( NOT TPLs_FIND_QUIETLY )
    MESSAGE( "Running FindTPLs" )
ENDIF()


# Set some basic information (should only be called once regardless of the number of calls to find_package(FindTPLs)
IF ( NOT TPLs_FOUND )

    # Set that we were able to find the TPLs (this file)
    SET( TPLs_FOUND TRUE)

    # Set the TPL list
    SET( TPL_LIST @TPL_LIST@ )

    # Include project install directory
    INCLUDE_DIRECTORIES( "${CMAKE_CURRENT_LIST_DIR}" )

    # Include project install directory
    INCLUDE_DIRECTORIES( "${${PROJ}_INSTALL_DIR}/include" )

    # Set CMAKE_MODULE_PATH
    SET( CMAKE_MODULE_PATH "@CMAKE_INSTALL_PREFIX@/cmake" ${CMAKE_MODULE_PATH} )

    # Set the compilers and compile flags
    SET( CMAKE_BUILD_TYPE   @CMAKE_BUILD_TYPE@  CACHE STRING "documentation for this variable")
    SET( ENABLE_STATIC      @ENABLE_STATIC@ )
    SET( ENABLE_SHARED      @ENABLE_SHARED@ )
    SET( DISABLE_GOLD       @DISABLE_GOLD@ )
    SET( BUILD_STATIC_LIBS  @BUILD_STATIC_LIBS@ )
    SET( BUILD_SHARED_LIBS  @BUILD_SHARED_LIBS@ )
    SET( USE_CUDA           @USE_CUDA@ )
    SET( USE_OPENMP         @USE_OPENMP@ )
    IF ( NOT CMAKE_C_COMPILER )
        SET( CMAKE_C_COMPILER    @CMAKE_C_COMPILER@    )
        SET( CMAKE_C_COMPILER_ID @CMAKE_C_COMPILER_ID@ )
        SET( CMAKE_C_FLAGS       "@CMAKE_C_FLAGS@"     )
    ENDIF()
    IF ( NOT CMAKE_CXX_COMPILER )
        SET( CMAKE_CXX_COMPILER    @CMAKE_CXX_COMPILER@    )
        SET( CMAKE_CXX_COMPILER_ID @CMAKE_CXX_COMPILER_ID@ )
        SET( CMAKE_CXX_FLAGS      "@CMAKE_CXX_FLAGS@"      )
    ENDIF()
    IF ( NOT CMAKE_CXX_STANDARD )
        SET( CMAKE_CXX_STANDARD @CMAKE_CXX_STANDARD@ )
        SET( CMAKE_CXX_EXTENSIONS OFF )
    ENDIF()
    SET( CXX_STD_FLAG ${CMAKE_CXX${CXX_STD}_STANDARD_COMPILE_OPTION} )
    ADD_DEFINITIONS( -DCXX_STD=${CMAKE_CXX_STANDARD} )
    IF ( NOT CMAKE_C_STANDARD )
        SET( CMAKE_C_STANDARD @CMAKE_C_STANDARD@ )
        SET( CMAKE_C_EXTENSIONS OFF )
    ENDIF()
    IF ( NOT CMAKE_Fortran_COMPILER )
        SET( CMAKE_Fortran_COMPILER    @CMAKE_Fortran_COMPILER@    )
        SET( CMAKE_Fortran_COMPILER_ID @CMAKE_Fortran_COMPILER_ID@ )
        SET( CMAKE_Fortran_FLAGS      "@CMAKE_Fortran_FLAGS@"      )
    ENDIF()
    IF ( CMAKE_C_COMPILER )
        ENABLE_LANGUAGE( C )
    ENDIF()
    IF ( CMAKE_CXX_COMPILER )
        ENABLE_LANGUAGE( CXX )
    ENDIF()
    IF ( CMAKE_Fortran_COMPILER )
        ENABLE_LANGUAGE( Fortran )
    ENDIF()
    IF ( USE_CUDA )
        ENABLE_LANGUAGE( CUDA )
        SET( CMAKE_CUDA_FLAGS  "@CMAKE_CUDA_FLAGS@" )
        ADD_DEFINITIONS( -DUSE_CUDA )
    ENDIF()
    IF ( USE_OPENMP )
        ADD_DEFINITIONS( -DUSE_OPENMP )
        FIND_PACKAGE( OpenMP )
    ENDIF()
    SET( LDFLAGS "@LDFLAGS@ ${LDFLAGS}" )
    SET( LDLIBS "@LDLIBS@ ${LDLIBS}" )
    SET( ENABLE_GXX_DEBUG @ENABLE_GXX_DEBUG@ )
    SET( DISABLE_GXX_DEBUG @DISABLE_GXX_DEBUG@ )
    IF ( NOT TPLs_FIND_QUIETLY )
        MESSAGE( STATUS "CMAKE_C_COMPILER = ${CMAKE_C_COMPILER}")
        MESSAGE( STATUS "CMAKE_CXX_COMPILER = ${CMAKE_CXX_COMPILER}")
        MESSAGE( STATUS "CMAKE_Fortran_COMPILER = ${CMAKE_Fortran_COMPILER}")
    ENDIF()

    # Initialize the include paths / libraries
    SET( TPL_INCLUDE_DIRS )
    SET( TPL_LIBRARIES )

    # Disable LTO
    IF ( NOT DEFINED DISABLE_LTO )
        SET( DISABLE_LTO @DISABLE_LTO@ )
    ENDIF()

    # Include additional cmake files
    SET( TPL_MACRO_CMAKE "@CMAKE_INSTALL_PREFIX@/cmake/macros.cmake" )
    INCLUDE( "${TPL_MACRO_CMAKE}" )
    INCLUDE( "@CMAKE_INSTALL_PREFIX@/cmake/WriteRepoVersion.cmake" )

    # Get the compiler and set the compiler flags
    CHECK_ENABLE_FLAG( USE_STATIC 0 )
    SET_COMPILER_FLAGS()
    IF ( USE_STATIC )
        SET_STATIC_FLAGS()
    ENDIF()

    # Add system dependent flags that are commonly used
    MESSAGE( STATUS "System is: ${CMAKE_SYSTEM_NAME}" )
    IF ( ${CMAKE_SYSTEM_NAME} STREQUAL "Windows" )
        # Windows specific system libraries
        SET( SYSTEM_PATHS "C:/Program Files (x86)/Microsoft SDKs/Windows/v7.0A/Lib/x64"
                          "C:/Program Files (x86)/Microsoft Visual Studio 8/VC/PlatformSDK/Lib/AMD64"
                          "C:/Program Files (x86)/Microsoft Visual Studio 12.0/Common7/Packages/Debugger/X64" )
        FIND_LIBRARY( PSAPI_LIB    NAMES Psapi    PATHS ${SYSTEM_PATHS}  NO_DEFAULT_PATH )
        FIND_LIBRARY( DBGHELP_LIB  NAMES DbgHelp  PATHS ${SYSTEM_PATHS}  NO_DEFAULT_PATH )
        FIND_LIBRARY( DBGHELP_LIB  NAMES DbgHelp )
        IF ( PSAPI_LIB )
            ADD_DEFINITIONS( -DPSAPI )
            SET( SYSTEM_LIBS ${PSAPI_LIB} )
        ENDIF()
        IF ( DBGHELP_LIB )
            ADD_DEFINITIONS( -DDBGHELP )
            SET( SYSTEM_LIBS ${DBGHELP_LIB} )
        ELSE()
            MESSAGE( WARNING "Did not find DbgHelp, stack trace will not be availible" )
        ENDIF()
        MESSAGE( STATUS "System libs: ${SYSTEM_LIBS}" )
    ELSEIF( ${CMAKE_SYSTEM_NAME} STREQUAL "Linux" )
        # Linux specific system libraries
        SET( SYSTEM_LIBS -lz -lpthread -ldl )
        IF ( NOT USE_STATIC )
            # Try to add rdynamic so we have names in backtrace
            SET( CMAKE_REQUIRED_FLAGS "${CMAKE_CXX_FLAGS} ${COVERAGE_FLAGS} -rdynamic" )
            CHECK_CXX_SOURCE_COMPILES( "int main() { return 0;}" rdynamic )
            IF ( rdynamic )
                SET( SYSTEM_LDFLAGS ${SYSTEM_LDFLAGS} -rdynamic )
            ENDIF()
        ENDIF()
        IF ( USING_GFORTRAN )
            SET( SYSTEM_LIBS ${SYSTEM_LIBS} -lgfortran )
        ENDIF()
        IF ( USING_GCC )
            SET( CMAKE_C_FLAGS   " ${CMAKE_C_FLAGS} -fPIC" )
            SET( CMAKE_CXX_FLAGS " ${CMAKE_CXX_FLAGS} -fPIC" )
        ENDIF()
    ELSEIF( ${CMAKE_SYSTEM_NAME} STREQUAL "Darwin" )
        # Max specific system libraries
        SET( SYSTEM_LIBS -lz -lpthread -ldl )
    ELSEIF( ${CMAKE_SYSTEM_NAME} STREQUAL "Generic" )
        # Generic system libraries
    ELSE()
        MESSAGE( FATAL_ERROR "OS not detected" )
    ENDIF()
    # Print some flags
    IF ( NOT TPLs_FIND_QUIETLY )
        MESSAGE( STATUS "LDLIBS = ${LDLIBS}" )
        MESSAGE( STATUS "LDFLAGS = ${LDFLAGS}" )
        MESSAGE( STATUS "SYSTEM_LIBS = ${SYSTEM_LIBS}" )
        MESSAGE( STATUS "CMAKE_C_FLAGS = ${CMAKE_C_FLAGS}" )
        MESSAGE( STATUS "CMAKE_CXX_FLAGS = ${CMAKE_CXX_FLAGS}" )
        MESSAGE( STATUS "CMAKE_Fortran_FLAGS = ${CMAKE_Fortran_FLAGS}" )
    ENDIF()

ENDIF()


# Check which TPLs we want to include and if they are required
IF ( NOT TPLs_FIND_COMPONENTS )
    SET( TPLs_FIND_COMPONENTS ${TPL_LIST} )
ENDIF()
FOREACH( tmp ${TPL_LIST} )
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


# Configure MPI
SET( USE_MPI @USE_MPI@ )
IF ( USE_MPI AND NOT TPL_FOUND_MPI )
    MESSAGE( "Configuring MPI" )
    SET( TPL_LIST MPI ${TPL_LIST} )
    SET( MPI_LANG C CXX Fortran )
    # Set user flags that control the behavior of FindMPI.cmake (or are used by subsequent projects)
    SET( USE_MPI_FOR_SERIAL_TESTS   @USE_MPI_FOR_SERIAL_TESTS@  )
    SET( MPI_C_FOUND                @MPI_C_FOUND@               )
    SET( MPI_C_COMPILER            "@MPI_C_COMPILER@"           )
    SET( MPI_C_COMPILE_FLAGS       "@MPI_C_COMPILE_FLAGS@"      )
    SET( MPI_C_INCLUDE_PATH        "@MPI_C_INCLUDE_PATH@"       )
    SET( MPI_C_LINK_FLAGS          "@MPI_C_LINK_FLAGS@"         )
    SET( MPI_C_LIBRARIES           "@MPI_C_LIBRARIES@"          )
    SET( MPI_CXX_FOUND              @MPI_C_FOUND@               )
    SET( MPI_CXX_COMPILER          "@MPI_C_COMPILER@"           )
    SET( MPI_CXX_COMPILE_FLAGS     "@MPI_C_COMPILE_FLAGS@"      )
    SET( MPI_CXX_INCLUDE_PATH      "@MPI_C_INCLUDE_PATH@"       )
    SET( MPI_CXX_LINK_FLAGS        "@MPI_C_LINK_FLAGS@"         )
    SET( MPI_CXX_LIBRARIES         "@MPI_C_LIBRARIES@"          )
    SET( MPI_Fortran_FOUND          @MPI_C_FOUND@               )
    SET( MPI_Fortran_COMPILER      "@MPI_C_COMPILER@"           )
    SET( MPI_Fortran_COMPILE_FLAGS "@MPI_C_COMPILE_FLAGS@"      )
    SET( MPI_Fortran_INCLUDE_PATH  "@MPI_C_INCLUDE_PATH@"       )
    SET( MPI_Fortran_LINK_FLAGS    "@MPI_C_LINK_FLAGS@"         )
    SET( MPI_Fortran_LIBRARIES     "@MPI_C_LIBRARIES@"          )
    SET( MPIEXEC                   "@MPIEXEC@"                  )
    SET( MPIEXEC_NUMPROC_FLAG       @MPIEXEC_NUMPROC_FLAG@      )
    SET( MPIEXEC_PREFLAGS           @MPIEXEC_PREFLAGS@          )
    SET( MPIEXEC_POSTFLAGS          @MPIEXEC_POSTFLAGS@         )
    SET( USE_EXT_MPI true )
    SET( TPL_FOUND_MPI true )
    ADD_DEFINITIONS( -DUSE_MPI )
    ADD_DEFINITIONS( -DUSE_EXT_MPI )
    FOREACH( lang ${MPI_LANG} )
        SET( CMAKE_${lang}_FLAGS "${CMAKE_${lang}_FLAGS} ${MPI_${lang}_COMPILE_FLAGS}" )
        SET( TPL_INCLUDE_DIRS ${TPL_INCLUDE_DIRS} ${MPI_${lang}_INCLUDE_PATH} )
        SET( TPL_LIBRARIES ${MPI_${lang}_LIBRARIES} ${TPL_LIBRARIES} )
    ENDFOREACH()
ENDIF()


## Begin individual TPL configuration





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


# Check that PROJ and ${PROJ}_INSTALL_DIR have been set
IF ( NOT PROJ )
    MESSAGE( FATAL_ERROR "PROJ must be set before calling FindTPLs")
ENDIF()
IF ( NOT ${PROJ}_INSTALL_DIR )
    MESSAGE( FATAL_ERROR "${PROJ}_INSTALL_DIR must be set before calling FindTPLs")
ENDIF()


# Set some basic information (should only be called once regardless of the number of calls to find_package(FindTPLs)
IF ( NOT TPLs_FOUND )

    # Set that we were able to find the TPLs (this file)
    SET( TPLs_FOUND TRUE)

    # Set the TPL list
    SET( TPL_LIST @TPL_LIST@ )

    # Include project install directory
    INCLUDE_DIRECTORIES( "${${PROJ}_INSTALL_DIR}/include" )

    # Set CMAKE_MODULE_PATH
    SET( CMAKE_MODULE_PATH "${TPL_DIRECTORY}/cmake" ${CMAKE_MODULE_PATH} )

    # Set the compilers and compile flags
    SET( CMAKE_BUILD_TYPE   @CMAKE_BUILD_TYPE@  CACHE STRING "documentation for this variable")
    SET( ENABLE_STATIC      @ENABLE_STATIC@ )
    SET( ENABLE_SHARED      @ENABLE_SHARED@ )
    SET( BUILD_STATIC_LIBS  @BUILD_STATIC_LIBS@ )
    SET( BUILD_SHARED_LIBS  @BUILD_SHARED_LIBS@ )
    IF ( NOT CMAKE_C_COMPILER )
        SET( CMAKE_C_COMPILER @CMAKE_C_COMPILER@ )
        SET( CMAKE_C_FLAGS    "@CMAKE_C_FLAGS@"  )
    ENDIF()
    IF ( NOT CMAKE_CXX_COMPILER )
        SET( CMAKE_CXX_COMPILER @CMAKE_CXX_COMPILER@ )
        SET( CMAKE_CXX_FLAGS    "@CMAKE_CXX_FLAGS@"  )
    ENDIF()
    IF ( NOT CXX_STD )
        SET( CMAKE_CXX_STANDARD @CMAKE_CXX_STANDARD@ )
        SET( CXX_STD            "@CXX_STD@"          )
        SET( CXX_STD_FLAG       "@CXX_STD_FLAG@"     )
    ENDIF()
    IF ( NOT CMAKE_Fortran_COMPILER )
        SET( CMAKE_Fortran_COMPILER @CMAKE_Fortran_COMPILER@ )
        SET( CMAKE_Fortran_FLAGS    @CMAKE_Fortran_FLAGS@    )
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
    SET( LDFLAGS @LDFLAGS@ )
    SET( ENABLE_GXX_DEBUG @ENABLE_GXX_DEBUG@ )
    SET( DISABLE_GXX_DEBUG @DISABLE_GXX_DEBUG@ )
    MESSAGE("CMAKE_C_COMPILER = ${CMAKE_C_COMPILER}")
    MESSAGE("CMAKE_CXX_COMPILER = ${CMAKE_CXX_COMPILER}")
    MESSAGE("CMAKE_Fortran_COMPILER = ${CMAKE_Fortran_COMPILER}")

    # Initialize the include paths / libraries
    SET( TPL_INCLUDE_DIRS )
    SET( TPL_LIBRARIES )

    # Set the path to macros.cmake
    SET( TPL_MACRO_CMAKE "@CMAKE_INSTALL_PREFIX@/macros.cmake" )
    INCLUDE( "${TPL_MACRO_CMAKE}" )

    # Get the compiler and set the compiler flags
    IDENTIFY_COMPILER()
    CHECK_ENABLE_FLAG( USE_STATIC 0 )
    SET_COMPILER_FLAGS()
    IF ( USE_STATIC )
        SET_STATIC_FLAGS()
    ENDIF()

    # Add system dependent flags that are commonly used
    MESSAGE("System is: ${CMAKE_SYSTEM_NAME}")
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
        MESSAGE("System libs: ${SYSTEM_LIBS}")
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
        IF ( USING_GCC )
            SET( SYSTEM_LIBS ${SYSTEM_LIBS} -lgfortran )
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
    MESSAGE( "LDLIBS = ${LDLIBS}" )
    MESSAGE( "SYSTEM_LIBS = ${SYSTEM_LIBS}" )
    MESSAGE( "CMAKE_C_FLAGS = ${CMAKE_C_FLAGS}" )
    MESSAGE( "CMAKE_CXX_FLAGS = ${CMAKE_CXX_FLAGS}" )

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


## Begin individual TPL configuration





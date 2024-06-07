INCLUDE(CheckCCompilerFlag)
INCLUDE(CheckCSourceCompiles)
INCLUDE(CheckCXXCompilerFlag)
INCLUDE(CheckCXXSourceCompiles)
IF ( ${CMAKE_VERSION} VERSION_GREATER_EQUAL "3.18.0")
    INCLUDE(CheckLinkerFlag)
ENDIF()
INCLUDE( ADD_TPL.cmake )



# Dummy use to prevent unused cmake variable warning
MACRO( NULL_USE VAR )
    FOREACH( var ${VAR} )
        IF ( "${${var}}" STREQUAL "dummy_string" )
            MESSAGE( FATAL_ERROR "NULL_USE fail" )
        ENDIF()
    ENDFOREACH()
ENDMACRO()
NULL_USE( CMAKE_C_FLAGS )


# Macro to set a global variable
MACRO( GLOBAL_SET VARNAME )
    SET(${VARNAME} ${ARGN} CACHE INTERNAL "")
ENDMACRO()


# Macro to print all variables
MACRO( PRINT_ALL_VARIABLES )
    GET_CMAKE_PROPERTY(_variableNames VARIABLES)
    FOREACH ( _variableName ${_variableNames} )
        MESSAGE( STATUS "${_variableName}=${${_variableName}}" )
    ENDFOREACH()
ENDMACRO()


# Macro to clean whitespace
MACRO( CLEAN_WHITESPACE VAR )
    IF ( DEFINED VAR )
        IF ( NOT "${${VAR}}" STREQUAL "" )
            STRING( STRIP ${${VAR}} ${VAR} )
            STRING( REPLACE "  " " " ${VAR} "${${VAR}}" )
            STRING( REPLACE "  " " " ${VAR} "${${VAR}}" )
            STRING( REPLACE "  " " " ${VAR} "${${VAR}}" )
        ENDIF()
    ENDIF()
ENDMACRO()


# CMake assert
MACRO( ASSERT test comment )
    IF (NOT ${test})
        MESSSAGE(FATAL_ERROR "Assertion failed: ${comment}")
    ENDIF(NOT ${test})
ENDMACRO(ASSERT)


# Macro to set the compile/link flags
MACRO( SET_DEFAULT_TPL TPL VAR VAL )
    IF ( (NOT ${TPL}_URL) AND (NOT ${TPL}_SRC_DIR) AND (NOT ${TPL}_INSTALL_DIR) )
        SET( ${TPL}_${VAR} "${VAL}" )
    ENDIF()
ENDMACRO()


# Macro to verify that a variable has been set
MACRO( VERIFY_VARIABLE VARIABLE_NAME )
    IF ( NOT ${VARIABLE_NAME} )
        MESSAGE( FATAL_ERROR "PLease set: " ${VARIABLE_NAME} )
    ENDIF()
ENDMACRO()


# Macro to verify that a path has been set
MACRO( VERIFY_PATH PATH_NAME )
    IF ("${PATH_NAME}" STREQUAL "")
        MESSAGE ( FATAL_ERROR "Path is not set: ${PATH_NAME}" )
    ENDIF()
    IF ( NOT EXISTS "${PATH_NAME}" )
        MESSAGE( FATAL_ERROR "Path does not exist: ${PATH_NAME}" )
    ENDIF()
ENDMACRO()


# Macro to identify the compiler
MACRO( IDENTIFY_COMPILER )
    # SET the C/C++ compiler
    IF ( CMAKE_C_COMPILER_WORKS OR CMAKE_CXX_COMPILER_WORKS )
        IF( USING_GCC OR CMAKE_COMPILER_IS_GNUCC OR CMAKE_COMPILER_IS_GNUCXX OR
            (${CMAKE_C_COMPILER_ID} MATCHES "GNU") OR (${CMAKE_CXX_COMPILER_ID} MATCHES "GNU") )
            SET( USING_GCC TRUE )
            ADD_DEFINITIONS( -DUSING_GCC )
            MESSAGE("Using gcc")
        ELSEIF( USING_MSVC OR MSVC OR MSVC_IDE OR MSVC60 OR MSVC70 OR MSVC71 OR MSVC80 OR CMAKE_COMPILER_2005 OR MSVC90 OR MSVC10 )
            IF( NOT ${CMAKE_SYSTEM_NAME} STREQUAL "Windows" )
                MESSAGE( FATAL_ERROR "Using microsoft compilers on non-windows system?" )
            ENDIF()
            SET( USING_MSVC TRUE )
            ADD_DEFINITIONS( -DUSING_MSVC )
            MESSAGE("Using Microsoft")
        ELSEIF( USING_ICC OR (${CMAKE_C_COMPILER_ID} MATCHES "Intel") OR (${CMAKE_CXX_COMPILER_ID} MATCHES "Intel") ) 
            SET(USING_ICC TRUE)
            ADD_DEFINITIONS( -DUSING_ICC )
            MESSAGE("Using icc")
        ELSEIF( USING_PGCC OR (${CMAKE_C_COMPILER_ID} MATCHES "PGI") OR (${CMAKE_CXX_COMPILER_ID} MATCHES "PGI") )
            SET(USING_PGCC TRUE)
            ADD_DEFINITIONS( -DUSING_PGCC )
            MESSAGE("Using pgCC")
        ELSEIF( USING_CRAY OR (${CMAKE_C_COMPILER_ID} MATCHES "CRAY") OR (${CMAKE_CXX_COMPILER_ID} MATCHES "CRAY") OR
                              (${CMAKE_C_COMPILER_ID} MATCHES "Cray") OR (${CMAKE_CXX_COMPILER_ID} MATCHES "Cray") )
            SET(USING_CRAY TRUE)
            ADD_DEFINITIONS( -DUSING_CRAY )
            MESSAGE("Using Cray")
        ELSEIF( USING_CLANG OR (${CMAKE_C_COMPILER_ID} MATCHES "CLANG") OR (${CMAKE_CXX_COMPILER_ID} MATCHES "CLANG") OR
                               (${CMAKE_C_COMPILER_ID} MATCHES "Clang") OR (${CMAKE_CXX_COMPILER_ID} MATCHES "Clang") )
            SET(USING_CLANG TRUE)
            ADD_DEFINITIONS( -DUSING_CLANG )
            MESSAGE("Using Clang")
        ELSEIF( USING_XL OR (${CMAKE_C_COMPILER_ID} MATCHES "XL") OR (${CMAKE_CXX_COMPILER_ID} MATCHES "XL") )
            SET(USING_XL TRUE)
            ADD_DEFINITIONS( -DUSING_XL )
            MESSAGE("Using XL")
        ELSE()
            MESSAGE( "CMAKE_C_COMPILER=${CMAKE_C_COMPILER}")
            MESSAGE( "CMAKE_CXX_COMPILER=${CMAKE_CXX_COMPILER}")
            MESSAGE( "CMAKE_C_COMPILER_ID=${CMAKE_C_COMPILER_ID}")
            MESSAGE( "CMAKE_CXX_COMPILER_ID=${CMAKE_CXX_COMPILER_ID}")
            MESSAGE(FATAL_ERROR "Unknown C/C++ compiler")
        ENDIF()
    ENDIF()
    # SET the Fortran compiler
    IF ( CMAKE_Fortran_COMPILER_WORKS )
        IF( CMAKE_COMPILER_IS_GNUG77 OR (${CMAKE_Fortran_COMPILER_ID} MATCHES "GNU") )
            SET( USING_GFORTRAN TRUE )
            MESSAGE("Using gfortran")
            IF ( NOT USING_GCC )
                LIST( REMOVE_ITEM CMAKE_Fortran_IMPLICIT_LINK_LIBRARIES gcc )
            ENDIF()
        ELSEIF ( (${CMAKE_Fortran_COMPILER_ID} MATCHES "Intel") ) 
            SET(USING_IFORT TRUE)
            MESSAGE("Using ifort")
        ELSEIF ( ${CMAKE_Fortran_COMPILER_ID} MATCHES "PGI")
            SET(USING_PGF90 TRUE)
            MESSAGE("Using pgf90")
        ELSEIF( (${CMAKE_Fortran_COMPILER_ID} MATCHES "CRAY") OR (${CMAKE_Fortran_COMPILER_ID} MATCHES "Cray") )
            SET(USING_CRAY TRUE)
            MESSAGE("Using Cray")
        ELSEIF ( (${CMAKE_Fortran_COMPILER_ID} MATCHES "CLANG") OR (${CMAKE_Fortran_COMPILER_ID} MATCHES "Clang") OR
                 (${CMAKE_Fortran_COMPILER_ID} MATCHES "FLANG") OR (${CMAKE_Fortran_COMPILER_ID} MATCHES "Flang") )
            SET(USING_FLANG TRUE)
            MESSAGE("Using flang")
        ELSEIF( USING_XL OR (${CMAKE_Fortran_COMPILER_ID} MATCHES "XL") )
            SET(USING_XL TRUE)
            ADD_DEFINITIONS( -DUSING_XL )
            MESSAGE("Using XL")
        ELSE()
            MESSAGE( "CMAKE_Fortran_COMPILER=${CMAKE_Fortran_COMPILER}")
            MESSAGE( "CMAKE_Fortran_COMPILER_ID=${CMAKE_Fortran_COMPILER_ID}")
            MESSAGE(FATAL_ERROR "Unknown Fortran compiler (${CMAKE_Fortran_COMPILER_ID})")
        ENDIF()
    ENDIF()
ENDMACRO()


# Macro to add user c++ std 
MACRO( SET_CXX_STD )
    # Set the C++ standard
    SET( CMAKE_CXX_EXTENSIONS OFF )
    IF ( NOT CMAKE_CXX_STANDARD )
        IF ( CXX_STD )
            IF ( ${CXX_STD} STREQUAL "NONE" )
                # Do nothing
            ELSEIF ( "${CXX_STD}" MATCHES "^(98|11|14|17|20|23|26)$" )
                SET( CMAKE_CXX_STANDARD ${CXX_STD} )
                SET( CXX_STD_FLAG ${CMAKE_CXX${CXX_STD}_STANDARD_COMPILE_OPTION} )
            ELSE()
                MESSAGE( FATAL_ERROR "Unknown C++ standard ${CXX_STD} (98,11,14,17,20,23,26,NONE)" )
            ENDIF()
        ELSE()
            MESSAGE( FATAL_ERROR "C++ standard is not set" )
        ENDIF()
    ENDIF()
    # Set the C standard
    IF ( NOT CMAKE_C_STANDARD )
        IF ( C_STD )
            IF ( ${C_STD} STREQUAL "NONE" )
                # Do nothing
            ELSEIF ( "${CXX_STD}" MATCHES "^(90|99|11|17|23)$" )
                SET( CMAKE_C_STANDARD ${C_STD} )
            ELSE()
                MESSAGE( FATAL_ERROR "Unknown C standard ${C_STD} (90,99,11,17,23,NONE)" )
            ENDIF()
        ELSEIF ( CMAKE_CXX_STANDARD )
            IF ( "${CMAKE_CXX_STANDARD}" STREQUAL "98" )
                SET( CMAKE_C_STANDARD 99 )
            ELSEIF ( "${CMAKE_CXX_STANDARD}" MATCHES "^(11|14)$" )
                SET( CMAKE_C_STANDARD 11 )
            ELSEIF ( "${CMAKE_CXX_STANDARD}" MATCHES "^(17|20)$" )
                SET( CMAKE_C_STANDARD 17 )
            ELSEIF ( "${CMAKE_CXX_STANDARD}" MATCHES "^(23|26)$" )
                SET( CMAKE_C_STANDARD 26 )
            ELSE()
                MESSAGE( FATAL_ERROR "Unknown C++ standard" )
            ENDIF()
        ELSE()
            MESSAGE( FATAL_ERROR "C standard is not set" )
        ENDIF()
    ENDIF()
    ADD_DEFINITIONS( -DCXX_STD=${CXX_STD} )
ENDMACRO()


# Macro to set the compile/link flags
MACRO( SET_COMPILER_DEFAULTS )
    # Initilaize the compiler
    IDENTIFY_COMPILER()
    # Set the compiler flags to use
    IF ( ${CMAKE_BUILD_TYPE} STREQUAL "Debug" OR ${CMAKE_BUILD_TYPE} STREQUAL "DEBUG")
        SET(CMAKE_C_FLAGS       "${CMAKE_C_FLAGS_DEBUG} -D_DEBUG"   )
        SET(CMAKE_CXX_FLAGS     "${CMAKE_CXX_FLAGS_DEBUG} -D_DEBUG" )
        SET(CMAKE_Fortran_FLAGS "${CMAKE_Fortran_FLAGS_DEBUG}"      )
    ELSEIF ( ${CMAKE_BUILD_TYPE} STREQUAL "Release" OR ${CMAKE_BUILD_TYPE} STREQUAL "RELEASE")
        SET(CMAKE_C_FLAGS       ${CMAKE_C_FLAGS_RELEASE}       )
        SET(CMAKE_CXX_FLAGS     ${CMAKE_CXX_FLAGS_RELEASE}     )
        SET(CMAKE_Fortran_FLAGS ${CMAKE_Fortran_FLAGS_RELEASE} )
    ELSEIF ( ${CMAKE_BUILD_TYPE} STREQUAL "RelWithDebInfo" OR ${CMAKE_BUILD_TYPE} STREQUAL "RELWITHDEBINFO")
        SET(CMAKE_C_FLAGS       "-g ${CMAKE_C_FLAGS_RELEASE}"       )
        SET(CMAKE_CXX_FLAGS     "-g ${CMAKE_CXX_FLAGS_RELEASE}"     )
        SET(CMAKE_Fortran_FLAGS "-g ${CMAKE_Fortran_FLAGS_RELEASE}" )
    ELSE()
        MESSAGE(FATAL_ERROR "Unknown value for CMAKE_BUILD_TYPE = ${CMAKE_BUILD_TYPE}")
    ENDIF()
    # Set the behavior of GLIBCXX flags
    CHECK_ENABLE_FLAG( ENABLE_GXX_DEBUG 0 )
    IF ( ENABLE_GXX_DEBUG ) 
        # Enable GLIBCXX_DEBUG flags
        SET( CMAKE_C_FLAGS_DEBUG   " ${CMAKE_C_FLAGS_DEBUG}   -D_GLIBCXX_DEBUG -D_GLIBCXX_DEBUG_PEDANTIC" )
        SET( CMAKE_CXX_FLAGS_DEBUG " ${CMAKE_CXX_FLAGS_DEBUG} -D_GLIBCXX_DEBUG -D_GLIBCXX_DEBUG_PEDANTIC" )
        SET( DISABLE_GXX_DEBUG OFF )
    ELSEIF ( DISABLE_GXX_DEBUG ) 
        # Disable GLIBCXX_DEBUG flags
        SET( DISABLE_GXX_DEBUG OFF )
    ELSE()
        # Default
        SET( DISABLE_GXX_DEBUG ON )
    ENDIF()
    # Add the user flags
    SET(CMAKE_C_FLAGS   " ${CMAKE_C_FLAGS} ${CFLAGS} ${CFLAGS_EXTRA}" )
    SET(CMAKE_CXX_FLAGS " ${CMAKE_CXX_FLAGS} ${CXXFLAGS} ${CXXFLAGS_EXTRA}" )
    SET(CMAKE_Fortran_FLAGS " ${CMAKE_Fortran_FLAGS} ${FFLAGS} ${FFLAGS_EXTRA}" )
    # Add the c++ standard flags
    SET_CXX_STD()
    # Test the compile flags
    CHECK_C_COMPILER_FLAG( "${CMAKE_C_FLAGS}" CHECK_C_FLAGS )
    CHECK_CXX_COMPILER_FLAG( "${CMAKE_CXX_FLAGS}" CHECK_CXX_FLAGS )
    IF ( NOT ${CHECK_C_FLAGS} )
        MESSAGE(FATAL_ERROR "Invalid C flags detected")
    ENDIF()
    IF ( NOT ${CHECK_CXX_FLAGS} )
        MESSAGE(FATAL_ERROR "Invalid CXX flags detected")
    ENDIF()
    # Add the shared/static flags
    IF ( (NOT ENABLE_SHARED) AND (NOT ENABLE_STATIC) ) 
        SET( ENABLE_STATIC )
    ELSEIF ( ENABLE_SHARED AND ENABLE_STATIC )
        MESSAGE(FATAL_ERROR "Building both static and shared libraries simultaneously is not currently supported")
    ELSEIF ( ENABLE_SHARED ) 
        SET( BUILD_SHARED_LIBS TRUE )
        SET( CMAKE_ARGS "-DBUILD_SHARED_LIBS:BOOL=TRUE;-DLIB_TYPE=SHARED" )
        SET( CMAKE_C_FLAGS "${CMAKE_C_FLAGS}" )
        SET( CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS}" )
        SET( CMAKE_Fortran_FLAGS "${CMAKE_Fortran_FLAGS}" )
        SET( ENV_LDFLAGS "${CMAKE_SHARED_LINKER_FLAGS}" )
        SET( LIB_TYPE STATIC )
    ELSE()
        SET( BUILD_SHARED_LIBS FALSE )
        SET( CMAKE_ARGS "-DBUILD_SHARED_LIBS:BOOL=FALSE;-DLIB_TYPE=STATIC" )
        SET( CMAKE_C_FLAGS "${CMAKE_C_FLAGS}" )
        SET( CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS}" )
        SET( ENV_LDFLAGS "${CMAKE_STATIC_LINKER_FLAGS}" )
        SET( LIB_TYPE SHARED )
    ENDIF()
ENDMACRO()


# Set ENV_VARS and CMAKE_ARGS
MACRO( SET_CMAKE_ARGS )
	FOREACH ( LANG C CXX Fortran CUDA HIP )
        SET( ENV_${LANG}_FLAGS "${CMAKE_${LANG}_FLAGS} ${MPI_${LANG}_COMPILE_FLAGS}" )
        FOREACH ( tmp ${MPI_${LANG}_INCLUDE_PATH} )
            SET( ENV_${LANG}_FLAGS "${ENV_${LANG}_FLAGS} -I${tmp}" )
        ENDFOREACH()
        CLEAN_WHITESPACE( ENV_${LANG}_FLAGS )
    ENDFOREACH()
    SET( LDFLAGS "${LDFLAGS} ${ENV_LDFLAGS}" )
    SET( ENV_VARS CC=${CMAKE_C_COMPILER} CFLAGS=${ENV_C_FLAGS} )
    SET( ENV_VARS ${ENV_VARS} CXX=${CMAKE_CXX_COMPILER} CXXFLAGS=${ENV_CXX_FLAGS} )
    SET( ENV_VARS ${ENV_VARS} F77=${CMAKE_Fortran_COMPILER} FFLAGS=${ENV_Fortran_FLAGS} )
    SET( ENV_VARS ${ENV_VARS} FC=${CMAKE_Fortran_COMPILER} FCFLAGS=${ENV_Fortran_FLAGS} )
    SET( ENV_LDFLAGS "${LDFLAGS} ${LDLIBS} ${MPI_CXX_LINK_FLAGS}" )
    SET( ENV_LIBS "${OpenMP_CXX_LIBRARIES} ${MPI_CXX_LIBRARIES} ${MPI_C_LIBRARIES} ${MPI_Fortran_LIBRARIES}" )
    STRING( REGEX REPLACE ";" " " ENV_LIBS "${ENV_LIBS}")
    CLEAN_WHITESPACE( ENV_LIBS )
    CLEAN_WHITESPACE( ENV_LDFLAGS )
    IF ( ${CMAKE_VERSION} VERSION_GREATER_EQUAL "3.18.0")
        check_linker_flag( C -ldl  test_dl )
        IF ( test_dl )
            SET( ENV_LIBS "${ENV_LIBS} -ldl" )
            SET( CMAKE_SHARED_LINKER_FLAGS "${CMAKE_SHARED_LINKER_FLAGS} -ldl" )
        ENDIF()
    ENDIF()
    MESSAGE( "ENV_LIBS=${ENV_LIBS}" )
    SET( ENV_VARS ${ENV_VARS} LD=${CMAKE_LINKER} LDFLAGS=${ENV_LDFLAGS} LIBS=${ENV_LIBS} )
    MESSAGE( "ENV_VARS=${ENV_VARS}" )
    SET( CMAKE_ARGS "${CMAKE_ARGS};-DCMAKE_C_COMPILER=${CMAKE_C_COMPILER}" )
    SET( CMAKE_ARGS "${CMAKE_ARGS};-DCMAKE_C_FLAGS=${CMAKE_C_FLAGS}" )
    SET( CMAKE_ARGS "${CMAKE_ARGS};-DCMAKE_CXX_COMPILER=${CMAKE_CXX_COMPILER}" )
    SET( CMAKE_ARGS "${CMAKE_ARGS};-DCMAKE_CXX_FLAGS=${CMAKE_CXX_FLAGS};" )
    SET( CMAKE_ARGS "${CMAKE_ARGS};-DCMAKE_CXX_EXTENSIONS=${CMAKE_CXX_EXTENSIONS}" )
    SET( CMAKE_ARGS "${CMAKE_ARGS};-DCMAKE_CXX_STANDARD=${CMAKE_CXX_STANDARD}" )
    SET( CMAKE_ARGS "${CMAKE_ARGS};-DCMAKE_Fortran_COMPILER=${CMAKE_Fortran_COMPILER}" )
    SET( CMAKE_ARGS "${CMAKE_ARGS};-DCMAKE_Fortran_FLAGS=${CMAKE_Fortran_FLAGS};" )
    SET( CMAKE_ARGS "${CMAKE_ARGS};-DCMAKE_SHARED_LINKER_FLAGS=${CMAKE_SHARED_LINKER_FLAGS}" )
    IF ( USE_CUDA )
        SET( CMAKE_ARGS "${CMAKE_ARGS};-DCMAKE_CUDA_COMPILER=${CMAKE_CUDA_COMPILER}" )
        SET( CMAKE_ARGS "${CMAKE_ARGS};-DCMAKE_CUDA_FLAGS=${CMAKE_CUDA_FLAGS};" )
    ENDIF()
    IF ( USE_HIP )
        SET( CMAKE_ARGS "${CMAKE_ARGS};-DCMAKE_HIP_COMPILER=${CMAKE_HIP_COMPILER}" )
        SET( CMAKE_ARGS "${CMAKE_ARGS};-DCMAKE_HIP_FLAGS=${CMAKE_HIP_FLAGS};" )
    ENDIF()
    # Write variables to cmake file
ENDMACRO()


# Macro to check if a flag is enabled
MACRO( CHECK_ENABLE_FLAG FLAG DEFAULT )
    IF( NOT DEFINED ${FLAG} )
        SET( ${FLAG} ${DEFAULT} )
    ELSEIF( ${FLAG}  STREQUAL "" )
        SET( ${FLAG} ${DEFAULT} )
    ELSEIF( ( ${${FLAG}} STREQUAL "false" ) OR ( ${${FLAG}} STREQUAL "0" ) OR ( ${${FLAG}} STREQUAL "OFF" ) )
        SET( ${FLAG} 0 )
    ELSEIF( ( ${${FLAG}} STREQUAL "true" ) OR ( ${${FLAG}} STREQUAL "1" ) OR ( ${${FLAG}} STREQUAL "ON" ) )
        SET( ${FLAG} 1 )
    ELSE()
        MESSAGE( "Bad value for ${FLAG} (${${FLAG}}); use true or false" )
    ENDIF()
ENDMACRO()


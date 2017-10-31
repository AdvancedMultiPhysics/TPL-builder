# FindCppcheck
# ---------
#
# Find cppcheck
#
# Use this module by invoking find_package with the form:
#
#   find_package( Cppcheck
#     [REQUIRED]             # Fail with error if the cppcheck is not found
#   )
#
# This module finds cppcheck and configures a test using the provided options
#
# This program reconizes the following options
#   CPPCHECK_INCLUDE      - List of include folders
#   CPPCHECK_OPTIONS      - List of cppcheck options
#   CPPCHECK_SOURCE       - Source path to check
#   CPPCHECK_TIMEOUT      - Timeout for each cppcheck test (default is 5 minutes)
#
# The following variables are set by find_package( Cppcheck )
#
#   CPPCHECK_FOUND        - True if cppcheck was found


# Find cppcheck if availible
FIND_PROGRAM( CPPCHECK 
    NAMES cppcheck cppcheck.exe 
    PATHS "${CPPCHECK_DIRECTORY}" "C:/Program Files/Cppcheck" "C:/Program Files (x86)/Cppcheck" 
)
IF ( CPPCHECK )
    SET( CPPCHECK_FOUND TRUE )
ELSE()
    SET( CPPCHECK_FOUND FALSE )
ENDIF()
IF ( CPPCHECK_FOUND )
    EXECUTE_PROCESS( COMMAND ${CPPCHECK} --version OUTPUT_VARIABLE CPPCHECK_VERSION OUTPUT_STRIP_TRAILING_WHITESPACE )
    MESSAGE( STATUS "Using cppcheck: ${CPPCHECK_VERSION}")
ELSEIF ( CPPCHECK_FIND_REQUIRED )
    MESSAGE( FATAL_ERROR "cppcheck not found")
ELSE()
    MESSAGE( STATUS "cppcheck not found")
ENDIF()


# Set the source directory (if not set)
IF ( NOT DEFINED CPPCHECK_SOURCE )
    IF ( DEFINED ${PROJ}_SOURCE_DIR )
        SET( CPPCHECK_SOURCE "${${PROJ}_SOURCE_DIR}" )
    ELSE()
        SET( CPPCHECK_SOURCE "${CMAKE_CURRENT_SOURCE_DIR}" )
    ENDIF()
ENDIF()


# Function to add a cppcheck tests
FUNCTION( ADD_CPPCHECK_TEST TESTNAME SRCDIR )

    # Check if SRCDIR has been processed by CMake
    STRING(REGEX REPLACE "${PROJECT_SOURCE_DIR}" "${PROJECT_BINARY_DIR}" BINDIR "${SRCDIR}" )
    SET( PROCESSED FALSE )
    IF ( EXISTS "${BINDIR}" )
        SET( PROCESSED TRUE )
    ENDIF()

    # Set the options for cppcheck
    IF ( NOT DEFINED CPPCHECK_OPTIONS )
        SET( CPPCHECK_OPTIONS -q --enable=all --suppress=missingIncludeSystem 
            "--suppressions-list=${PROJECT_SOURCE_DIR}/cppcheckSuppressionFile" )
        IF ( CXX_STD STREQUAL 98 )
            SET( CPPCHECK_OPTIONS ${CPPCHECK_OPTIONS} --std=c99 --std=c++03 --std=posix )
        ELSEIF ( CXX_STD STREQUAL 11 )
            SET( CPPCHECK_OPTIONS ${CPPCHECK_OPTIONS} --std=c11 --std=c++11 --std=posix )
        ELSEIF ( CXX_STD STREQUAL 14 )
            SET( CPPCHECK_OPTIONS ${CPPCHECK_OPTIONS} --std=c11 --std=c++11 --std=posix )
        ENDIF()
        # Set definitions
        IF ( PROCESSED )
            GET_DIRECTORY_PROPERTY( DirDefs DIRECTORY "${SRCDIR}" COMPILE_DEFINITIONS )
        ELSE()
            GET_DIRECTORY_PROPERTY( DirDefs DIRECTORY "${PROJECT_SOURCE_DIR}" COMPILE_DEFINITIONS )
        ENDIF()
        FOREACH( def ${DirDefs} )
            SET( CPPCHECK_OPTIONS ${CPPCHECK_OPTIONS} -D${def} )
        ENDFOREACH()
        # Set OS specific defines
        IF ( WIN32 )
            SET( CPPCHECK_OPTIONS ${CPPCHECK_OPTIONS} -DWIN32 )
        ELSEIF( APPLE )
            SET( CPPCHECK_OPTIONS ${CPPCHECK_OPTIONS} -D__APPLE__ )
        ELSEIF( UNIX )
            SET( CPPCHECK_OPTIONS ${CPPCHECK_OPTIONS} -D__unix )
        ENDIF()
    ENDIF()

    # Add the include paths
    IF( NOT DEFINED CPPCHECK_INCLUDE )
        SET( CPPCHECK_INCLUDE )
        IF ( PROCESSED )
            GET_PROPERTY( dirs DIRECTORY "${SRCDIR}" PROPERTY INCLUDE_DIRECTORIES )
        ELSE()
            GET_PROPERTY( dirs DIRECTORY "${PROJECT_SOURCE_DIR}" PROPERTY INCLUDE_DIRECTORIES )
        ENDIF()
        LIST( REMOVE_DUPLICATES dirs )
        FOREACH(dir ${dirs})
            SET( CPPCHECK_INCLUDE ${CPPCHECK_INCLUDE} "-I${dir}" )
        ENDFOREACH()
    ENDIF()

    # Set the timeout
    IF ( NOT DEFINED CPPCHECK_TIMEOUT )
        SET( CPPCHECK_TIMEOUT 300 )
    ENDIF()

    # Add the test
    ADD_TEST( ${TESTNAME} ${CPPCHECK} ${CPPCHECK_OPTIONS} --error-exitcode=1  ${CPPCHECK_INCLUDE} "${SRCDIR}" )
    SET_TESTS_PROPERTIES( ${TESTNAME} PROPERTIES PROCESSORS 1 TIMEOUT ${CPPCHECK_TIMEOUT} COST ${CPPCHECK_TIMEOUT} )

ENDFUNCTION()


# Add the test(s)
IF ( CPPCHECK )
    LIST(LENGTH CPPCHECK_SOURCE src_len)
    IF ( src_len GREATER 1 )
        # Multiple src directories
        FOREACH(src ${CPPCHECK_SOURCE})
            FILE(GLOB child RELATIVE "${CMAKE_CURRENT_SOURCE_DIR}" "${src}" )
            ADD_CPPCHECK_TEST( cppcheck-${child} "${src}" )
        ENDFOREACH()
    ELSE()
        # Find the number of files to determine if we want one (or multiple) cppcheck commands
        FILE(GLOB_RECURSE SRCS "${CPPCHECK_SOURCE}/*.cpp" "${CPPCHECK_SOURCE}/*.cc" "${CPPCHECK_SOURCE}/*.c" )
        LIST(LENGTH SRCS len)
        IF ( len LESS 100 OR CPPCHECK_SERIALIZE )
            ADD_CPPCHECK_TEST( cppcheck "${CPPCHECK_SOURCE}" )
        ELSE()
            FILE(GLOB children RELATIVE "${CPPCHECK_SOURCE}" "${CPPCHECK_SOURCE}/*" )
            FOREACH(child ${children})
                FILE(GLOB_RECURSE SRCS "${CPPCHECK_SOURCE}/${child}/*.cpp" "${CPPCHECK_SOURCE}/${child}/*.cc" "${CPPCHECK_SOURCE}/${child}/*.c" )
                LIST(LENGTH SRCS len)
                IF ( (IS_DIRECTORY ${CPPCHECK_SOURCE}/${child}) AND (len GREATER 0) )
                    ADD_CPPCHECK_TEST( cppcheck-${child} "${CPPCHECK_SOURCE}/${child}" )
                ENDIF()
            ENDFOREACH()
        ENDIF()
    ENDIF()
ENDIF()

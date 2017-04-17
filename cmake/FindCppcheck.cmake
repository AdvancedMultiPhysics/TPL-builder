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


# Set the options for cppcheck
IF ( NOT DEFINED CPPCHECK_OPTIONS )
    SET( CPPCHECK_OPTIONS -q --enable=all --force --suppress=missingIncludeSystem 
        "--suppressions-list=${CMAKE_CURRENT_SOURCE_DIR}/cppcheckSuppressionFile" )
    IF ( CXX_STD STREQUAL 98 )
        SET( CPPCHECK_OPTIONS ${CPPCHECK_OPTIONS} --std=c99 --std=c++03 --std=posix )
    ELSEIF ( CXX_STD STREQUAL 11 )
        SET( CPPCHECK_OPTIONS ${CPPCHECK_OPTIONS} --std=c11 --std=c++11 --std=posix )
    ELSEIF ( CXX_STD STREQUAL 14 )
        SET( CPPCHECK_OPTIONS ${CPPCHECK_OPTIONS} --std=c11 --std=c++11 --std=posix )
    ENDIF()
ENDIF()
IF( NOT DEFINED CPPCHECK_INCLUDE )
    SET( CPPCHECK_INCLUDE )
    GET_PROPERTY( dirs DIRECTORY "${CMAKE_CURRENT_SOURCE_DIR}" PROPERTY INCLUDE_DIRECTORIES )
    LIST( REMOVE_DUPLICATES dirs )
    FOREACH(dir ${dirs})
        SET( CPPCHECK_INCLUDE ${CPPCHECK_INCLUDE} "-I${dir}" )
    ENDFOREACH()
ENDIF()
IF ( NOT DEFINED CPPCHECK_SOURCE )
    IF ( DEFINED ${PROJ}_SOURCE_DIR )
        SET( CPPCHECK_SOURCE "${${PROJ}_SOURCE_DIR}" )
    ELSE()
        SET( CPPCHECK_SOURCE "${CMAKE_CURRENT_SOURCE_DIR}" )
    ENDIF()
ENDIF()


# Add the test
IF ( CPPCHECK )
    LIST(LENGTH CPPCHECK_SOURCE src_len)
    IF ( src_len GREATER 1 )
        # Multiple src directories
        FOREACH(src ${CPPCHECK_SOURCE})
            FILE(GLOB child RELATIVE "${CMAKE_CURRENT_SOURCE_DIR}" "${src}" )
            ADD_TEST( cppcheck-${child} ${CPPCHECK} ${CPPCHECK_OPTIONS} --error-exitcode=1  ${CPPCHECK_INCLUDE} "${src}" )
        ENDFOREACH()
    ELSE()
        # Find the number of files to determine if we want one (or multiple) cppcheck commands
        FILE(GLOB_RECURSE SRCS "${CPPCHECK_SOURCE}/*.cpp" "${CPPCHECK_SOURCE}/*.cc" "${CPPCHECK_SOURCE}/*.c" )
        LIST(LENGTH SRCS len)
        IF ( len LESS 100 OR CPPCHECK_DIR )
            ADD_TEST( cppcheck ${CPPCHECK} ${CPPCHECK_OPTIONS} --error-exitcode=1  ${CPPCHECK_INCLUDE} "${CPPCHECK_SOURCE}" )
            IF( ${CPPCHECK_DIR} )
                SET_TESTS_PROPERTIES( ${TEST_NAME} PROPERTIES WORKING_DIRECTORY "${CPPCHECK_DIR}" PROCESSORS 1 )
            ENDIF()
        ELSE()
            FILE(GLOB children RELATIVE "${CPPCHECK_SOURCE}" "${CPPCHECK_SOURCE}/*" )
            SET(dirlist "")
            FOREACH(child ${children})
                IF(IS_DIRECTORY ${CPPCHECK_SOURCE}/${child})
                    ADD_TEST( cppcheck-${child} ${CPPCHECK} ${CPPCHECK_OPTIONS} --error-exitcode=1  ${CPPCHECK_INCLUDE} "${CPPCHECK_SOURCE}/${child}" )
                    LIST(APPEND dirlist ${child})
                ENDIF()
            ENDFOREACH()
        ENDIF()
    ENDIF()
ENDIF()


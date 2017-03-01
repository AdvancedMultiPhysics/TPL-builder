SET( CPPCLEAN @CPPCLEAN@ )
SET( CPPCLEAN_OPTIONS @CPPCLEAN_OPTIONS@ )
SET( CPPCLEAN_INCLUDE @CPPCLEAN_INCLUDE@ )
SET( CPPCLEAN_EXCLUDE @CPPCLEAN_EXCLUDE@ )
SET( CPPCLEAN_SOURCE  @CPPCLEAN_SOURCE@ )
SET( CPPCLEAN_OUTPUT  @CPPCLEAN_OUTPUT@ )
SET( CPPCLEAN_ERROR   @CPPCLEAN_ERROR@ )
SET( CPPCLEAN_SUPPRESSIONS "@CPPCLEAN_SUPPRESSIONS@" )
SET( CPPCLEAN_UNNECESSARY_INCLUDE @CPPCLEAN_UNNECESSARY_INCLUDE@ )
SET( CPPCLEAN_EXTRA_INCLUDE @CPPCLEAN_EXTRA_INCLUDE@ )
SET( CPPCLEAN_SHOULD_INCLUDE @CPPCLEAN_SHOULD_INCLUDE@ )
SET( CPPCLEAN_INCLUDE_NOT_FOUND @CPPCLEAN_INCLUDE_NOT_FOUND@ )
SET( CPPCLEAN_FUN_NOT_FOUND @CPPCLEAN_FUN_NOT_FOUND@ )
SET( CPPCLEAN_DECLARED @CPPCLEAN_DECLARED@ )
SET( CPPCLEAN_STATIC @CPPCLEAN_STATIC@ )
SET( CPPCLEAN_FORWARD_DECLARE @CPPCLEAN_FORWARD_DECLARE@ )
SET( CPPCLEAN_UNUSED_VARIABLE @CPPCLEAN_UNUSED_VARIABLE@ )
SET( CPPCLEAN_UNKNOWN @CPPCLEAN_UNKNOWN@ )


# Set include/exclude options
FOREACH(dir ${CPPCLEAN_INCLUDE})
    SET( CPPCLEAN_OPTIONS ${CPPCLEAN_OPTIONS} "--include-path='${dir}'" )
ENDFOREACH()
FOREACH(file ${CPPCLEAN_EXCLUDE})
    SET( CPPCLEAN_OPTIONS ${CPPCLEAN_OPTIONS} "--exclude '${file}'" )
ENDFOREACH()


# Get the final list of suppressions
SET( SUPPRESSIONS ${CPPCLEAN_SUPPRESSIONS} 
    "'shared_ptr.h' does not need to be #included"
    "'ProfilerApp.h' does not need to be #included"
)


# Run cppclean
EXECUTE_PROCESS( COMMAND ${CPPCLEAN} ${CPPCLEAN_OPTIONS} "${CPPCLEAN_SOURCE}"
   OUTPUT_FILE "${CPPCLEAN_OUTPUT}" 
   ERROR_FILE  "${CPPCLEAN_ERROR}"
   RESULT_VARIABLE RESULT 
)


# Function to split a line in the file path, file name, line number, and message
MACRO( SPLIT_LINE MESSAGE1 FILEPATH FILENAME LINE MESSAGE2 )
    STRING( REPLACE ":" ";" ${MESSAGE2} "${MESSAGE1}" )
    LIST( LENGTH ${MESSAGE2} LEN )
    IF ( "${LEN}" MATCHES "2" )
        LIST( GET ${MESSAGE2} 0 ${FILEPATH} )
        LIST( REMOVE_AT ${MESSAGE2} 0 )
    ELSEIF ( "${LEN}" MATCHES "3" )
        LIST( GET ${MESSAGE2} 1 ${LINE} )
        LIST( GET ${MESSAGE2} 0 ${FILEPATH} )
        LIST( REMOVE_AT ${MESSAGE2} 0 1 )
    ELSE()
       RETURN()
    ENDIF()
    STRING( REPLACE ";" ":" ${MESSAGE2} "${${MESSAGE2}}" )
    STRING( REPLACE "/" "/;" ${FILEPATH} "${${FILEPATH}}" )
    LIST( GET ${FILEPATH} -1 ${FILENAME} )
    LIST( REMOVE_AT ${FILEPATH} -1 )
    STRING( REPLACE ";" "" ${FILEPATH} "${${FILEPATH}}" )
ENDMACRO()


# Check the results
FILE(READ "${CPPCLEAN_OUTPUT}" OUTPUT )
STRING(REGEX REPLACE ";"  "\\\\;" OUTPUT "${OUTPUT}")
STRING(REGEX REPLACE "\n"  ";"    OUTPUT "${OUTPUT}")
SET( UNNECESSARY_INCLUDE )
SET( EXTRA_INCLUDE )
SET( SHOULD_INCLUDE )
SET( INCLUDE_NOT_FOUND )
SET( FUN_NOT_FOUND )
SET( UNUSED_VARIABLE )
SET( DECLARED )
SET( STATIC )
SET( UNKNOWN )
SET( FORWARD_DECLARE )
FOREACH( line ${OUTPUT} )
    SET( FOUND_IN_SUPPRESSIONS 0 )
    FOREACH( tmp ${SUPPRESSIONS} )
        IF ( "${line}" MATCHES "${tmp}" )
           SET( FOUND_IN_SUPPRESSIONS 1 ) 
        ENDIF()
    ENDFOREACH()
    IF ( ${FOUND_IN_SUPPRESSIONS} )
        # Suppress message
    ELSEIF ( "${line}" MATCHES "" )
        # Empty line
    ELSEIF ( ( "${line}" MATCHES "use a forward declaration instead" ) OR
             ( "${line}" MATCHES "forward declaration not expected" ) )
        SET( FORWARD_DECLARE ${FORWARD_DECLARE} "${line}" )
    ELSEIF ( "${line}" MATCHES "does not need to be #included" )
        # Remove includes of .hpp files within .h files
        SPLIT_LINE( "${line}" FILEPATH FILENAME LINE MESSAGE2 )
        STRING( REPLACE ".h" ".hpp" FILEHEADER "${FILENAME}" )
        IF ( NOT "${MESSAGE2}" MATCHES "${FILEHEADER}" )
            SET( UNNECESSARY_INCLUDE ${UNNECESSARY_INCLUDE} "${line}" )
        ENDIF()
    ELSEIF ( "${line}" MATCHES "already #included" )
        SET( EXTRA_INCLUDE ${EXTRA_INCLUDE} "${line}" )
    ELSEIF ( "${line}" MATCHES "should #include header file" )
        # Remove lines to include the same header as cpp file (may be included using include tree)
        SPLIT_LINE( "${line}" FILEPATH FILENAME LINE MESSAGE2 )
        STRING( REPLACE ".cpp" ".h" FILEHEADER "${FILEPATH}${FILENAME}" )
        STRING( REPLACE ".cu"  ".h" FILEHEADER "${FILEHEADER}" )
        IF ( NOT "${MESSAGE2}" MATCHES "${FILEHEADER}" )
            SET( SHOULD_INCLUDE ${SHOULD_INCLUDE} "${line}" )
        ENDIF()
    ELSEIF ( "${line}" MATCHES "unable to find" )
        SET( INCLUDE_NOT_FOUND ${INCLUDE_NOT_FOUND} "${line}" )
    ELSEIF ( "${line}" MATCHES "not found in any directly" )
        SET( FUN_NOT_FOUND ${FUN_NOT_FOUND} "${line}" )
    ELSEIF ( "${line}" MATCHES "not found in expected header" )
        SET( FUN_NOT_FOUND ${FUN_NOT_FOUND} "${line}" )
    ELSEIF ( "${line}" MATCHES "declared but not defined" )
        SET( DECLARED ${DECLARED} "${line}" )
    ELSEIF ( "${line}" MATCHES "static data" )
        SET( STATIC ${STATIC} "${line}" )
    ELSEIF ( "${line}" MATCHES "unused variable" )
        SET( UNUSED_VARIABLE ${UNUSED_VARIABLE} "${line}" )
    ELSE ()
        SET( UNKNOWN ${UNKNOWN} "${line}" )
    ENDIF()
ENDFOREACH()

# Print the results
SET( ERR 0 )
IF ( CPPCLEAN_UNNECESSARY_INCLUDE )
    MESSAGE(STATUS "UNNECESSARY_INCLUDE:")
    FOREACH( line ${UNNECESSARY_INCLUDE} )
        MESSAGE(${line})
    ENDFOREACH()
    MESSAGE("")
    LIST(LENGTH UNNECESSARY_INCLUDE len)
    MATH(EXPR ERR "${ERR}+${len}")
ENDIF()
IF ( CPPCLEAN_EXTRA_INCLUDE )
    MESSAGE(STATUS "EXTRA_INCLUDE:")
    FOREACH( line ${EXTRA_INCLUDE} )
        MESSAGE(${line})
    ENDFOREACH()
    MESSAGE("")
    LIST(LENGTH EXTRA_INCLUDE len)
    MATH(EXPR ERR "${ERR}+${len}")
ENDIF()
IF ( CPPCLEAN_SHOULD_INCLUDE )
    MESSAGE(STATUS "SHOULD_INCLUDE:")
    FOREACH( line ${SHOULD_INCLUDE} )
        MESSAGE(${line})
    ENDFOREACH()
    MESSAGE("")
    LIST(LENGTH SHOULD_INCLUDE len)
    MATH(EXPR ERR "${ERR}+${len}")
ENDIF()
IF ( CPPCLEAN_DECLARED )
    MESSAGE(STATUS "DECLARED:")
    FOREACH( line ${DECLARED} )
        MESSAGE(${line})
    ENDFOREACH()
    MESSAGE("")
    LIST(LENGTH DECLARED len)
    MATH(EXPR ERR "${ERR}+${len}")
ENDIF()
IF ( CPPCLEAN_UNUSED_VARIABLE )
    MESSAGE(STATUS "UNUSED_VARIABLE:")
    FOREACH( line ${UNUSED_VARIABLE} )
        MESSAGE(${line})
    ENDFOREACH()
    MESSAGE("")
    LIST(LENGTH UNUSED_VARIABLE len)
    MATH(EXPR ERR "${ERR}+${len}")
ENDIF()
IF ( CPPCLEAN_FORWARD_DECLARE )
    MESSAGE(STATUS "FORWARD DECLARE:")
    FOREACH( line ${FORWARD_DECLARE} )
        MESSAGE(${line})
    ENDFOREACH()
    MESSAGE("")
    LIST(LENGTH FORWARD_DECLARE len)
    MATH(EXPR ERR "${ERR}+${len}")
ENDIF()
IF ( CPPCLEAN_UNKNOWN )
    MESSAGE(STATUS "UNKNOWN:")
    FOREACH( line ${UNKNOWN} )
        MESSAGE(${line})
    ENDFOREACH()
    MESSAGE("")
    LIST(LENGTH UNKNOWN len)
    MATH(EXPR ERR "${ERR}+${len}")
ENDIF()


# Return
IF ( "${ERR}" STREQUAL "0" )
    MESSAGE("All tests passed")
ELSE()
    MESSAGE("${ERR} warnings detected")
ENDIF()
RETURN()

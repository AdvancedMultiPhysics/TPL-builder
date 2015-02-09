# Check success based on if we find TPL-done
IF ( EXISTS "${TPL}-done" )
    MESSAGE( "${TPL} completed: ")
    SET( filename "${CMAKE_CURRENT_SOURCE_DIR}/time" )
    IF ( EXISTS "${filename}" )
        INCLUDE( "${CMAKE_CURRENT_LIST_DIR}/print_elapsed.cmake" )
    ENDIF()
    RETURN()
ENDIF()

# We did not complete, print useful information
MESSAGE( "${TPL} did not complete" )

# List the directory contents
FILE( GLOB FILE_LIST "${CMAKE_CURRENT_LIST_DIR}/*" )
FOREACH( filename ${FILE_LIST} )
    MESSAGE( "${filename}" )
ENDFOREACH()

# Print the logs for the step the fails
SET( steps configure build install )
FOREACH( step ${steps} )
    If ( (EXISTS "${TPL}-${step}-out.log") AND (NOT EXISTS "${TPL}-${step}") )
        MESSAGE( "${step} failed:" )
        FILE( READ "${TPL}-${step}-out.log" out_log )
        FILE( READ "${TPL}-${step}-err.log" err_log )
        MESSAGE( "${TPL}-${step}-out.log:\n${out_log}" )
        MESSAGE( "${TPL}-${step}-err.log:\n${err_log}" )
        RETURN()
    ENDIF()
ENDFOREACH()


STRING( TIMESTAMP time "%d|%H|%M|%S" )
IF ( ${append} )
    FILE( APPEND "${filename}" "${time}\n" )
ELSE()
    FILE( WRITE "${filename}" "${time}\n" )
ENDIF()



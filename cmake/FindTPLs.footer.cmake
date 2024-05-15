# Check that all desired TPLs were found
FOREACH ( TPL ${TPL_LIST} )
    IF ( NOT TPL_FOUND_${TPL} AND TPLs_FIND_${TPL} )
        IF ( TPLs_FIND_REQUIRED_${TPL} )
            MESSAGE( ERROR "${TPL} not found" )
        ELSE()
            MESSAGE( "  ${TPL} not found" )
        ENDIF()
    ENDIF()
ENDFOREACH()
SET( TPL_LIST_FOUND )       # List of all TPLs found/linked
SET( TPL_LIST_INCLUDED )    # List of TPLs found and not disabled
FOREACH( TPL ${TPL_LIST} )
    IF ( TPL_FOUND_${TPL} ) 
        SET( TPL_LIST_FOUND ${TPL_LIST_FOUND} ${TPL} )
        IF ( NOT DISABLE_${TPL} )
            SET( TPL_LIST_INCLUDED ${TPL_LIST_INCLUDED} ${TPL} )
        ENDIF()
    ENDIF()
ENDFOREACH()


# Write the TPLs.h
SET( TPLs_HEADER "${CMAKE_CURRENT_BINARY_DIR}/tmp/TPLs.h" )
FILE( WRITE "${TPLs_HEADER}" "// This file sets the TPL list for C/C++ codes\n")
FILE( APPEND "${TPLs_HEADER}" "#ifndef TPL_LIST\n")
FILE( APPEND "${TPLs_HEADER}" "#define TPL_LIST \"${TPL_LIST}\"\n")
FILE( APPEND "${TPLs_HEADER}" "#endif\n")
FILE( APPEND "${TPLs_HEADER}" "#ifndef ${PROJ}_TPL_LIST\n")
FILE( APPEND "${TPLs_HEADER}" "#define ${PROJ}_TPL_LIST \"${TPL_LIST_INCLUDED}\"\n")
FOREACH( TPL ${TPL_LIST} )
    IF ( TPL_FOUND_${TPL} AND NOT DISABLE_${TPL} )
        SET( USE_${TPL} TRUE )
        FILE( APPEND "${TPLs_HEADER}" "#define ${PROJ}_USE_${TPL}\n")
        FOREACH( tmp ${${TPL}_PACKAGE_LIST} )
             STRING(TOUPPER ${tmp} tmp)
             FILE( APPEND "${TPLs_HEADER}" "#define ${PROJ}_USE_${TPL}_${tmp}\n")
        ENDFOREACH()
    ENDIF()
ENDFOREACH()
FILE( APPEND "${TPLs_HEADER}" "#endif\n")
EXECUTE_PROCESS( COMMAND ${CMAKE_COMMAND} -E copy_if_different "${TPLs_HEADER}" "${${PROJ}_INSTALL_DIR}/include/${${PROJ}_INC}/${PROJ}_TPLs.h" )



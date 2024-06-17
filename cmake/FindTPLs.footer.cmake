# Check that all desired TPLs were found
FOREACH ( TPL ${TPLs_LIST} )
    IF ( NOT TPLs_${TPL}_FOUND AND TPLs_FIND_${TPL} )
        IF ( TPLs_FIND_REQUIRED_${TPL} )
            MESSAGE( ERROR "${TPL} not found" )
        ELSE()
            MESSAGE( "  ${TPL} not found" )
        ENDIF()
    ENDIF()
ENDFOREACH()
SET( TPLs_LIST_FOUND )       # List of all TPLs found/linked
SET( TPLs_LIST_INCLUDED )    # List of TPLs found and not disabled
FOREACH( TPL ${TPLs_LIST} )
    IF ( TPLs_${TPL}_FOUND ) 
        SET( ${TPL}_FOUND true )
        SET( TPLs_LIST_FOUND ${TPLs_LIST_FOUND} ${TPL} )
        IF ( NOT DISABLE_${TPL} )
            SET( TPLs_LIST_INCLUDED ${TPLs_LIST_INCLUDED} ${TPL} )
        ENDIF()
    ENDIF()
ENDFOREACH()


# Clean up some lists
LIST( REMOVE_DUPLICATES TPLs_INCLUDE_DIRS )
LIST( REMOVE_DUPLICATES CMAKE_INSTALL_RPATH )


# Write the TPLs.h
SET( TPLs_HEADER "${CMAKE_CURRENT_BINARY_DIR}/tmp/TPLs.h" )
FILE( WRITE "${TPLs_HEADER}" "// This file sets the TPL list for C/C++ codes\n")
FILE( APPEND "${TPLs_HEADER}" "#ifndef TPL_LIST\n")
FILE( APPEND "${TPLs_HEADER}" "#define TPL_LIST \"${TPLs_LIST}\"\n")
FILE( APPEND "${TPLs_HEADER}" "#endif\n")
FILE( APPEND "${TPLs_HEADER}" "#ifndef ${PROJ}_TPL_LIST\n")
FILE( APPEND "${TPLs_HEADER}" "#define ${PROJ}_TPL_LIST \"${TPLs_LIST_INCLUDED}\"\n")
FOREACH( TPL ${TPLs_LIST} )
    IF ( TPLs_${TPL}_FOUND AND NOT DISABLE_${TPL} )
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


# Check that all components were found (not finished)
CHECK_REQUIRED_COMPONENTS( TPLs )



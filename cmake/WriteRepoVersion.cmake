FUNCTION( WRITE_REPO_VERSION )

    # Check the inputs
    IF ( NOT PROJ )
        MESSAGE( FATAL_ERROR "PROJ is not set")
    ENDIF()
    IF ( NOT IS_DIRECTORY "${${PROJ}_SOURCE_DIR}" )
        MESSAGE( FATAL_ERROR "Repo path ${${PROJ}_SOURCE_DIR} does not exist")
    ENDIF()
    SET( src_dir "${${PROJ}_SOURCE_DIR}" )

    # Set the output filename
    SET( filename "${${PROJ}_INSTALL_DIR}/include/${PROJ}_Version.h" )

    # Check if a version file exists in the src tree
    IF ( EXISTS "${src_dir}/${PROJ}_Version.h" )
        EXECUTE_PROCESS( COMMAND ${CMAKE_COMMAND} -E copy_if_different "${src_dir}/${PROJ}_Version.h" "${filename}" )
        RETURN()
    ENDIF()

    # Check if we are dealing with mercurial
    EXECUTE_PROCESS( COMMAND hg head  WORKING_DIRECTORY "${src_dir}"  OUTPUT_VARIABLE HG_INFO )
    IF ( "${HG_INFO}" MATCHES "changeset")
        WRITE_HG_INFO()
        RETURN()
    ENDIF()

    # Unable to obtain version info
    MESSAGE( FATAL_ERROR "No version information" )

ENDFUNCTION()


FUNCTION( WRITE_HG_INFO )

    # Get the repo version
    EXECUTE_PROCESS( COMMAND hg id -i  WORKING_DIRECTORY "${src_dir}"  OUTPUT_VARIABLE VERSION_OUT )
    EXECUTE_PROCESS( COMMAND hg log --limit 1 --template "{rev};{node}"  WORKING_DIRECTORY "${src_dir}" OUTPUT_VARIABLE VERSION_REV_OUT  )
    STRING(REGEX REPLACE "(\r?\n)+$" "" short_hash "${VERSION_OUT}")
    LIST(GET VERSION_REV_OUT 0 rev )
    LIST(GET VERSION_REV_OUT 1 long_hash )

    # Write the results to the file
    STRING(REGEX REPLACE " " "_" namespace "${PROJ}")
    SET( tmp_file "${CMAKE_CURRENT_BINARY_DIR}/tmp/version.h" )
    FILE(WRITE  "${tmp_file}" "#ifndef ${PROJ}_VERSION_INCLUDE\n#define ${PROJ}_VERSION_INCLUDE\n\n" )
    FILE(APPEND "${tmp_file}" "namespace ${namespace} {\nnamespace Version{\n\n" )
    FILE(APPEND "${tmp_file}" "static const int major = 0;\n" )
    FILE(APPEND "${tmp_file}" "static const int minor = 0;\n" )
    FILE(APPEND "${tmp_file}" "static const int build = ${rev};\n" )
    FILE(APPEND "${tmp_file}" "static const char short_hash[] = \"${short_hash}\";\n" )
    FILE(APPEND "${tmp_file}" "static const char long_hash[] = \"${long_hash}\";\n" )

    IF ( WRITE_ALL_CHANGESETS )
        # Get all changesets
        EXECUTE_PROCESS( COMMAND hg log --template "{rev}\n"  WORKING_DIRECTORY "${src_dir}"  OUTPUT_VARIABLE VERSION_REV_OUT  )
        EXECUTE_PROCESS( COMMAND hg log --template "{node}\n" WORKING_DIRECTORY "${src_dir}"  OUTPUT_VARIABLE VERSION_NODE_OUT )
        STRING(REGEX REPLACE "\n" ", " VERSION_REV_OUT "${VERSION_REV_OUT}")
        STRING(REGEX REPLACE "\n" "\", \"" VERSION_NODE_OUT "\"${VERSION_NODE_OUT}")
        STRING(REGEX REPLACE ", ;"   "" VERSION_REV_OUT  "${VERSION_REV_OUT};"  )
        STRING(REGEX REPLACE ", \";" "" VERSION_NODE_OUT "${VERSION_NODE_OUT};" )
        LIST( LENGTH VERSION_REV_OUT OUTPUT_LENGTH )
        # Write the results to the file
        FILE(APPEND "${tmp_file}" "static const int ${PROJ}_REV[] = { ${VERSION_REV_OUT} };\n\n" )
        FILE(APPEND "${tmp_file}" "static const char *${PROJ}_id[] = { ${VERSION_NODE_OUT} };\n\n" )
    ENDIF()

    FILE(APPEND "${tmp_file}" "\n}\n}\n#endif\n" )

    # Copy the file only if it is different (to avoid rebuilding project)
    EXECUTE_PROCESS( COMMAND ${CMAKE_COMMAND} -E copy_if_different "${tmp_file}" "${filename}" )
    MESSAGE("${PROJ} Version = ${VERSION_OUT}")

ENDFUNCTION()

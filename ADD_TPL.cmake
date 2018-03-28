# Macro to create a distclean target
MACRO( ADD_DISTCLEAN )
    SET( DISTCLEAN_CMDS )
    FOREACH( tmp ${TPL_LIST} )
        STRING(TOLOWER ${tmp} tmp2)
        SET( DISTCLEAN_CMDS ${DISTCLEAN_CMDS} COMMAND ${CMAKE_COMMAND} -E remove_directory ${tmp}-prefix )
        SET( DISTCLEAN_CMDS ${DISTCLEAN_CMDS} COMMAND ${CMAKE_COMMAND} -E remove_directory "${CMAKE_INSTALL_PREFIX}/${tmp2}" )
    ENDFOREACH()
    ADD_CUSTOM_TARGET(
        distclean
        COMMAND ${CMAKE_COMMAND} -E remove_directory "${CMAKE_INSTALL_PREFIX}/logs"
        COMMAND ${CMAKE_COMMAND} -E remove_directory "${CMAKE_INSTALL_PREFIX}/cmake"
        COMMAND ${CMAKE_COMMAND} -E remove           "${CMAKE_INSTALL_PREFIX}/TPLs.h"
        COMMAND ${CMAKE_COMMAND} -E remove           "${CMAKE_INSTALL_PREFIX}/FindTPLs.cmake"
        COMMAND ${CMAKE_COMMAND} -E remove           "${CMAKE_INSTALL_PREFIX}/macros.cmake"
        COMMAND ${CMAKE_COMMAND} -E remove_directory "${CMAKE_INSTALL_PREFIX}/LapackWrappers"
        COMMAND ${CMAKE_COMMAND} -E remove_directory "${CMAKE_INSTALL_PREFIX}/tests"
        COMMAND ${CMAKE_COMMAND} -E remove_directory tmp
        COMMAND ${CMAKE_COMMAND} -E remove_directory CMakeFiles
        COMMAND ${CMAKE_COMMAND} -E remove_directory Testing
        COMMAND ${CMAKE_COMMAND} -E remove_directory environment-prefix
        COMMAND ${CMAKE_COMMAND} -E remove_directory LAPACK_WRAPPERS-prefix
        COMMAND ${CMAKE_COMMAND} -E remove_directory TPLS_Test-prefix
        COMMAND ${CMAKE_COMMAND} -E remove CMakeCache.txt cmake_install.cmake CTestTestfile.cmake DartConfiguration.tcl Makefile
        ${DISTCLEAN_CMDS}
        WORKING_DIRECTORY "${CMAKE_CURRENT_BINARY_DIR}" 
    )
ENDMACRO()


# Macro to create a TPL-clean target
MACRO( ADD_TPL_CLEAN TPL )
    SET( tpl_cmds ${TPL}-build ${TPL}-pre-configure ${TPL}-configure ${TPL}-done 
        ${TPL}-download ${TPL}-download-impl ${TPL}-mkdir ${TPL}-patch ${TPL}-install 
        ${TPL}-build-test ${TPL}-test ${TPL}-check-test ${TPL}-update ${TPL}-post-install )
    SET( RM_LIST )
    FOREACH( tmp ${tpl_cmds} )
        SET( RM_LIST ${RM_LIST} ${tmp} ${tmp}-err.log ${tmp}-out.log )
    ENDFOREACH()
    IF ( ${TPL}_INSTALL_DIR )
        ADD_CUSTOM_TARGET( 
            ${TPL}-clean
            ${CMAKE_COMMAND}         -E remove_directory ../${TPL}-build
            COMMAND ${CMAKE_COMMAND} -E make_directory   ../${TPL}-build
            COMMAND ${CMAKE_COMMAND} -E remove ${RM_LIST}
            COMMAND ${CMAKE_COMMAND} -E remove_directory "${${TPL}_INSTALL_DIR}"
            COMMAND ${CMAKE_COMMAND} -E make_directory   "${${TPL}_INSTALL_DIR}"
            COMMAND ${CMAKE_COMMAND} -E remove_directory "${CMAKE_INSTALL_PREFIX}/logs/${TPL}"
            COMMAND ${CMAKE_COMMAND} -E make_directory   "${CMAKE_INSTALL_PREFIX}/logs/${TPL}"
            COMMAND ${CMAKE_COMMAND} -E remove_directory ${TPL}-prefix
            WORKING_DIRECTORY "${CMAKE_CURRENT_BINARY_DIR}/${TPL}-prefix/src/${TPL}-stamp" 
        )
    ELSE()
        ADD_CUSTOM_TARGET( 
            ${TPL}-clean
            ${CMAKE_COMMAND}         -E remove_directory ../${TPL}-build
            COMMAND ${CMAKE_COMMAND} -E make_directory   ../${TPL}-build
            COMMAND ${CMAKE_COMMAND} -E remove ${RM_LIST}
            COMMAND ${CMAKE_COMMAND} -E remove_directory "${CMAKE_INSTALL_PREFIX}/logs/${TPL}"
            COMMAND ${CMAKE_COMMAND} -E make_directory   "${CMAKE_INSTALL_PREFIX}/logs/${TPL}"
            COMMAND ${CMAKE_COMMAND} -E remove_directory ${TPL}-prefix
            WORKING_DIRECTORY "${CMAKE_CURRENT_BINARY_DIR}/${TPL}-prefix/src/${TPL}-stamp" 
        )
    ENDIF()
ENDMACRO()


# Macro to create an empty TPL target
MACRO( ADD_TPL_EMPTY TPL )
    FILE( MAKE_DIRECTORY "${${TPL}_INSTALL_DIR}" )
    FILE( MAKE_DIRECTORY "${CMAKE_INSTALL_PREFIX}/logs/${TPL}" )
    STRING(TOLOWER ${TPL} TPL2)
    EXTERNALPROJECT_ADD(
        ${TPL}
        DOWNLOAD_COMMAND    ""
        SOURCE_DIR          "${${TPL}_INSTALL_DIR}"
        CONFIGURE_COMMAND   ""
        INSTALL_COMMAND     ${CMAKE_COMMAND} -E echo "   Using preinstalled ${TPL2}: ${${TPL}_INSTALL_DIR}"
        BUILD_COMMAND       ""
    )
    ADD_CUSTOM_TARGET(
        ${TPL}-clean
        ${CMAKE_COMMAND}         -E echo "Skipping preinstalled ${TPL}"
    )
ENDMACRO()


# Macro to create a step to save the log files
MACRO( ADD_TPL_SAVE_LOGS TPL )
    FILE( MAKE_DIRECTORY "${${TPL}_INSTALL_DIR}" )
    FILE( MAKE_DIRECTORY "${CMAKE_INSTALL_PREFIX}/logs/${TPL}" )
    SET( tpl_cmds extract-${TPL} ${TPL}-build ${TPL}-pre-configure ${TPL}-configure ${TPL}-done 
        ${TPL}-download ${TPL}-download-impl ${TPL}-mkdir ${TPL}-patch ${TPL}-install 
        ${TPL}-build-test ${TPL}-test ${TPL}-check-test ${TPL}-update ${TPL}-post-install verify-${TPL} )
    FOREACH( tmp ${tpl_cmds} )
        SET( RM_LIST ${RM_LIST} ${tmp} ${tmp}.cmake )
    ENDFOREACH()
    EXTERNALPROJECT_ADD_STEP(
        ${TPL}
        stop-stamp
        COMMAND             ${CMAKE_COMMAND} -Dfilename=time -Dappend=1 -P "${CMAKE_CURRENT_SOURCE_DIR}/cmake/write_stamp.cmake"
        COMMAND             ${CMAKE_COMMAND} -Dfilename=time -P "${CMAKE_CURRENT_SOURCE_DIR}/cmake/print_elapsed.cmake"
        COMMENT             ""
        DEPENDEES           install
        DEPENDERS           
        ALWAYS              0
        WORKING_DIRECTORY   "${CMAKE_CURRENT_BINARY_DIR}/${TPL}-prefix/src/${TPL}-stamp"
        LOG                 0
    )
    EXTERNALPROJECT_ADD_STEP(
        ${TPL}
        start-stamp
        COMMAND             ${CMAKE_COMMAND} -Dfilename=time -P "${CMAKE_CURRENT_SOURCE_DIR}/cmake/write_stamp.cmake"
        COMMENT             ""
        DEPENDEES           
        DEPENDERS           download configure stop-stamp
        ALWAYS              0
        WORKING_DIRECTORY   "${CMAKE_CURRENT_BINARY_DIR}/${TPL}-prefix/src/${TPL}-stamp"
        LOG                 0
    )
    EXTERNALPROJECT_ADD_STEP(
        ${TPL}
        post-install
        COMMAND             make log-${TPL}
        COMMENT             ""
        DEPENDEES           stop-stamp
        ALWAYS              0
        LOG                 0
    )
    ADD_CUSTOM_TARGET( log-${TPL}
        COMMAND             ${CMAKE_COMMAND} -E copy_directory "${CMAKE_CURRENT_BINARY_DIR}/${TPL}-prefix/src/${TPL}-stamp" .
        COMMAND             ${CMAKE_COMMAND} -E remove ${RM_LIST}  ${TPL}-urlinfo.txt
        COMMAND             ${CMAKE_COMMAND} -E remove_directory ${TPL}-prefix
        WORKING_DIRECTORY   "${CMAKE_INSTALL_PREFIX}/logs/${TPL}"
    )
    ADD_DEPENDENCIES( logs log-${TPL} )
ENDMACRO()


# Macro to create a test to print the results of the build
MACRO( ADD_BUILD_TEST TPL )
    ADD_TEST( ${TPL}-build ${CMAKE_COMMAND} -DTPL=${TPL} -P "${CMAKE_CURRENT_SOURCE_DIR}/cmake/check_build.cmake" )
    SET_TESTS_PROPERTIES( ${TPL}-build PROPERTIES WORKING_DIRECTORY "${CMAKE_CURRENT_BINARY_DIR}/${TPL}-prefix/src/${TPL}-stamp"
         PASS_REGULAR_EXPRESSION "completed:" FAIL_REGULAR_EXPRESSION "did not complete" )
ENDMACRO()




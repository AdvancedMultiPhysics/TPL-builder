# This will configure and build lapack
# User can configure the source path by specifying LAPACK_SRC_DIR
#    the download path by specifying LAPACK_URL, or the installed 
#    location by specifying LAPACK_INSTALL_DIR


# Skip if we are installing OpenBLAS
IF ( OPENBLAS_INSTALL_DIR )
    RETURN()
ENDIF()


# Override options if we are using MATLAB's lapack
IF ( USE_MATLAB_LAPACK )
    LIST( FIND TPL_LIST "LAPACK" index1 )
    LIST( FIND TPL_LIST "MATLAB" index2 )
    IF ( ${index2} GREATER ${index1} )
        MESSAGE(FATAL_ERROR "MATLAB should be specified before LAPACK when USE_MATLAB_LAPACK is enabled" )
    ENDIF()
    SET( LAPACK_INSTALL_DIR "${MATLAB_EXTERN}" )
ENDIF()


# Intialize download/src/install vars
SET( LAPACK_BUILD_DIR "${CMAKE_BINARY_DIR}/LAPACK-prefix/src/LAPACK-build" )
IF ( LAPACK_URL ) 
    MESSAGE("   LAPACK_URL = ${LAPACK_URL}")
    SET( LAPACK_CMAKE_URL            "${LAPACK_URL}"       )
    SET( LAPACK_CMAKE_DOWNLOAD_DIR   "${LAPACK_BUILD_DIR}" )
    SET( LAPACK_CMAKE_SOURCE_DIR     "${LAPACK_BUILD_DIR}" )
    SET( LAPACK_CMAKE_INSTALL_DIR "${CMAKE_INSTALL_PREFIX}/lapack" )
    SET( CMAKE_BUILD_LAPACK TRUE )
ELSEIF ( LAPACK_SRC_DIR )
    MESSAGE("   LAPACK_SRC_DIR = ${LAPACK_SRC_DIR}")
    SET( LAPACK_CMAKE_URL                                  )
    SET( LAPACK_CMAKE_DOWNLOAD_DIR                         )
    SET( LAPACK_CMAKE_SOURCE_DIR     "${LAPACK_SRC_DIR}"   )
    SET( LAPACK_CMAKE_INSTALL_DIR "${CMAKE_INSTALL_PREFIX}/lapack" )
    SET( CMAKE_BUILD_LAPACK TRUE )
ELSEIF ( LAPACK_INSTALL_DIR ) 
    SET( LAPACK_CMAKE_INSTALL_DIR "${LAPACK_INSTALL_DIR}" )
    SET( CMAKE_BUILD_LAPACK FALSE )
ELSE()
    MESSAGE(FATAL_ERROR "Please specify LAPACK_SRC_DIR, LAPACK_URL, or LAPACK_INSTALL_DIR")
ENDIF()
NULL_USE(   BLAS_INSTALL_DIR   BLAS_SRC_DIR   BLAS_URL_DIR   BLAS_LIB )
NULL_USE( LAPACK_INSTALL_DIR LAPACK_SRC_DIR LAPACK_URL_DIR LAPACK_LIB )
FILE( MAKE_DIRECTORY "${LAPACK_CMAKE_INSTALL_DIR}" )
SET( LAPACK_INSTALL_DIR "${LAPACK_CMAKE_INSTALL_DIR}" )
MESSAGE( "   LAPACK_INSTALL_DIR = ${LAPACK_INSTALL_DIR}" )
SET( LAPACK_OUT "${CMAKE_CURRENT_BINARY_DIR}/tmp/LAPACK_OUT.cmake" )
FILE( WRITE "${LAPACK_OUT}" "" )
FILE( APPEND "${LAPACK_OUT}" "    SET(LAPACK_INSTALL_DIR \"${LAPACK_INSTALL_DIR}\")\n" )


# Create blas_lapack.h
SET( BLAS_LAPACK_HEADER "${CMAKE_INSTALL_PREFIX}/blas_lapack.h" )
FILE( WRITE "${BLAS_LAPACK_HEADER}" "// Auto-generated file to include BLAS/LAPACK headers\n" )

# Build lapack
IF ( CMAKE_BUILD_LAPACK ) 
    ADD_TPL(
        LAPACK
        URL                 "${LAPACK_CMAKE_URL}"
        DOWNLOAD_COMMAND    URL
        DOWNLOAD_DIR        "${LAPACK_CMAKE_DOWNLOAD_DIR}"
        SOURCE_DIR          "${LAPACK_SRC_DIR}"
        UPDATE_COMMAND      ""
        BUILD_IN_SOURCE     0
        INSTALL_DIR         "${LAPACK_INSTALL_DIR}"
        CMAKE_ARGS          "${CMAKE_ARGS};-DCMAKE_INSTALL_PREFIX=${CMAKE_INSTALL_PREFIX}/lapack"
        BUILD_COMMAND       $(MAKE) install VERBOSE=1
        LOG_DOWNLOAD 1   LOG_UPDATE 1   LOG_CONFIGURE 1   LOG_BUILD 1   LOG_TEST 1   LOG_INSTALL 1
    )
    FIND_LIBRARY( BLAS_LIBRARY    NAMES blas    PATHS "${LAPACK_INSTALL_DIR}/${CMAKE_INSTALL_LIBDIR}"  NO_DEFAULT_PATH )
    FIND_LIBRARY( LAPACK_LIBRARY  NAMES lapack  PATHS "${LAPACK_INSTALL_DIR}/${CMAKE_INSTALL_LIBDIR}"  NO_DEFAULT_PATH )
    SET( BLAS_DIR   "${LAPACK_INSTALL_DIR}/${CMAKE_INSTALL_LIBDIR}" )
    SET( LAPACK_DIR "${LAPACK_INSTALL_DIR}/${CMAKE_INSTALL_LIBDIR}" )
    IF ( ENABLE_SHARED )
        SET( BLAS_LIBS   "${BLAS_DIR}/libblas.so" )
        SET( LAPACK_LIBS "${LAPACK_DIR}/liblapack.so" )
    ELSE()
        SET( BLAS_LIBS   "${BLAS_DIR}/libblas.a" )
        SET( LAPACK_LIBS "${LAPACK_DIR}/liblapack.a" )
    ENDIF()
    SET( BLAS_LAPACK_LINK "${LAPACK_LIBS}" "${BLAS_LIBS}" )
    FILE( READ "${CMAKE_CURRENT_LIST_DIR}/DefaultLapackInterface.h" LAPACK_HEADER )
    FILE( APPEND "${BLAS_LAPACK_HEADER}" "${LAPACK_HEADER}" )
ELSEIF ( USE_MATLAB_LAPACK )
    ADD_TPL_EMPTY( LAPACK )
    SET( BLAS_DIR   "${MATLAB_EXTERN}" )
    SET( LAPACK_DIR "${MATLAB_EXTERN}" )
    SET( BLAS_LIBS   "${MATLAB_BLAS_LIBRARY}" )
    SET( LAPACK_LIBS "${MATLAB_LAPACK_LIBRARY}" )
    SET( BLAS_LAPACK_LINK "${MATLAB_LAPACK_LIBRARY}" "${MATLAB_BLAS_LIBRARY}" )
    FILE( APPEND "${BLAS_LAPACK_HEADER}" "#include \"${MATLAB_INSTALL_DIR}/extern/include/tmwtypes.h\"\n" )
    FILE( APPEND "${BLAS_LAPACK_HEADER}" "#include \"${MATLAB_INSTALL_DIR}/extern/include/blas.h\"\n" )
    FILE( APPEND "${BLAS_LAPACK_HEADER}" "#include \"${MATLAB_INSTALL_DIR}/extern/include/lapack.h\"\n" )
    FILE( APPEND "${BLAS_LAPACK_HEADER}" "#ifndef USE_BLAS\n  #define USE_BLAS\n#endif\n" )
    FILE( APPEND "${BLAS_LAPACK_HEADER}" "#ifndef USE_LAPACK\n  #define USE_LAPACK\n#endif\n" )
    FILE( APPEND "${BLAS_LAPACK_HEADER}" "#ifndef USE_MATLAB_LAPACK\n  #define USE_MATLAB_LAPACK\n#endif\n" )
ELSE()
    ADD_TPL_EMPTY( LAPACK )
    INCLUDE(TPLs/LAPACK_macros.cmake)
    VERIFY_PATH( "${LAPACK_INSTALL_DIR}" )
    SET( BLAS_LAPACK_LINK )
    # Check if we are including acml
    IF ( (NOT BLAS_FOUND) OR (NOT LAPACK_FOUND) )
        CHECK_ACML( "${LAPACK_INSTALL_DIR}" "${LAPACK_OUT}" )
    ENDIF()
    # Check if we are including mkl
    IF ( (NOT BLAS_FOUND) OR (NOT LAPACK_FOUND) )
        CHECK_MKL( "${LAPACK_INSTALL_DIR}" "${LAPACK_OUT}" )
    ENDIF()
    # Check if we are including veclib
    IF ( (NOT BLAS_FOUND) OR (NOT LAPACK_FOUND) )
        CHECK_VECLIB( "${LAPACK_INSTALL_DIR}" "${LAPACK_OUT}" )
    ENDIF()
    # Check if we are including openblas
    IF ( (NOT BLAS_FOUND) OR (NOT LAPACK_FOUND) )
        CHECK_OPENBLAS( "${LAPACK_INSTALL_DIR}" "${LAPACK_OUT}" )
    ENDIF()
    # Check for basic blas/lapack
    IF ( NOT BLAS_DIR )
        SET( BLAS_DIR "${LAPACK_INSTALL_DIR}" )
    ENDIF()
    IF ( (NOT BLAS_FOUND) OR (NOT LAPACK_FOUND) )
        IF ( NOT BLAS_FOUND )
            CHECK_BLAS( "${BLAS_DIR}" "${LAPACK_OUT}" )
        ENDIF()
        IF ( NOT LAPACK_FOUND )
            CHECK_LAPACK( "${LAPACK_INSTALL_DIR}" "${LAPACK_OUT}" )
        ENDIF()
        SET( BLAS_LAPACK_LINK "-Wl,--start-group ${BLAS_LIBRARY} ${LAPACK_LIBRARY} -Wl,--end-group" )
        FILE( APPEND "${BLAS_LAPACK_HEADER}" "${LAPACK_HEADER}" )
    ENDIF()
    # Finished searching
    IF ( (NOT BLAS_FOUND) OR (NOT LAPACK_FOUND) )
        MESSAGE(FATAL_ERROR "No sutable blas or lapack libraries found in ${LAPACK_INSTALL_DIR}")
    ENDIF()
    # Create symbolic links
    SET( BLAS_LIBRARY "" )
    SET( LAPACK_LIBRARY "" )
    IF ( NOT ( CMAKE_SYSTEM_NAME MATCHES "Windows" ) )
        EXECUTE_PROCESS( COMMAND ${CMAKE_COMMAND} -E make_directory "${CMAKE_INSTALL_PREFIX}/lapack/lib" )
        FOREACH ( lib ${BLAS_LIBS} )
            GET_FILENAME_COMPONENT( lib2 ${lib} NAME )
            EXECUTE_PROCESS( COMMAND ${CMAKE_COMMAND} -E create_symlink ${lib} "${CMAKE_INSTALL_PREFIX}/lapack/lib/${lib2}" )
            STRING(REGEX REPLACE "^lib" "" lib3 ${lib2})
            STRING(REGEX REPLACE "(.a|.so)$" "" lib3 ${lib3})
            SET( BLAS_LIBRARY ${BLAS_LIBRARY} ${lib3} )
        ENDFOREACH()
        FOREACH ( lib ${LAPACK_LIBS} )
            GET_FILENAME_COMPONENT( lib2 ${lib} NAME )
            EXECUTE_PROCESS( COMMAND ${CMAKE_COMMAND} -E create_symlink ${lib} "${CMAKE_INSTALL_PREFIX}/lapack/lib/${lib2}" )
            STRING(REGEX REPLACE "^lib" "" lib3 ${lib2})
            STRING(REGEX REPLACE "(.a|.so)$" "" lib3 ${lib3})
            SET( LAPACK_LIBRARY ${LAPACK_LIBRARY} ${lib3} )
        ENDFOREACH()
    ENDIF()
ENDIF()
FILE( APPEND "${LAPACK_OUT}" "    SET( BLAS_DIR    \"${BLAS_DIR}\" )\n" )
FILE( APPEND "${LAPACK_OUT}" "    SET( LAPACK_DIR  \"${LAPACK_DIR}\" )\n" )
FILE( APPEND "${LAPACK_OUT}" "    SET( BLAS_DIRECTORY   \"${BLAS_DIR}\" )\n" )
FILE( APPEND "${LAPACK_OUT}" "    SET( LAPACK_DIRECTORY \"${LAPACK_DIR}\" )\n" )
FILE( APPEND "${LAPACK_OUT}" "    SET( BLAS_LIBS   \"${BLAS_LIBS}\" )\n"   )
FILE( APPEND "${LAPACK_OUT}" "    SET( LAPACK_LIBS \"${LAPACK_LIBS}\" )\n" )
FILE( APPEND "${LAPACK_OUT}" "    SET( BLAS_LAPACK_LINK \"${BLAS_LAPACK_LINK}\" )\n" )


# Add the appropriate fields to TPLs.cmake and FindTPLs.cmake
FILE( READ "${LAPACK_OUT}" LAPACK_OUTPUT_FIELDS )
FILE( APPEND "${FIND_TPLS_CMAKE}" "\n# Find LAPACK\n" )
FILE( APPEND "${FIND_TPLS_CMAKE}" "IF ( TPLs_FIND_LAPACK AND NOT TPL_FOUND_LAPACK )\n" )
FILE( APPEND "${FIND_TPLS_CMAKE}" "${LAPACK_OUTPUT_FIELDS}" )
FILE( APPEND "${FIND_TPLS_CMAKE}" "    ADD_LIBRARY( LAPACK INTERFACE IMPORTED )\n" )
FILE( APPEND "${FIND_TPLS_CMAKE}" "    TARGET_LINK_LIBRARIES( LAPACK INTERFACE $\{BLAS_LAPACK_LINK} )\n" )
FILE( APPEND "${FIND_TPLS_CMAKE}" "    SET( LAPACK_FOUND $\{USE_LAPACK} )\n" )
FILE( APPEND "${FIND_TPLS_CMAKE}" "    SET( TPL_LIBRARIES LAPACK $\{TPL_LIBRARIES} )\n" )
FILE( APPEND "${FIND_TPLS_CMAKE}" "    SET( TPL_FOUND_LAPACK TRUE )\n" )
FILE( APPEND "${FIND_TPLS_CMAKE}" "ENDIF()\n" )
FILE( APPEND "${FIND_TPLS_CMAKE}" "\n" )



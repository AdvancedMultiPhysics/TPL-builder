# This will configure and build lapack
# User can configure the source path by specifying LAPACK_SRC_DIR
#    the download path by specifying LAPACK_URL, or the installed 
#    location by specifying LAPACK_INSTALL_DIR


# Intialize download/src/install vars
SET( LAPACK_BUILD_DIR "${CMAKE_BINARY_DIR}/LAPACK-prefix/src/LAPACK-build" )
IF ( LAPACK_URL ) 
    MESSAGE_TPL("   LAPACK_URL = ${LAPACK_URL}")
    SET( LAPACK_CMAKE_URL            "${LAPACK_URL}"       )
    SET( LAPACK_CMAKE_DOWNLOAD_DIR   "${LAPACK_BUILD_DIR}" )
    SET( LAPACK_CMAKE_SOURCE_DIR     "${LAPACK_BUILD_DIR}" )
    SET( LAPACK_CMAKE_INSTALL_DIR "${CMAKE_INSTALL_PREFIX}/lapack" )
    SET( CMAKE_BUILD_LAPACK TRUE )
ELSEIF ( LAPACK_SRC_DIR )
    MESSAGE_TPL("   LAPACK_SRC_DIR = ${LAPACK_SRC_DIR}")
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
MESSAGE_TPL( "   LAPACK_INSTALL_DIR = ${LAPACK_INSTALL_DIR}" )
FILE( APPEND "${CMAKE_INSTALL_PREFIX}/TPLs.cmake" "SET(LAPACK_INSTALL_DIR \"${LAPACK_INSTALL_DIR}\")\n" )


# Build lapack
IF ( CMAKE_BUILD_LAPACK ) 
    EXTERNALPROJECT_ADD(
        LAPACK
        URL                 "${LAPACK_CMAKE_URL}"
        DOWNLOAD_COMMAND    URL
        DOWNLOAD_DIR        "${LAPACK_CMAKE_DOWNLOAD_DIR}"
        SOURCE_DIR          "${LAPACK_SRC_DIR}"
        UPDATE_COMMAND      ""
        BUILD_IN_SOURCE     0
        INSTALL_DIR         "${LAPACK_INSTALL_DIR}"
        CMAKE_ARGS          "${CMAKE_ARGS};-DCMAKE_INSTALL_PREFIX=${CMAKE_INSTALL_PREFIX}/lapack"
        BUILD_COMMAND       make install -j ${PROCS_INSTALL} VERBOSE=1
        LOG_DOWNLOAD 1   LOG_UPDATE 1   LOG_CONFIGURE 1   LOG_BUILD 1   LOG_TEST 1   LOG_INSTALL 1
    )
    ADD_TPL_SAVE_LOGS( LAPACK )
    ADD_TPL_CLEAN( LAPACK )
    FIND_LIBRARY( BLAS_LIBRARY    NAMES blas    PATHS "${LAPACK_INSTALL_DIR}"  NO_DEFAULT_PATH )
    FIND_LIBRARY( LAPACK_LIBRARY  NAMES lapack  PATHS "${LAPACK_INSTALL_DIR}"  NO_DEFAULT_PATH )
    SET( BLAS_DIR   "${LAPACK_INSTALL_DIR}" )
    SET( LAPACK_DIR "${LAPACK_INSTALL_DIR}" )
    SET( BLAS_LIBS   "${LAPACK_INSTALL_DIR}/lib/libblas.a" )
    SET( LAPACK_LIBS "${LAPACK_INSTALL_DIR}/lib/liblapack.a" )
ELSE()
    ADD_TPL_EMPTY( LAPACK )
    INCLUDE(TPLs/LAPACK_macros.cmake)
    VERIFY_PATH( "${LAPACK_INSTALL_DIR}" )
    SET( BLAS_LAPACK_LINK )
    # Check if we are including acml
    IF ( (NOT BLAS_FOUND) OR (NOT LAPACK_FOUND) )
        CHECK_ACML( "${LAPACK_INSTALL_DIR}" "${CMAKE_INSTALL_PREFIX}/TPLs.cmake" )
    ENDIF()
    # Check if we are including mkl
    IF ( (NOT BLAS_FOUND) OR (NOT LAPACK_FOUND) )
        CHECK_MKL( "${LAPACK_INSTALL_DIR}" "${CMAKE_INSTALL_PREFIX}/TPLs.cmake" )
    ENDIF()
    # Check for basic blas/lapack
    IF ( (NOT BLAS_FOUND) OR (NOT LAPACK_FOUND) )
        IF ( NOT BLAS_FOUND )
            CHECK_BLAS( "${LAPACK_INSTALL_DIR}" "${CMAKE_INSTALL_PREFIX}/TPLs.cmake" )
        ENDIF()
        IF ( NOT LAPACK_FOUND )
            CHECK_LAPACK( "${LAPACK_INSTALL_DIR}" "${CMAKE_INSTALL_PREFIX}/TPLs.cmake" )
        ENDIF()
        SET( BLAS_LAPACK_LINK "-Wl,--start-group ${BLAS_LIBRARY} ${LAPACK_LIBRARY} -Wl,--end-group" )
    ENDIF()
    # Finished searching
    IF ( (NOT BLAS_FOUND) OR (NOT LAPACK_FOUND) )
        MESSAGE(FATAL_ERROR "No sutable blas or lapack libraries found in ${LAPACK_INSTALL_DIR}")
    ENDIF()
    IF ( NOT BLAS_DIR )
        SET( BLAS_DIR   "${LAPACK_INSTALL_DIR}" )
    ENDIF()
    # Create symbolic links
    SET( BLAS_LIBRARY )
    SET( LAPACK_LIBRARY )
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
FILE( APPEND "${CMAKE_INSTALL_PREFIX}/TPLs.cmake" "SET(BLAS_DIR    \"${BLAS_DIR}\")\n"    )
FILE( APPEND "${CMAKE_INSTALL_PREFIX}/TPLs.cmake" "SET(LAPACK_DIR  \"${LAPACK_DIR}\")\n"  )
FILE( APPEND "${CMAKE_INSTALL_PREFIX}/TPLs.cmake" "SET(BLAS_LIBS   \"${BLAS_LIBS}\")\n"   )
FILE( APPEND "${CMAKE_INSTALL_PREFIX}/TPLs.cmake" "SET(LAPACK_LIBS \"${LAPACK_LIBS}\")\n" )
FILE( APPEND "${CMAKE_INSTALL_PREFIX}/TPLs.cmake" "SET(BLAS_LAPACK_LINK \"${BLAS_LAPACK_LINK}\")\n" )



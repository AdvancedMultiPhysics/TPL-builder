# This will configure and build OpenBLAS
# User can configure the source path by speficfying OPENBLAS_SRC_DIR,
#    the download path by specifying OPENBLAS_URL, or the installed 
#    location by specifying OPENBLAS_INSTALL_DIR


# Check for other LAPACK packages
LIST(FIND TPL_LIST "LAPACK" index)
IF (${index} GREATER -1)
    MESSAGE(FATAL_ERROR "OpenBLAS should not be specified with LAPACK" )
ENDIF()


# Intialize download/src/install vars
SET( OPENBLAS_BUILD_DIR "${CMAKE_BINARY_DIR}/OPENBLAS-prefix/src/OPENBLAS-build" )
IF ( OPENBLAS_URL ) 
    MESSAGE_TPL("   OPENBLAS_URL = ${OPENBLAS_URL}")
    SET( OPENBLAS_SRC_DIR "${CMAKE_BINARY_DIR}/OPENBLAS-prefix/src/OPENBLAS-src" )
    SET( OPENBLAS_CMAKE_URL            "${OPENBLAS_URL}"     )
    SET( OPENBLAS_CMAKE_DOWNLOAD_DIR   "${OPENBLAS_SRC_DIR}" )
    SET( OPENBLAS_CMAKE_SOURCE_DIR     "${OPENBLAS_SRC_DIR}" )
    SET( OPENBLAS_CMAKE_INSTALL_DIR "${CMAKE_INSTALL_PREFIX}/openblas" )
    SET( CMAKE_BUILD_OPENBLAS TRUE )
ELSEIF ( OPENBLAS_SRC_DIR )
    VERIFY_PATH("${OPENBLAS_SRC_DIR}")
    MESSAGE_TPL("   OPENBLAS_SRC_DIR = ${OPENBLAS_SRC_DIR}")
    SET( OPENBLAS_CMAKE_URL            ""                  )
    SET( OPENBLAS_CMAKE_DOWNLOAD_DIR   ""                  )
    SET( OPENBLAS_CMAKE_SOURCE_DIR     "${OPENBLAS_SRC_DIR}" )
    SET( OPENBLAS_CMAKE_INSTALL_DIR "${CMAKE_INSTALL_PREFIX}/openblas" )
    SET( CMAKE_BUILD_OPENBLAS TRUE )
ELSEIF ( OPENBLAS_INSTALL_DIR ) 
    SET( OPENBLAS_CMAKE_INSTALL_DIR "${OPENBLAS_INSTALL_DIR}" )
    SET( CMAKE_BUILD_OPENBLAS FALSE )
ELSE()
    MESSAGE(FATAL_ERROR "Please specify OPENBLAS_SRC_DIR, OPENBLAS_URL, or OPENBLAS_INSTALL_DIR")
ENDIF()
SET( OPENBLAS_INSTALL_DIR "${OPENBLAS_CMAKE_INSTALL_DIR}" )
MESSAGE_TPL( "   OPENBLAS_INSTALL_DIR = ${OPENBLAS_INSTALL_DIR}" )
FILE( APPEND "${CMAKE_INSTALL_PREFIX}/TPLs.cmake" "SET(OPENBLAS_INSTALL_DIR \"${OPENBLAS_INSTALL_DIR}\")\n" )


# Configure OpenBLAS
IF ( CMAKE_BUILD_OPENBLAS )
    SET( CONFIGURE_OPTIONS "${CMAKE_ARGS}" )
    IF ( ENABLE_SHARED )
        SET( OPENBLAS_LIBS libopenblas.so )
    ELSEIF ( ENABLE_STATIC )
        SET( OPENBLAS_LIBS libopenblas.a )
    ENDIF()
    SET( BLAS_LIBRARY openblas )
    SET( LAPACK_LIBRARY openblas )
    SET( BLAS_DIR    "${OPENBLAS_CMAKE_INSTALL_DIR}/lib" )
    SET( LAPACK_DIR  "${OPENBLAS_CMAKE_INSTALL_DIR}/lib" )
    SET( BLAS_LIBS   "${BLAS_DIR}/${OPENBLAS_LIBS}"  )
    SET( LAPACK_LIBS "${LAPACK_DIR}/${OPENBLAS_LIBS}" )
    SET( BLAS_LAPACK_LINK "-Wl,${BLAS_LIBRARY}" )
    SET( INSTALL_FILE "${OPENBLAS_CMAKE_SOURCE_DIR}/install.cmake" )
    FILE( WRITE  "${INSTALL_FILE}" "EXECUTE_PROCESS( COMMAND ${CMAKE_COMMAND} -E make_directory \"${BLAS_DIR}/lib\" )\n" )
    FILE( APPEND "${INSTALL_FILE}" "EXECUTE_PROCESS( COMMAND ${CMAKE_COMMAND} -E copy \"${OPENBLAS_CMAKE_SOURCE_DIR}/${OPENBLAS_LIBS}\" \"${BLAS_DIR}/lib/${OPENBLAS_LIBS}\" )\n" )
    FILE( APPEND "${INSTALL_FILE}" "EXECUTE_PROCESS( COMMAND ${CMAKE_COMMAND} -E make_directory \"${CMAKE_INSTALL_PREFIX}/lapack/lib\" )\n" )
    FILE( APPEND "${INSTALL_FILE}" "EXECUTE_PROCESS( COMMAND ${CMAKE_COMMAND} -E create_symlink \"${BLAS_DIR}/lib/${OPENBLAS_LIBS}\" \"${CMAKE_INSTALL_PREFIX}/lapack/lib/${OPENBLAS_LIBS}\" )\n" )
    FILE( APPEND "${CMAKE_INSTALL_PREFIX}/TPLs.cmake" "SET(USE_OPENBLAS true)\n" )
    FILE( APPEND "${CMAKE_INSTALL_PREFIX}/TPLs.cmake" "SET(BLAS_DIR    \"${BLAS_DIR}\")\n"    )
    FILE( APPEND "${CMAKE_INSTALL_PREFIX}/TPLs.cmake" "SET(LAPACK_DIR  \"${LAPACK_DIR}\")\n"  )
    FILE( APPEND "${CMAKE_INSTALL_PREFIX}/TPLs.cmake" "SET(BLAS_LIBS   \"${BLAS_LIBS}\")\n"   )
    FILE( APPEND "${CMAKE_INSTALL_PREFIX}/TPLs.cmake" "SET(LAPACK_LIBS \"${LAPACK_LIBS}\")\n" )
    FILE( APPEND "${CMAKE_INSTALL_PREFIX}/TPLs.cmake" "SET(BLAS_LAPACK_LINK \"${BLAS_LAPACK_LINK}\")\n" )
ENDIF()


# Build OpenBLAS
IF ( CMAKE_BUILD_OPENBLAS )
    EXTERNALPROJECT_ADD(
        OPENBLAS
        URL                 "${OPENBLAS_CMAKE_URL}"
        DOWNLOAD_DIR        "${OPENBLAS_CMAKE_DOWNLOAD_DIR}"
        SOURCE_DIR          "${OPENBLAS_CMAKE_SOURCE_DIR}"
        UPDATE_COMMAND      ${CMAKE_COMMAND} -E echo "" 
        CONFIGURE_COMMAND   ""
        BUILD_COMMAND       make -j ${PROCS_INSTALL} ${ENV_VARS} VERBOSE=1
        BUILD_IN_SOURCE     1
        INSTALL_COMMAND     make PREFIX=${OPENBLAS_CMAKE_INSTALL_DIR} install
#        INSTALL_COMMAND     ${CMAKE_COMMAND} -P "${INSTALL_FILE}"
        LOG_DOWNLOAD 1   LOG_UPDATE 1   LOG_CONFIGURE 1   LOG_BUILD 1   LOG_TEST 1   LOG_INSTALL 1
    )
    ADD_TPL_SAVE_LOGS( OPENBLAS )
    ADD_TPL_CLEAN( OPENBLAS )
    ADD_LIBRARY(LAPACK INTERFACE)
    ADD_DEPENDENCIES(LAPACK OPENBLAS)
    ADD_TPL_CLEAN( LAPACK )
ELSE()
    ADD_TPL_EMPTY( OPENBLAS )
ENDIF()



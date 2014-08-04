# Macro to check for ACML and set the appropriate variables
FUNCTION( CHECK_ACML INSTALL_PATH CMAKE_FILE )
    VERIFY_PATH( "${INSTALL_PATH}" )
    IF ( NOT EXISTS "${INSTALL_PATH}/include" )
        RETURN()
    ENDIF()
    IF ( NOT EXISTS "${INSTALL_PATH}/lib" )
        RETURN()
    ENDIF()
    IF ( ENABLE_STATIC ) 
        FIND_LIBRARY( ACML_LIBRARY    NAMES libacml.a     PATHS "${INSTALL_PATH}/lib"  NO_DEFAULT_PATH )
    ELSEIF( ENABLE_SHARED ) 
        FIND_LIBRARY( ACML_LIBRARY    NAMES libacml.so    PATHS "${INSTALL_PATH}/lib"  NO_DEFAULT_PATH )
    ELSE()
        MESSAGE(FATAL_ERROR "Both static and shared libraries are disabled")
    ENDIF()
    IF ( NOT ACML_LIBRARY )
        RETURN()
    ENDIF()
    MESSAGE_TPL( "   Found ACML" )
    SET( BLAS_FOUND true PARENT_SCOPE )
    SET( LAPACK_FOUND true PARENT_SCOPE )
    SET( BLAS_DIR    "${INSTALL_PATH}/lib" PARENT_SCOPE )
    SET( LAPACK_DIR  "${INSTALL_PATH}/lib" PARENT_SCOPE )
    SET( BLAS_LIBS   "${ACML_LIBRARY}"     PARENT_SCOPE )
    SET( LAPACK_LIBS "${ACML_LIBRARY}"     PARENT_SCOPE )
    FILE( APPEND "${CMAKE_FILE}" "SET(USE_ACML true)\n" )
    FILE( APPEND "${CMAKE_FILE}" "SET(ACML_DIR \"${INSTALL_PATH}\")\n" )
    FILE( APPEND "${CMAKE_FILE}" "SET(ACML_DIRECTORY \"${INSTALL_PATH}\")\n" )
ENDFUNCTION()


# Macro to check for ACML and set the appropriate variables
FUNCTION( CHECK_MKL INSTALL_PATH CMAKE_FILE )

ENDFUNCTION()


# Macro to check for BLAS and set the appropriate variables
FUNCTION( CHECK_BLAS INSTALL_PATH CMAKE_FILE )
    SET( BLAS_LIB_DIR "${INSTALL_PATH}" )
    IF ( BLAS_INSTALL_DIR )
        SET( BLAS_LIB_DIR "${BLAS_INSTALL_DIR}" )
    ENDIF()
    IF ( EXISTS "${BLAS_LIB_DIR}/lib" )
        SET( BLAS_LIB_DIR "${BLAS_LIB_DIR}/lib" )
    ENDIF()
    IF ( BLAS_LIB )
        FIND_LIBRARY( BLAS_LIBRARY  NAMES ${BLAS_LIB} PATHS "${BLAS_LIB_DIR}"  NO_DEFAULT_PATH )
    ELSEIF ( ENABLE_STATIC ) 
        FIND_LIBRARY( BLAS_LIBRARY  NAMES libblas.a   PATHS "${BLAS_LIB_DIR}"  NO_DEFAULT_PATH )
    ELSEIF( ENABLE_SHARED ) 
        FIND_LIBRARY( BLAS_LIBRARY  NAMES libblas.so  PATHS "${BLAS_LIB_DIR}"  NO_DEFAULT_PATH )
    ELSE()
        MESSAGE(FATAL_ERROR "Both static and shared libraries are disabled")
    ENDIF()
    IF ( NOT BLAS_LIBRARY )
        RETURN()
    ENDIF()
    MESSAGE_TPL( "   Found BLAS" )
    SET( BLAS_FOUND true PARENT_SCOPE )
    SET( BLAS_DIR  "${BLAS_INSTALL_DIR}" PARENT_SCOPE )
    SET( BLAS_LIBS "${BLAS_LIBRARY}"     PARENT_SCOPE )
    IF ( BLAS_LIB ) 
        FILE( APPEND "${CMAKE_FILE}" "SET(BLAS_DIRECTORY \"${BLAS_LIB_DIR}\")\n" )
        FILE( APPEND "${CMAKE_FILE}" "SET(BLAS_LIB \"${BLAS_LIB}\")\n" )
    ENDIF()
ENDFUNCTION()


# Macro to check for LAPACK and set the appropriate variables
FUNCTION( CHECK_LAPACK INSTALL_PATH CMAKE_FILE )
    SET( LAPACK_LIB_DIR "${INSTALL_PATH}" )
    IF ( EXISTS "${LAPACK_INSTALL_DIR}/lib" )
        SET( LAPACK_LIB_DIR "${LAPACK_INSTALL_DIR}/lib" )
    ENDIF()
    IF ( LAPACK_LIB )
        FIND_LIBRARY( LAPACK_LIBRARY  NAMES ${LAPACK_LIB} PATHS "${LAPACK_LIB_DIR}"  NO_DEFAULT_PATH )
    ELSEIF ( ENABLE_STATIC ) 
        FIND_LIBRARY( LAPACK_LIBRARY  NAMES liblapack.a   PATHS "${LAPACK_LIB_DIR}"  NO_DEFAULT_PATH )
    ELSEIF( ENABLE_SHARED ) 
        FIND_LIBRARY( LAPACK_LIBRARY  NAMES liblapack.so  PATHS "${LAPACK_LIB_DIR}"  NO_DEFAULT_PATH )
    ELSE()
        MESSAGE(FATAL_ERROR "Both static and shared libraries are disabled")
    ENDIF()
    IF ( NOT LAPACK_LIBRARY )
        RETURN()
    ENDIF()
    MESSAGE_TPL( "   Found LAPACK" )
    SET( LAPACK_FOUND true PARENT_SCOPE )
    SET( LAPACK_DIR  "${LAPACK_INSTALL_DIR}" PARENT_SCOPE )
    SET( LAPACK_LIBS "${LAPACK_LIBRARY}"     PARENT_SCOPE )
    IF ( LAPACK_LIB ) 
        FILE( APPEND "${CMAKE_FILE}" "SET(LAPACK_DIRECTORY \"${LAPACK_LIB_DIR}\")\n" )
        FILE( APPEND "${CMAKE_FILE}" "SET(LAPACK_LIB \"${LAPACK_LIB}\")\n" )
    ENDIF()
ENDFUNCTION()



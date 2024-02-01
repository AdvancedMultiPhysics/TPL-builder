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
        FIND_LIBRARY( ACML_MV_LIBRARY NAMES libacml_mv.a  PATHS "${INSTALL_PATH}/lib"  NO_DEFAULT_PATH )
    ELSEIF( ENABLE_SHARED )
        FIND_LIBRARY( ACML_LIBRARY    NAMES libacml.so    PATHS "${INSTALL_PATH}/lib"  NO_DEFAULT_PATH )
        FIND_LIBRARY( ACML_MV_LIBRARY NAMES libacml_mv.so PATHS "${INSTALL_PATH}/lib"  NO_DEFAULT_PATH )
    ELSE()
        MESSAGE(FATAL_ERROR "Both static and shared libraries are disabled")
    ENDIF()
    IF ( NOT ACML_LIBRARY )
        RETURN()
    ENDIF()
    MESSAGE( "   Found ACML" )
    SET( ACML_LIBS "${ACML_LIBRARY}" )
    SET( ACML_LINK "-Wl,${ACML_LIBRARY}" )
    IF ( ACML_MV_LIBRARY )
        SET( ACML_LIBS ${ACML_LIBS} "${ACML_MV_LIBRARY}" )
        SET( ACML_LINK ${ACML_LINK} "-Wl,${ACML_MV_LIBRARY}" )
    ENDIF()
    SET( BLAS_FOUND true PARENT_SCOPE )
    SET( LAPACK_FOUND true PARENT_SCOPE )
    SET( BLAS_DIR    "${INSTALL_PATH}/lib" PARENT_SCOPE )
    SET( LAPACK_DIR  "${INSTALL_PATH}/lib" PARENT_SCOPE )
    SET( BLAS_LIBS   ${ACML_LIBS} PARENT_SCOPE )
    SET( LAPACK_LIBS ${ACML_LIBS} PARENT_SCOPE )
    SET( BLAS_LAPACK_LINK ${ACML_LINK} PARENT_SCOPE )
    FILE( APPEND "${CMAKE_FILE}" "SET(USE_ACML true)\n" )
    FILE( APPEND "${CMAKE_FILE}" "SET(ACML_DIR \"${INSTALL_PATH}\")\n" )
    FILE( APPEND "${CMAKE_FILE}" "SET(ACML_DIRECTORY \"${INSTALL_PATH}\")\n" )
    FILE( APPEND "${BLAS_LAPACK_HEADER}" "#include \"${INSTALL_PATH}/include/acml.h\"\n" )
    FILE( APPEND "${BLAS_LAPACK_HEADER}" "#ifndef USE_BLAS\n #define USE_BLAS\n #endif\n" )
    FILE( APPEND "${BLAS_LAPACK_HEADER}" "#ifndef USE_LAPACK\n #define USE_LAPACK\n #endif\n" )
    FILE( APPEND "${BLAS_LAPACK_HEADER}" "#ifndef USE_ACML\n #define USE_ACML\n #endif\n" )
ENDFUNCTION()


# Macro to check for ACML and set the appropriate variables
FUNCTION( CHECK_MKL INSTALL_PATH CMAKE_FILE )
    VERIFY_PATH( "${INSTALL_PATH}" )
    IF ( NOT MKL_INCLUDE_DIR )
        IF ( EXISTS "${INSTALL_PATH}/include" )
            SET( MKL_INCLUDE_DIR "${INSTALL_PATH}/include" )
        ELSE()
            SET( MKL_INCLUDE_DIR "${INSTALL_PATH}" )
        ENDIF()
    ENDIF()
    IF ( NOT MKL_LIB_DIR )
        IF ( EXISTS "${INSTALL_PATH}/lib" )
            SET( MKL_LIB_DIR "${INSTALL_PATH}/lib" )
        ELSE()
            SET( MKL_LIB_DIR "${INSTALL_PATH}" )
        ENDIF()
        IF ( EXISTS "${MKL_LIB_DIR}/intel64" )
            SET( MKL_LIB_DIR "${MKL_LIB_DIR}/intel64" )
        ENDIF()
    ENDIF()
    IF ( ENABLE_STATIC )
        FIND_LIBRARY( MKL_SEQ     NAMES libmkl_sequential.a     PATHS "${MKL_LIB_DIR}"  NO_DEFAULT_PATH )
        FIND_LIBRARY( MKL_SEQ     NAMES mkl_sequential.lib      PATHS "${MKL_LIB_DIR}"  NO_DEFAULT_PATH )
        FIND_LIBRARY( MKL_CORE    NAMES libmkl_core.a           PATHS "${MKL_LIB_DIR}"  NO_DEFAULT_PATH )
        FIND_LIBRARY( MKL_CORE    NAMES mkl_core.lib            PATHS "${MKL_LIB_DIR}"  NO_DEFAULT_PATH )
        FIND_LIBRARY( MKL_GF      NAMES libmkl_gf_lp64.a        PATHS "${MKL_LIB_DIR}"  NO_DEFAULT_PATH )
        FIND_LIBRARY( MKL_GF      NAMES mkl_gf_lp64.lib         PATHS "${MKL_LIB_DIR}"  NO_DEFAULT_PATH )
        FIND_LIBRARY( MKL_LP      NAMES libmkl_intel_lp64.a     PATHS "${MKL_LIB_DIR}"  NO_DEFAULT_PATH )
        FIND_LIBRARY( MKL_LP      NAMES mkl_intel_lp64.lib      PATHS "${MKL_LIB_DIR}"  NO_DEFAULT_PATH )
        FIND_LIBRARY( MKL_BLAS    NAMES libmkl_blas95_lp64.a    PATHS "${MKL_LIB_DIR}"  NO_DEFAULT_PATH )
        FIND_LIBRARY( MKL_BLAS    NAMES mkl_blas95_lp64.lib     PATHS "${MKL_LIB_DIR}"  NO_DEFAULT_PATH )
        FIND_LIBRARY( MKL_LAPACK  NAMES libmkl_lapack95_lp64.a  PATHS "${MKL_LIB_DIR}"  NO_DEFAULT_PATH )
        FIND_LIBRARY( MKL_LAPACK  NAMES mkl_lapack95_lp64.lib   PATHS "${MKL_LIB_DIR}"  NO_DEFAULT_PATH )
    ELSEIF( ENABLE_SHARED )
        FIND_LIBRARY( MKL_SEQ     NAMES libmkl_sequential.so    PATHS "${MKL_LIB_DIR}"  NO_DEFAULT_PATH )
        FIND_LIBRARY( MKL_SEQ     NAMES mkl_sequential_dll.lib  PATHS "${MKL_LIB_DIR}"  NO_DEFAULT_PATH )
        FIND_LIBRARY( MKL_CORE    NAMES libmkl_core.so          PATHS "${MKL_LIB_DIR}"  NO_DEFAULT_PATH )
        FIND_LIBRARY( MKL_CORE    NAMES mkl_core_dll.lib        PATHS "${MKL_LIB_DIR}"  NO_DEFAULT_PATH )
        FIND_LIBRARY( MKL_GF      NAMES libmkl_gf_lp64.so       PATHS "${MKL_LIB_DIR}"  NO_DEFAULT_PATH )
        FIND_LIBRARY( MKL_GF      NAMES mkl_gf_lp64.lib         PATHS "${MKL_LIB_DIR}"  NO_DEFAULT_PATH )
        FIND_LIBRARY( MKL_LP      NAMES libmkl_intel_lp64.so    PATHS "${MKL_LIB_DIR}"  NO_DEFAULT_PATH )
        FIND_LIBRARY( MKL_LP      NAMES mkl_intel_lp64.lib      PATHS "${MKL_LIB_DIR}"  NO_DEFAULT_PATH )
        FIND_LIBRARY( MKL_BLAS    NAMES libmkl_blas95_lp64.so   PATHS "${MKL_LIB_DIR}"  NO_DEFAULT_PATH )
        FIND_LIBRARY( MKL_BLAS    NAMES mkl_blas95_lp64_dll.lib PATHS "${MKL_LIB_DIR}"  NO_DEFAULT_PATH )
        FIND_LIBRARY( MKL_LAPACK  NAMES libmkl_lapack95_lp64.so PATHS "${MKL_LIB_DIR}"  NO_DEFAULT_PATH )
        FIND_LIBRARY( MKL_LAPACK  NAMES mkl_lapack95_lp64_dll.lib PATHS "${MKL_LIB_DIR}" NO_DEFAULT_PATH )
    ELSE()
        MESSAGE(FATAL_ERROR "Both static and shared libraries are disabled")
    ENDIF()
    IF ( (NOT MKL_SEQ) OR (NOT MKL_CORE) )
        RETURN()
    ENDIF()
    SET( MKL_LIBS )
    ADD_LIB_LIST( MKL_LIBS MKL_GF )
    ADD_LIB_LIST( MKL_LIBS MKL_LP )
    ADD_LIB_LIST( MKL_LIBS MKL_LAPACK )
    ADD_LIB_LIST( MKL_LIBS MKL_BLAS )
    ADD_LIB_LIST( MKL_LIBS MKL_SEQ )
    ADD_LIB_LIST( MKL_LIBS MKL_CORE )
    MESSAGE( "   Found MKL: ${MKL_LIBS}" )
    STRING( REPLACE ";" " " MKL_GROUP "-Wl,--no-as-needed -Wl,--start-group ${MKL_LIBS} -Wl,--end-group" )
    IF ( ${SYSTEM_NAME} STREQUAL "Windows_32" OR ${SYSTEM_NAME} STREQUAL "Windows_64" )
        SET( MKL_LINK "" )
    ELSE()
        SET( MKL_LINK "${MKL_GROUP} -lpthread -lm" )
    ENDIF()
    SET( BLAS_FOUND true PARENT_SCOPE )
    SET( LAPACK_FOUND true PARENT_SCOPE )
    SET( BLAS_DIR       "${MKL_LIB_DIR}"  PARENT_SCOPE )
    SET( LAPACK_DIR     "${MKL_LIB_DIR}"  PARENT_SCOPE )
    SET( BLAS_LIBS      "${MKL_LIBS}"      PARENT_SCOPE )
    SET( LAPACK_LIBS    "${MKL_LIBS}"      PARENT_SCOPE )
    SET( BLAS_LAPACK_LINK "${MKL_LINK}"    PARENT_SCOPE )
    FILE( APPEND "${CMAKE_FILE}" "SET(USE_MKL true)\n" )
    FILE( APPEND "${CMAKE_FILE}" "SET(MKL_DIR \"${INSTALL_PATH}\")\n" )
    FILE( APPEND "${CMAKE_FILE}" "SET(MKL_DIRECTORY \"${INSTALL_PATH}\")\n" )
    FILE( APPEND "${BLAS_LAPACK_HEADER}" "#include \"${MKL_INCLUDE_DIR}/mkl_blas.h\"\n" )
    FILE( APPEND "${BLAS_LAPACK_HEADER}" "#include \"${MKL_INCLUDE_DIR}/mkl_lapack.h\"\n" )
    FILE( APPEND "${BLAS_LAPACK_HEADER}" "#ifndef USE_BLAS\n #define USE_BLAS\n #endif\n" )
    FILE( APPEND "${BLAS_LAPACK_HEADER}" "#ifndef USE_LAPACK\n #define USE_LAPACK\n #endif\n" )
    FILE( APPEND "${BLAS_LAPACK_HEADER}" "#ifndef USE_MKL\n #define USE_MKL\n #endif\n" )
ENDFUNCTION()


# Macro to check for vecLib and set the appropriate variables
FUNCTION( CHECK_VECLIB INSTALL_PATH CMAKE_FILE )
    IF ( NOT APPLE )
        RETURN()
    ENDIF()
    VERIFY_PATH( "${INSTALL_PATH}" )
    IF ( NOT EXISTS "${INSTALL_PATH}/Headers" )
        RETURN()
    ENDIF()
    FIND_LIBRARY( BLAS_LIBRARY    NAMES BLAS    PATHS "${INSTALL_PATH}"  NO_DEFAULT_PATH )
    FIND_LIBRARY( LAPACK_LIBRARY  NAMES LAPACK  PATHS "${INSTALL_PATH}"  NO_DEFAULT_PATH )
    FIND_LIBRARY( MISC_LIBRARY    NAMES vMisc   PATHS "${INSTALL_PATH}"  NO_DEFAULT_PATH )
    IF ( NOT MISC_LIBRARY )
        RETURN()
    ENDIF()
    MESSAGE( "   Found vecLib" )
    SET( VECLIB_LIBS "${LAPACK_LIBRARY}" "${BLAS_LIBRARY}" )
    SET( BLAS_FOUND true PARENT_SCOPE )
    SET( LAPACK_FOUND true PARENT_SCOPE )
    SET( BLAS_DIR    "${INSTALL_PATH}" PARENT_SCOPE )
    SET( LAPACK_DIR  "${INSTALL_PATH}" PARENT_SCOPE )
    SET( BLAS_LIBS   ${BLAS_LIBRARY} PARENT_SCOPE )
    SET( LAPACK_LIBS ${LAPACK_LIBRARY} PARENT_SCOPE )
    SET( BLAS_LAPACK_LINK ${LAPACK_LINK} ${BLAS_LIBRARY} PARENT_SCOPE )
    FILE( APPEND "${CMAKE_FILE}" "SET(USE_VECLIB true)\n" )
    FILE( APPEND "${CMAKE_FILE}" "SET(VECLIB_DIR \"${INSTALL_PATH}\")\n" )
    FILE( APPEND "${CMAKE_FILE}" "SET(VECLIB_DIRECTORY \"${INSTALL_PATH}\")\n" )
    FILE( APPEND "${BLAS_LAPACK_HEADER}" "#include \"${INSTALL_PATH}/Headers/cblas.h\"\n" )
    FILE( APPEND "${BLAS_LAPACK_HEADER}" "#include \"${INSTALL_PATH}/Headers/clapack.h\"\n" )
    FILE( APPEND "${BLAS_LAPACK_HEADER}" "#ifndef USE_BLAS\n #define USE_BLAS\n #endif\n" )
    FILE( APPEND "${BLAS_LAPACK_HEADER}" "#ifndef USE_LAPACK\n #define USE_LAPACK\n #endif\n" )
    FILE( APPEND "${BLAS_LAPACK_HEADER}" "#ifndef USE_VECLIB\n #define USE_VECLIB\n #endif\n" )
ENDFUNCTION()


# Macro to check for OpenBLAS and set the appropriate variables
FUNCTION( CHECK_OPENBLAS INSTALL_PATH CMAKE_FILE )
    VERIFY_PATH( "${INSTALL_PATH}" )
    IF ( NOT EXISTS "${INSTALL_PATH}/include" )
        RETURN()
    ENDIF()
    IF ( NOT EXISTS "${INSTALL_PATH}/lib" )
        RETURN()
    ENDIF()
    FIND_LIBRARY( OPENBLAS_LIBRARY    NAMES openblas    PATHS "${INSTALL_PATH}/lib"  NO_DEFAULT_PATH )
    IF ( NOT OPENBLAS_LIBRARY )
        RETURN()
    ENDIF()
    MESSAGE( "   Found OpenBLAS" )
    SET( OPENBLAS_LIBS "${LAPACK_LIBRARY}" "${BLAS_LIBRARY}" )
    SET( BLAS_FOUND true PARENT_SCOPE )
    SET( LAPACK_FOUND true PARENT_SCOPE )
    SET( BLAS_DIR    "${INSTALL_PATH}" PARENT_SCOPE )
    SET( LAPACK_DIR  "${INSTALL_PATH}" PARENT_SCOPE )
    SET( BLAS_LIBS   ${OPENBLAS_LIBRARY} PARENT_SCOPE )
    SET( LAPACK_LIBS ${OPENBLAS_LIBRARY} PARENT_SCOPE )
    SET( BLAS_LAPACK_LINK ${OPENBLAS_LINK} PARENT_SCOPE )
    FILE( APPEND "${CMAKE_FILE}" "SET(USE_OPENBLAS true)\n" )
    FILE( APPEND "${CMAKE_FILE}" "SET(OPENBLAS_DIR \"${INSTALL_PATH}\")\n" )
    FILE( APPEND "${CMAKE_FILE}" "SET(OPENBLAS_DIRECTORY \"${INSTALL_PATH}\")\n" )
    FILE( APPEND "${BLAS_LAPACK_HEADER}" "#include \"${INSTALL_PATH}/include/openblas/cblas.h\"\n" )
    FILE( APPEND "${BLAS_LAPACK_HEADER}" "#include \"${INSTALL_PATH}/include/openblas/lapacke.h\"\n" )
    FILE( APPEND "${BLAS_LAPACK_HEADER}" "#ifndef USE_BLAS\n #define USE_BLAS\n #endif\n" )
    FILE( APPEND "${BLAS_LAPACK_HEADER}" "#ifndef USE_LAPACK\n #define USE_LAPACK\n #endif\n" )
    FILE( APPEND "${BLAS_LAPACK_HEADER}" "#ifndef USE_OPENBLAS\n #define USE_OPENBLAS\n #endif\n" )
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
    MESSAGE( "   Found BLAS" )
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
    MESSAGE( "   Found LAPACK" )
    SET( LAPACK_FOUND true PARENT_SCOPE )
    SET( LAPACK_DIR  "${LAPACK_INSTALL_DIR}" PARENT_SCOPE )
    SET( LAPACK_LIBS "${LAPACK_LIBRARY}"     PARENT_SCOPE )
    IF ( LAPACK_LIB )
        FILE( APPEND "${CMAKE_FILE}" "SET(LAPACK_DIRECTORY \"${LAPACK_LIB_DIR}\")\n" )
        FILE( APPEND "${CMAKE_FILE}" "SET(LAPACK_LIB \"${LAPACK_LIB}\")\n" )
    ENDIF()
ENDFUNCTION()


MACRO( ADD_LIB_LIST LISTNAME LIBNAME )
    IF ( ${LIBNAME} )
        SET( ${LISTNAME} ${${LISTNAME}} ${${LIBNAME}} )
    ENDIF()
ENDMACRO()



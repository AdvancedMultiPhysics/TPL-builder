# This will configure and build hypre
# User can configure the source path by specifying HYPRE_SRC_DIR
#    the download path by specifying HYPRE_URL, or the installed 
#    location by specifying HYPRE_INSTALL_DIR


# Initialize download/src/install vars
SET( HYPRE_BUILD_DIR "${CMAKE_BINARY_DIR}/HYPRE-prefix/src/HYPRE-build" )
IF ( HYPRE_URL ) 
    MESSAGE("   HYPRE_URL = ${HYPRE_URL}")
    SET( HYPRE_CMAKE_URL            "${HYPRE_URL}"       )
    SET( HYPRE_CMAKE_DOWNLOAD_DIR   "${HYPRE_BUILD_DIR}" )
    SET( HYPRE_CMAKE_SOURCE_DIR     "${HYPRE_BUILD_DIR}" )
    SET( HYPRE_CMAKE_INSTALL_DIR "${CMAKE_INSTALL_PREFIX}/hypre" )
    SET( CMAKE_BUILD_HYPRE TRUE )
ELSEIF ( HYPRE_SRC_DIR )
    MESSAGE("   HYPRE_SRC_DIR = ${HYPRE_SRC_DIR}")
    SET( HYPRE_CMAKE_URL            "${HYPRE_SRC_DIR}" )
    SET( HYPRE_CMAKE_DOWNLOAD_DIR   "${HYPRE_BUILD_DIR}" )
    SET( HYPRE_CMAKE_SOURCE_DIR     "${HYPRE_BUILD_DIR}" )
    SET( HYPRE_CMAKE_INSTALL_DIR "${CMAKE_INSTALL_PREFIX}/hypre" )
    SET( CMAKE_BUILD_HYPRE TRUE )
ELSEIF ( HYPRE_INSTALL_DIR ) 
    SET( HYPRE_CMAKE_INSTALL_DIR "${HYPRE_INSTALL_DIR}" )
    SET( CMAKE_BUILD_HYPRE FALSE )
ELSE()
    MESSAGE(FATAL_ERROR "Please specify HYPRE_SRC_DIR, HYPRE_URL, or HYPRE_INSTALL_DIR")
ENDIF()
FILE( MAKE_DIRECTORY "${HYPRE_CMAKE_INSTALL_DIR}" )
SET( HYPRE_INSTALL_DIR "${HYPRE_CMAKE_INSTALL_DIR}" )
MESSAGE( "   HYPRE_INSTALL_DIR = ${HYPRE_INSTALL_DIR}" )


# Configure optional/required TPLs
CONFIGURE_DEPENDENCIES( HYPRE OPTIONAL LAPACK UMPIRE )


# Configure HYPRE
IF ( NOT DEFINED HYPRE_USE_CUDA )
    SET( HYPRE_USE_CUDA ${USE_CUDA} )
ENDIF()
IF ( NOT DEFINED HYPRE_USE_HIP )
    SET( HYPRE_USE_HIP ${USE_HIP} )
ENDIF()
IF ( NOT DEFINED HYPRE_USE_OPENMP )
    SET( HYPRE_USE_OPENMP ${USE_OPENMP} )
ENDIF()


# Configure hypre
SET( HYPRE_CONFIG "${CMAKE_BINARY_DIR}/HYPRE-prefix/src/HYPRE_config.cmake" )
IF ( CMAKE_BUILD_HYPRE )
    # Macro to add configure option for HYPRE
    FILE( WRITE "${HYPRE_CONFIG}" "# Configure HYPRE\n" )
    FILE( APPEND "${HYPRE_CONFIG}" "CMAKE_POLICY( SET CMP0007 NEW )\n" )
    FILE( APPEND "${HYPRE_CONFIG}" "SET( OPTIONS )\n" )
    MACRO( ADD_HYPRE_OPTION VAL )
        FILE( APPEND "${HYPRE_CONFIG}" "SET( OPTIONS $\{OPTIONS} ${VAL} ${ARGN} )\n" )
    ENDMACRO()
    ADD_HYPRE_OPTION( --enable-mixedint )
    IF( HYPRE_USE_CUDA )
        MESSAGE( "Enabling CUDA support for HYPRE" )
        IF ( HYPRE_CUDA_HOME )
            ADD_HYPRE_OPTION( --with-cuda --with-cuda-home=${HYPRE_CUDA_HOME} )
        ELSE()
            ADD_HYPRE_OPTION( --with-cuda --with-cuda-home=${CUDA_HOME} )
        ENDIF()
        IF ( HYPRE_CUDA_ARCH )
            ADD_HYPRE_OPTION( --with-gpu-arch=${HYPRE_CUDA_ARCH} )
        ELSE()
          MESSAGE( FATAL_ERROR "The HYPRE_CUDA_ARCH must be set" )
        ENDIF()
        ADD_HYPRE_OPTION( --enable-unified-memory )
    ENDIF()
    IF( HYPRE_USE_HIP )
        MESSAGE( "Enabling HIP support for HYPRE" )
        ADD_HYPRE_OPTION( --with-hip )
        ADD_HYPRE_OPTION( --enable-unified-memory )
        IF ( HYPRE_HIP_ARCH )
            ADD_HYPRE_OPTION( --with-gpu-arch=${HYPRE_HIP_ARCH} )
        ELSE()
            MESSAGE( FATAL_ERROR "The HYPRE_HIP_ARCH must be set" )
        ENDIF()
	    SET(CMAKE_HIP_FLAGS "${CMAKE_HIP_FLAGS} -std=c++${CMAKE_HIP_STANDARD}")
        ADD_HYPRE_OPTION( "\"--with-extra-CUFLAGS=${CMAKE_HIP_FLAGS}\"" )
    ENDIF()
      
    # Appears hypre only uses Umpire with CUDA/HIP
    IF ( ( HYPRE_USE_CUDA OR HYPRE_USE_HIP ) AND HYPRE_USE_UMPIRE )
        ADD_HYPRE_OPTION( --with-umpire )
        ADD_HYPRE_OPTION( --with-umpire-include=${UMPIRE_INSTALL_DIR}/include )
        ADD_HYPRE_OPTION( --with-umpire-libs=umpire )
        ADD_HYPRE_OPTION( --with-umpire-um )
        FILE( APPEND "${HYPRE_CONFIG}" "IF ( IS_DIRECTORY ${UMPIRE_INSTALL_DIR}/lib )\n" )
        FILE( APPEND "${HYPRE_CONFIG}" "   SET( OPTIONS $\{OPTIONS} --with-umpire-lib-dirs=${UMPIRE_INSTALL_DIR}/lib )\n" )
        FILE( APPEND "${HYPRE_CONFIG}" "ELSEIF ( IS_DIRECTORY ${UMPIRE_INSTALL_DIR}/lib64 )\n" )
        FILE( APPEND "${HYPRE_CONFIG}" "   SET( OPTIONS $\{OPTIONS} --with-umpire-lib-dirs=${UMPIRE_INSTALL_DIR}/lib64 )\n" )
        FILE( APPEND "${HYPRE_CONFIG}" "ENDIF()\n" )
    ENDIF()
    IF( HYPRE_USE_OPENMP )
        MESSAGE( "Enabling OpenMP support for HYPRE" )
        ADD_HYPRE_OPTION(  --with-openmp )        
    ENDIF()
    IF ( "${BLAS_LIBS}" MATCHES ";" )
        STRING( REPLACE ";" " " HYPRE_BLAS_LIBS "${BLAS_LIBS}")
        SET( HYPRE_BLAS_LIBS "'${HYPRE_BLAS_LIBS}'" )
    ELSE()
        SET( HYPRE_BLAS_LIBS "${BLAS_LIBS}" )
    ENDIF()
    EXECUTE_PROCESS( COMMAND ${CMAKE_COMMAND} -E make_directory "${HYPRE_INSTALL_DIR}/include" )
    EXECUTE_PROCESS( COMMAND ${CMAKE_COMMAND} -E make_directory "${HYPRE_INSTALL_DIR}/lib" )
    #ADD_HYPRE_OPTION( --with-blas-lib=${HYPRE_BLAS_LIBS} )
    #ADD_HYPRE_OPTION( --with-lapack-lib=${HYPRE_LAPACK_LIBS} )
    ADD_HYPRE_OPTION( --includedir=${HYPRE_INSTALL_DIR}/include )
    ADD_HYPRE_OPTION( --libdir=${HYPRE_INSTALL_DIR}/lib )
    IF ( ${CMAKE_BUILD_TYPE} STREQUAL "Debug" )
        ADD_HYPRE_OPTION(  --enable-debug )
    ELSEIF ( (${CMAKE_BUILD_TYPE} STREQUAL "Release") OR (${CMAKE_BUILD_TYPE} STREQUAL "RelWithDebInfo") )
        ADD_HYPRE_OPTION( --disable-debug )
    ELSE()
        MESSAGE ( FATAL_ERROR "Unknown CMAKE_BUILD_TYPE=${CMAKE_BUILD_TYPE}" )
    ENDIF()
    IF ( ENABLE_SHARED )
        ADD_HYPRE_OPTION( --enable-shared )
    ELSE()
        ADD_HYPRE_OPTION( --disable-shared )
    ENDIF()
    IF ( ENABLE_STATIC )
        ADD_HYPRE_OPTION( --disable-shared )
    ELSE()
        ADD_HYPRE_OPTION( --enable-shared )
    ENDIF()
    IF ( NOT USE_MPI )
        ADD_HYPRE_OPTION( --without-MPI )
    ENDIF()
    FILE( APPEND "${HYPRE_CONFIG}" "SET( ENV_VARS \"${ENV_VARS}\" )\n" )
    FILE( APPEND "${HYPRE_CONFIG}" "FOREACH ( tmp $\{ENV_VARS} )\n" )
    FILE( APPEND "${HYPRE_CONFIG}" "    STRING( REPLACE \"=\" \";\" tmp2 \"$\{tmp}\" )\n" )
    FILE( APPEND "${HYPRE_CONFIG}" "    LIST( GET tmp2 0 var )\n" )
    FILE( APPEND "${HYPRE_CONFIG}" "    LIST( POP_FRONT tmp2 )\n" )
    FILE( APPEND "${HYPRE_CONFIG}" "    STRING( REPLACE \";\" \"=\" val \"$\{tmp2}\" )\n" )
    FILE( APPEND "${HYPRE_CONFIG}" "    SET( ENV{$\{var}} \"$\{val}\" )\n" )
    FILE( APPEND "${HYPRE_CONFIG}" "    SET( OPTIONS $\{OPTIONS} $\{var}=$\{val} )\n" )
    FILE( APPEND "${HYPRE_CONFIG}" "ENDFOREACH()\n" )
    FILE( APPEND "${HYPRE_CONFIG}" "EXECUTE_PROCESS( COMMAND ./configure --prefix=${HYPRE_INSTALL_DIR} $\{OPTIONS} WORKING_DIRECTORY ${HYPRE_BUILD_DIR} ECHO_OUTPUT_VARIABLE ECHO_ERROR_VARIABLE RESULTS_VARIABLE err )\n" )
    FILE( APPEND "${HYPRE_CONFIG}" "IF ( NOT $\{err} EQUAL \"0\" )\n" )
    FILE( APPEND "${HYPRE_CONFIG}" "    MESSAGE( FATAL_ERROR \"Failed to configure: $\{err}\" )\n" )
    FILE( APPEND "${HYPRE_CONFIG}" "ENDIF()\n" )
    MESSAGE("   HYPRE configure options: ${HYPRE_CONFIGURE_OPTIONS}")
    IF ( NOT HYPRE_VERSION )
        SET( HYPRE_VERSION "0.0.0" )
    ENDIF()
    IF ( "${HYPRE_VERSION}" VERSION_EQUAL "2.31.0" )
        SET( HYPRE_PATCH_COMMAND patch -p1 -i "${CMAKE_CURRENT_SOURCE_DIR}/patches/hypre.patch" )
    ENDIF()
ENDIF()


# Build hypre
IF ( CMAKE_BUILD_HYPRE )
    ADD_TPL(
        HYPRE
        URL                 "${HYPRE_CMAKE_URL}"
        DOWNLOAD_DIR        "${HYPRE_CMAKE_DOWNLOAD_DIR}"
        SOURCE_DIR          "${HYPRE_CMAKE_SOURCE_DIR}"
	    ${HYPRE_PATCH_COMMAND}
        CONFIGURE_COMMAND   ${CMAKE_COMMAND} -P ${HYPRE_CONFIG}
        BUILD_COMMAND       $(MAKE) VERBOSE=1
        BUILD_IN_SOURCE     1
        INSTALL_COMMAND     $(MAKE) install
        LOG_DOWNLOAD 1   LOG_UPDATE 1   LOG_CONFIGURE 1   LOG_BUILD 1   LOG_TEST 1   LOG_INSTALL 1
    )
    EXTERNALPROJECT_ADD_STEP(
        HYPRE
        pre-configure
        COMMAND             ${CMAKE_COMMAND} -E copy_directory "${HYPRE_CMAKE_SOURCE_DIR}/src" "HYPRE-tmp" 
        COMMAND             ${CMAKE_COMMAND} -E remove_directory "${HYPRE_CMAKE_SOURCE_DIR}"
        COMMAND             ${CMAKE_COMMAND} -E rename "HYPRE-tmp" "${HYPRE_CMAKE_SOURCE_DIR}"
        COMMENT             ""
        DEPENDEES           download
        DEPENDERS           configure
        WORKING_DIRECTORY   "${HYPRE_CMAKE_SOURCE_DIR}/.."
        LOG                 0
    )
ELSE()
    ADD_TPL_EMPTY( HYPRE )
ENDIF()


# Add the appropriate fields to FindTPLs.cmake
CONFIGURE_FILE( ${CMAKE_CURRENT_SOURCE_DIR}/cmake/FindHypre.cmake "${CMAKE_INSTALL_PREFIX}/cmake/FindHypre.cmake" COPYONLY )
FILE( APPEND "${FIND_TPLS_CMAKE}" "\n# Find HYPRE\n" )
FILE( APPEND "${FIND_TPLS_CMAKE}" "IF ( TPLs_FIND_HYPRE AND NOT TPLs_HYPRE_FOUND )\n" )
FILE( APPEND "${FIND_TPLS_CMAKE}" "    SET( HYPRE_INSTALL_DIR \"${HYPRE_INSTALL_DIR}\" )\n" )
FILE( APPEND "${FIND_TPLS_CMAKE}" "    INCLUDE( \"${CMAKE_INSTALL_PREFIX}/cmake/FindHypre.cmake\" )\n" )
FILE( APPEND "${FIND_TPLS_CMAKE}" "    HYPRE_SET_INCLUDES( ${HYPRE_INSTALL_DIR} )\n" )
FILE( APPEND "${FIND_TPLS_CMAKE}" "    HYPRE_SET_LIBRARIES( ${HYPRE_INSTALL_DIR} )\n" )
FILE( APPEND "${FIND_TPLS_CMAKE}" "    ADD_TPL_LIBRARY( HYPRE $\{HYPRE_LIBS} )\n" )
FILE( APPEND "${FIND_TPLS_CMAKE}" "ENDIF()\n" )
FILE( APPEND "${FIND_TPLS_CMAKE}" "\n" )



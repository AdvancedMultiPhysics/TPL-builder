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
CONFIGURE_DEPENDENCIES( HYPRE REQUIRED LAPACK OPTIONAL UMPIRE )


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
IF ( CMAKE_BUILD_HYPRE )
    IF( HYPRE_USE_CUDA )
        MESSAGE( "Enabling CUDA support for HYPRE" )
        IF ( HYPRE_CUDA_HOME )
          SET( HYPRE_CONFIGURE_OPTIONS --with-cuda --with-cuda-home=${HYPRE_CUDA_HOME} )
        ELSE()
          SET( HYPRE_CONFIGURE_OPTIONS --with-cuda --with-cuda-home=${CUDA_HOME} )
        ENDIF()
        IF ( HYPRE_CUDA_ARCH )
          SET( HYPRE_CONFIGURE_OPTIONS ${HYPRE_CONFIGURE_OPTIONS} --with-gpu-arch=${HYPRE_CUDA_ARCH} )
        ELSE()
          MESSAGE( FATAL_ERROR "The HYPRE_CUDA_ARCH must be set" )
        ENDIF()
        SET( HYPRE_CONFIGURE_OPTIONS ${HYPRE_CONFIGURE_OPTIONS} --enable-unified-memory )        
        # Appears hypre only uses Umpire with CUDA so keep this if condition here
        IF ( HYPRE_USE_UMPIRE )
            MESSAGE( "Building HYPRE with Umpire support" )
            SET( HYPRE_CONFIGURE_OPTIONS ${HYPRE_CONFIGURE_OPTIONS} --with-umpire --with-umpire-include=${UMPIRE_INSTALL_DIR}/include --with-umpire-lib-dirs=${UMPIRE_INSTALL_DIR}/lib --with-umpire-libs=umpire )
        SET( HYPRE_CONFIGURE_OPTIONS ${HYPRE_CONFIGURE_OPTIONS} --with-umpire-um )
        ENDIF()
    ENDIF()
    IF( HYPRE_USE_HIP )
        MESSAGE( "Enabling HIP support for HYPRE" )
        IF ( HYPRE_HIP_HOME )
          SET( HYPRE_CONFIGURE_OPTIONS --with-hip --with-hip-home=${HYPRE_HIP_HOME} )
        ELSE()
          SET( HYPRE_CONFIGURE_OPTIONS --with-hip --with-hip-home=${HIP_HOME} )
        ENDIF()
        IF ( HYPRE_HIP_ARCH )
          SET( HYPRE_CONFIGURE_OPTIONS ${HYPRE_CONFIGURE_OPTIONS} --with-gpu-arch=${HYPRE_HIP_ARCH} )
        ELSE()
          MESSAGE( FATAL_ERROR "The HYPRE_HIP_ARCH must be set" )
        ENDIF()
	SET( HYPRE_CONFIGURE_OPTIONS ${HYPRE_CONFIGURE_OPTIONS} --enable-unified-memory --with-extra-CUFLAGS=${CMAKE_HIP_FLAGS} )        
        # Appears hypre only uses Umpire with HIP so keep this if condition here
        IF ( HYPRE_USE_UMPIRE )
            MESSAGE( "Building HYPRE with Umpire support" )
            SET( HYPRE_CONFIGURE_OPTIONS ${HYPRE_CONFIGURE_OPTIONS} --with-umpire --with-umpire-include=${UMPIRE_INSTALL_DIR}/include --with-umpire-lib-dirs=${UMPIRE_INSTALL_DIR}/lib --with-umpire-libs=umpire )
        SET( HYPRE_CONFIGURE_OPTIONS ${HYPRE_CONFIGURE_OPTIONS} --with-umpire-um )
        ENDIF()
    ENDIF()
    IF( HYPRE_USE_OPENMP )
        MESSAGE( "Enabling OpenMP support for HYPRE" )
        SET( HYPRE_CONFIGURE_OPTIONS ${HYPRE_CONFIGURE_OPTIONS} --with-openmp )        
    ENDIF()
    IF ( "${BLAS_LIBS}" MATCHES ";" )
        STRING( REPLACE ";" " " HYPRE_BLAS_LIBS "${BLAS_LIBS}")
        SET( HYPRE_BLAS_LIBS "'${HYPRE_BLAS_LIBS}'" )
    ELSE()
        SET( HYPRE_BLAS_LIBS "${BLAS_LIBS}" )
    ENDIF()
    EXECUTE_PROCESS( COMMAND ${CMAKE_COMMAND} -E make_directory "${HYPRE_INSTALL_DIR}/include" )
    EXECUTE_PROCESS( COMMAND ${CMAKE_COMMAND} -E make_directory "${HYPRE_INSTALL_DIR}/lib" )
    SET( PETSC_CONFIGURE_OPTIONS ${PETSC_CONFIGURE_OPTIONS} --with-blas-lib=${HYPRE_BLAS_LIBS} )
    SET( PETSC_CONFIGURE_OPTIONS ${PETSC_CONFIGURE_OPTIONS} --with-lapack-lib=${HYPRE_LAPACK_LIBS} )
    SET( HYPRE_CONFIGURE_OPTIONS ${HYPRE_CONFIGURE_OPTIONS} --includedir=${HYPRE_INSTALL_DIR}/include )
    SET( HYPRE_CONFIGURE_OPTIONS ${HYPRE_CONFIGURE_OPTIONS} --libdir=${HYPRE_INSTALL_DIR}/lib )
    IF ( ${CMAKE_BUILD_TYPE} STREQUAL "Debug" )
        SET( HYPRE_CONFIGURE_OPTIONS ${HYPRE_CONFIGURE_OPTIONS} --enable-debug )
    ELSEIF ( (${CMAKE_BUILD_TYPE} STREQUAL "Release") OR (${CMAKE_BUILD_TYPE} STREQUAL "RelWithDebInfo") )
        SET( HYPRE_CONFIGURE_OPTIONS ${HYPRE_CONFIGURE_OPTIONS} --disable-debug )
    ELSE()
        MESSAGE ( FATAL_ERROR "Unknown CMAKE_BUILD_TYPE=${CMAKE_BUILD_TYPE}" )
    ENDIF()
    IF ( ENABLE_SHARED )
        SET( HYPRE_CONFIGURE_OPTIONS ${HYPRE_CONFIGURE_OPTIONS} --enable-shared )
    ELSE()
        SET( HYPRE_CONFIGURE_OPTIONS ${HYPRE_CONFIGURE_OPTIONS} --disable-shared )
    ENDIF()
    IF ( ENABLE_STATIC )
        SET( HYPRE_CONFIGURE_OPTIONS ${HYPRE_CONFIGURE_OPTIONS} --disable-shared )
    ELSE()
        SET( HYPRE_CONFIGURE_OPTIONS ${HYPRE_CONFIGURE_OPTIONS} --enable-shared )
    ENDIF()
    IF ( NOT USE_MPI )
        SET( HYPRE_CONFIGURE_OPTIONS ${HYPRE_CONFIGURE_OPTIONS} --without-MPI )
    ENDIF()
    MESSAGE("   HYPRE configure options: ${HYPRE_CONFIGURE_OPTIONS}")
ENDIF()


# Build hypre
IF ( CMAKE_BUILD_HYPRE )
    ADD_TPL(
        HYPRE
        URL                 "${HYPRE_CMAKE_URL}"
        DOWNLOAD_DIR        "${HYPRE_CMAKE_DOWNLOAD_DIR}"
        SOURCE_DIR          "${HYPRE_CMAKE_SOURCE_DIR}"
        CONFIGURE_COMMAND   "./configure" --prefix=${HYPRE_INSTALL_DIR} ${HYPRE_CONFIGURE_OPTIONS} ${ENV_VARS}
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
FILE( APPEND "${FIND_TPLS_CMAKE}" "    INCLUDE( \"${CMAKE_INSTALL_PREFIX}/cmake/FindHypre.cmake\" )\n" )
FILE( APPEND "${FIND_TPLS_CMAKE}" "    SET( HYPRE_DIR \"${HYPRE_INSTALL_DIR}\" )\n" )
FILE( APPEND "${FIND_TPLS_CMAKE}" "    SET( HYPRE_DIRECTORY \"${HYPRE_INSTALL_DIR}\" )\n" )
FILE( APPEND "${FIND_TPLS_CMAKE}" "    HYPRE_SET_INCLUDES( ${HYPRE_INSTALL_DIR} )\n" )
FILE( APPEND "${FIND_TPLS_CMAKE}" "    HYPRE_SET_LIBRARIES( ${HYPRE_INSTALL_DIR} )\n" )
FILE( APPEND "${FIND_TPLS_CMAKE}" "    SET( CMAKE_INSTALL_RPATH $\{CMAKE_INSTALL_RPATH} \"${HYPRE_INSTALL_DIR}/lib\" )\n" )
FILE( APPEND "${FIND_TPLS_CMAKE}" "    SET( TPL_INCLUDE_DIRS $\{TPL_INCLUDE_DIRS} $\{HYPRE_INCLUDE} )\n" )
FILE( APPEND "${FIND_TPLS_CMAKE}" "    SET( TPL_LIBRARIES $\{HYPRE_LIBS} $\{TPL_LIBRARIES} )\n" )
FILE( APPEND "${FIND_TPLS_CMAKE}" "    SET( TPLs_HYPRE_FOUND TRUE )\n" )
FILE( APPEND "${FIND_TPLS_CMAKE}" "ENDIF()\n" )
FILE( APPEND "${FIND_TPLS_CMAKE}" "\n" )



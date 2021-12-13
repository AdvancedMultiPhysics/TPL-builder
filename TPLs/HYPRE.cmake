# This will configure and build hypre
# User can configure the source path by specifying HYPRE_SRC_DIR
#    the download path by specifying HYPRE_URL, or the installed 
#    location by specifying HYPRE_INSTALL_DIR


# Intialize download/src/install vars
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


# Configure hypre
IF ( CMAKE_BUILD_HYPRE )
    IF( HYPRE_USE_CUDA )
        SET( CONFIGURE_OPTIONS --with-cuda --enable-unified-memory )        
        # Appears hypre only uses Umpire with CUDA so keep this if condition here
        IF ( HYPRE_USE_UMPIRE )
            SET( HYPRE_DEPENDS UMPIRE LAPACK )
            MESSAGE( "Building HYPRE with Umpire support" )
            SET( CONFIGURE_OPTIONS ${CONFIGURE_OPTIONS} --with-umpire --with-umpire-include=${UMPIRE_INSTALL_DIR}/include --with-umpire-lib-dirs=${UMPIRE_INSTALL_DIR}/lib --with-umpire-libs=umpire )
	    SET( CONFIGURE_OPTIONS ${CONFIGURE_OPTIONS} --with-umpire-um )
	ENDIF()
    ELSE()
         SET( HYPRE_DEPENDS LAPACK )
    ENDIF()      
    EXECUTE_PROCESS( COMMAND ${CMAKE_COMMAND} -E make_directory "${HYPRE_INSTALL_DIR}/include" )
    EXECUTE_PROCESS( COMMAND ${CMAKE_COMMAND} -E make_directory "${HYPRE_INSTALL_DIR}/lib" )
    SET( CONFIGURE_OPTIONS ${CONFIGURE_OPTIONS} --with-blas-libs=${BLAS_LIBRARY} )
    SET( CONFIGURE_OPTIONS ${CONFIGURE_OPTIONS} --with-blas-lib-dirs=${BLAS_DIR} )
    SET( CONFIGURE_OPTIONS ${CONFIGURE_OPTIONS} --with-lapack-libs=${LAPACK_LIBRARY} )
    SET( CONFIGURE_OPTIONS ${CONFIGURE_OPTIONS} --with-lapack-lib-dirs=${LAPACK_DIR} )
    SET( CONFIGURE_OPTIONS ${CONFIGURE_OPTIONS} --includedir=${HYPRE_INSTALL_DIR}/include )
    SET( CONFIGURE_OPTIONS ${CONFIGURE_OPTIONS} --libdir=${HYPRE_INSTALL_DIR}/lib )
    IF ( ${CMAKE_BUILD_TYPE} STREQUAL "Debug" )
        SET( CONFIGURE_OPTIONS ${CONFIGURE_OPTIONS} --enable-debug )
    ELSEIF ( ${CMAKE_BUILD_TYPE} STREQUAL "Release" )
        SET( CONFIGURE_OPTIONS ${CONFIGURE_OPTIONS} --disable-debug )
    ELSE()
        MESSAGE ( FATAL_ERROR "Unknown CMAKE_BUILD_TYPE=${CMAKE_BUILD_TYPE}" )
    ENDIF()
    IF ( ENABLE_SHARED )
        SET( CONFIGURE_OPTIONS ${CONFIGURE_OPTIONS} --enable-shared )
    ELSE()
        SET( CONFIGURE_OPTIONS ${CONFIGURE_OPTIONS} --disable-shared )
    ENDIF()
    IF ( ENABLE_STATIC )
        SET( CONFIGURE_OPTIONS ${CONFIGURE_OPTIONS} --disable-shared )
    ELSE()
        SET( CONFIGURE_OPTIONS ${CONFIGURE_OPTIONS} --enable-shared )
    ENDIF()
    IF ( NOT USE_MPI )
        SET( CONFIGURE_OPTIONS ${CONFIGURE_OPTIONS} --without-MPI )
    ENDIF()
ENDIF()


# Build hypre
IF ( CMAKE_BUILD_HYPRE )
    ADD_TPL(
        HYPRE
        URL                 "${HYPRE_CMAKE_URL}"
        DOWNLOAD_DIR        "${HYPRE_CMAKE_DOWNLOAD_DIR}"
        SOURCE_DIR          "${HYPRE_CMAKE_SOURCE_DIR}"
        CONFIGURE_COMMAND   "./configure" --prefix=${HYPRE_INSTALL_DIR} ${CONFIGURE_OPTIONS} ${ENV_VARS}
        BUILD_COMMAND       make -j ${PROCS_INSTALL} VERBOSE=1
        BUILD_IN_SOURCE     1
        INSTALL_COMMAND     make install
        DEPENDS             ${HYPRE_DEPENDS}
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
FILE( APPEND "${FIND_TPLS_CMAKE}" "IF ( TPLs_FIND_HYPRE AND NOT TPL_FOUND_HYPRE )\n" )
FILE( APPEND "${FIND_TPLS_CMAKE}" "    INCLUDE( \"${CMAKE_INSTALL_PREFIX}/cmake/FindHypre.cmake\" )\n" )
FILE( APPEND "${FIND_TPLS_CMAKE}" "    SET( HYPRE_DIR \"${HYPRE_INSTALL_DIR}\" )\n" )
FILE( APPEND "${FIND_TPLS_CMAKE}" "    SET( HYPRE_DIRECTORY \"${HYPRE_INSTALL_DIR}\" )\n" )
FILE( APPEND "${FIND_TPLS_CMAKE}" "    HYPRE_SET_INCLUDES( ${HYPRE_INSTALL_DIR} )\n" )
FILE( APPEND "${FIND_TPLS_CMAKE}" "    HYPRE_SET_LIBRARIES( ${HYPRE_INSTALL_DIR} )\n" )
FILE( APPEND "${FIND_TPLS_CMAKE}" "    SET( TPL_INCLUDE_DIRS $\{TPL_INCLUDE_DIRS} $\{HYPRE_INCLUDE} )\n" )
FILE( APPEND "${FIND_TPLS_CMAKE}" "    SET( TPL_LIBRARIES $\{HYPRE_LIBS} $\{TPL_LIBRARIES} )\n" )
FILE( APPEND "${FIND_TPLS_CMAKE}" "    SET( HYPRE_FOUND TRUE )\n" )
FILE( APPEND "${FIND_TPLS_CMAKE}" "    SET( TPL_FOUND_HYPRE TRUE )\n" )
FILE( APPEND "${FIND_TPLS_CMAKE}" "ENDIF()\n" )
FILE( APPEND "${FIND_TPLS_CMAKE}" "\n" )



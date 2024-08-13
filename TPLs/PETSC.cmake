# This will configure and build petsc
# User can configure the source path by specifying PETSC_SRC_DIR,
#    the download path by specifying PETSC_URL, or the installed 
#    location by specifying PETSC_INSTALL_DIR


# Intialize download/src/install vars
SET( PETSC_BUILD_DIR "${CMAKE_BINARY_DIR}/PETSC-prefix/src/PETSC-build" )
IF ( PETSC_URL ) 
    MESSAGE("   PETSC_URL = ${PETSC_URL}")
    SET( PETSC_CMAKE_URL            "${PETSC_URL}"       )
    SET( PETSC_CMAKE_DOWNLOAD_DIR   "${PETSC_BUILD_DIR}" )
    SET( PETSC_CMAKE_SOURCE_DIR     "${PETSC_BUILD_DIR}" )
    SET( PETSC_CMAKE_INSTALL_DIR "${CMAKE_INSTALL_PREFIX}/petsc" )
    SET( CMAKE_BUILD_PETSC TRUE )
ELSEIF ( PETSC_SRC_DIR )
    VERIFY_PATH("${PETSC_SRC_DIR}")
    MESSAGE("   PETSC_SRC_DIR = ${PETSC_SRC_DIR}")
    SET( PETSC_CMAKE_URL            "${PETSC_SRC_DIR}"   )
    SET( PETSC_CMAKE_DOWNLOAD_DIR   "${PETSC_BUILD_DIR}" )
    SET( PETSC_CMAKE_SOURCE_DIR     "${PETSC_BUILD_DIR}" )
    SET( PETSC_CMAKE_INSTALL_DIR "${CMAKE_INSTALL_PREFIX}/petsc" )
    SET( CMAKE_BUILD_PETSC TRUE )
ELSEIF ( PETSC_INSTALL_DIR ) 
    SET( PETSC_CMAKE_INSTALL_DIR "${PETSC_INSTALL_DIR}" )
    SET( CMAKE_BUILD_PETSC FALSE )
ELSE()
    MESSAGE(FATAL_ERROR "Please specify PETSC_SRC_DIR, PETSC_URL, or PETSC_INSTALL_DIR")
ENDIF()
NULL_USE( PETSC_INSTALL_DIR PETSC_SRC_DIR PETSC_URL_DIR )
SET( PETSC_INSTALL_DIR "${PETSC_CMAKE_INSTALL_DIR}" )
MESSAGE( "   PETSC_INSTALL_DIR = ${PETSC_INSTALL_DIR}" )


# Configure optional/required TPLs
CONFIGURE_DEPENDENCIES( PETSC REQUIRED LAPACK )


# Configure petsc
IF ( CMAKE_BUILD_PETSC )
    IF ( ${CMAKE_BUILD_TYPE} STREQUAL "Debug" )
        SET( PETSC_ARCH linux-gnu-dbg )
        SET( BUILD_OPTS --with-debugging=1 )
    ELSEIF ( (${CMAKE_BUILD_TYPE} STREQUAL "Release") OR (${CMAKE_BUILD_TYPE} STREQUAL "RelWithDebInfo") )
        SET( PETSC_ARCH linux-gnu-opt )
        SET( BUILD_OPTS --with-debugging=0 )
    ELSE()
        MESSAGE ( FATAL_ERROR "Unknown CMAKE_BUILD_TYPE=${CMAKE_BUILD_TYPE}" )
    ENDIF()
    IF ( "${BLAS_LIBS}" MATCHES ";" )
        STRING( REPLACE ";" " " PETSC_BLAS_LIBS "${BLAS_LIBS}")
        SET( PETSC_BLAS_LIBS "'${PETSC_BLAS_LIBS}'" )
    ELSE()
        SET( PETSC_BLAS_LIBS "${BLAS_LIBS}" )
    ENDIF()
    IF ( "${LAPACK_LIBS}" MATCHES ";" )
        STRING( REPLACE ";" " " PETSC_LAPACK_LIBS "${LAPACK_LIBS}")
        SET( PETSC_LAPACK_LIBS "'${PETSC_LAPACK_LIBS}'" )
    ELSE()
        SET( PETSC_LAPACK_LIBS "${LAPACK_LIBS}" )
    ENDIF()
    SET( PETSC_CONFIGURE_OPTIONS --PETSC_ARCH=${PETSC_ARCH} --PETSC_DIR=${PETSC_CMAKE_SOURCE_DIR} )
    SET( PETSC_CONFIGURE_OPTIONS ${PETSC_CONFIGURE_OPTIONS} --prefix=${CMAKE_INSTALL_PREFIX}/petsc )
    #SET( PETSC_CONFIGURE_OPTIONS ${PETSC_CONFIGURE_OPTIONS} --with-clanguage=c++ )
    SET( PETSC_CONFIGURE_OPTIONS ${PETSC_CONFIGURE_OPTIONS} --with-x=false --with-x11=false )
    SET( PETSC_CONFIGURE_OPTIONS ${PETSC_CONFIGURE_OPTIONS} --with-valgrind=false )
    SET( PETSC_CONFIGURE_OPTIONS ${PETSC_CONFIGURE_OPTIONS} ${BUILD_OPTS} )
    SET( PETSC_CONFIGURE_OPTIONS ${PETSC_CONFIGURE_OPTIONS} --with-blas-lib=${PETSC_BLAS_LIBS} )
    SET( PETSC_CONFIGURE_OPTIONS ${PETSC_CONFIGURE_OPTIONS} --with-lapack-lib=${PETSC_LAPACK_LIBS} )
    #SET( PETSC_CONFIGURE_OPTIONS ${PETSC_CONFIGURE_OPTIONS} --with-pthread )
    SET( PETSC_CONFIGURE_OPTIONS ${PETSC_CONFIGURE_OPTIONS} --with-cmake-exec=${CMAKE_COMMAND} )
    SET( PETSC_CONFIGURE_OPTIONS ${PETSC_CONFIGURE_OPTIONS} --with-fortran-bindings=0 )
    SET( PETSC_CONFIGURE_OPTIONS ${PETSC_CONFIGURE_OPTIONS} --with-ssl=0 )
    IF ( USE_MPI )
        SET( PETSC_CONFIGURE_OPTIONS ${PETSC_CONFIGURE_OPTIONS} --CC=${MPI_C_COMPILER} --CFLAGS=${CMAKE_C_FLAGS} )
        SET( PETSC_CONFIGURE_OPTIONS ${PETSC_CONFIGURE_OPTIONS} --CXX=${MPI_CXX_COMPILER} --CXXFLAGS=${CMAKE_CXX_FLAGS} )
        SET( PETSC_CONFIGURE_OPTIONS ${PETSC_CONFIGURE_OPTIONS} --FC=${MPI_Fortran_COMPILER} --FFLAGS=${CMAKE_Fortran_FLAGS} --FCFLAGS=${CMAKE_Fortran_FLAGS} )
        SET( PETSC_CONFIGURE_OPTIONS ${PETSC_CONFIGURE_OPTIONS} --with-mpi )
    ELSE()
        SET( PETSC_CONFIGURE_OPTIONS ${PETSC_CONFIGURE_OPTIONS} --CC=${CMAKE_C_COMPILER} --CFLAGS=${CMAKE_C_FLAGS} )
        SET( PETSC_CONFIGURE_OPTIONS ${PETSC_CONFIGURE_OPTIONS} --CXX=${CMAKE_CXX_COMPILER} --CXXFLAGS=${CMAKE_CXX_FLAGS} )
        SET( PETSC_CONFIGURE_OPTIONS ${PETSC_CONFIGURE_OPTIONS} --FC=${CMAKE_Fortran_COMPILER} --FFLAGS=${CMAKE_Fortran_FLAGS} --FCFLAGS=${CMAKE_Fortran_FLAGS} )
        SET( PETSC_CONFIGURE_OPTIONS ${PETSC_CONFIGURE_OPTIONS} --without-mpi )
    ENDIF()
    IF ( ENABLE_SHARED AND ENABLE_STATIC )
        MESSAGE(FATAL_ERROR "Compiling petsc with both static and shared libraries is not yet supported")
    ELSEIF ( ENABLE_SHARED )
        # sowing has to be enabled for fortran stubs to be generated else shared linking fails
        SET( PETSC_CONFIGURE_OPTIONS ${PETSC_CONFIGURE_OPTIONS} --with-c2html=false --with-sowing=false )
        SET( PETSC_CONFIGURE_OPTIONS ${PETSC_CONFIGURE_OPTIONS} --with-shared-libraries=1 )
        SET( PETSC_CONFIGURE_OPTIONS ${PETSC_CONFIGURE_OPTIONS} --LDFLAGS=${CMAKE_SHARED_LINKER_FLAGS} )
    ELSEIF ( ENABLE_STATIC )
        SET( PETSC_CONFIGURE_OPTIONS ${PETSC_CONFIGURE_OPTIONS} --with-c2html=false --with-sowing=false )
        SET( PETSC_CONFIGURE_OPTIONS ${PETSC_CONFIGURE_OPTIONS} --with-shared-libraries=0 )
        SET( PETSC_CONFIGURE_OPTIONS ${PETSC_CONFIGURE_OPTIONS} )
    ENDIF()
    IF ( NOT PETSC_VERSION )
        SET( PETSC_VERSION "0.0.0" )
    ENDIF()
    IF ( "${PETSC_VERSION}" VERSION_GREATER_EQUAL "3.17.3" )
      SET( PETSC_PATCH_FILE "petsc.snes.patch.v3.19.0" )
    ELSE()
      SET( PETSC_PATCH_FILE "petsc.snes.patch" )
    ENDIF()
ENDIF()

IF ( CMAKE_BUILD_PETSC )

    # Build petsc
    ADD_TPL( 
        PETSC
        URL                 "${PETSC_CMAKE_URL}"
        DOWNLOAD_DIR        "${PETSC_CMAKE_DOWNLOAD_DIR}"
        SOURCE_DIR          "${PETSC_CMAKE_SOURCE_DIR}"
        UPDATE_COMMAND      ""
        PATCH_COMMAND       patch -p1 -i ${CMAKE_CURRENT_SOURCE_DIR}/patches/${PETSC_PATCH_FILE}
        CONFIGURE_COMMAND   ${PETSC_BUILD_DIR}/configure --prefix=${CMAKE_INSTALL_PREFIX}/petsc ${PETSC_CONFIGURE_OPTIONS}
        BUILD_COMMAND       $(MAKE) PETSC_DIR=${PETSC_CMAKE_SOURCE_DIR} PETSC_ARCH=${PETSC_ARCH} VERBOSE=1
        BUILD_IN_SOURCE     1
        INSTALL_COMMAND     $(MAKE) PETSC_DIR=${PETSC_CMAKE_SOURCE_DIR} PETSC_ARCH=${PETSC_ARCH} install
        CLEAN_COMMAND       $(MAKE) clean
        LOG_DOWNLOAD 1   LOG_UPDATE 1   LOG_CONFIGURE 1   LOG_BUILD 1   LOG_TEST 1   LOG_INSTALL 1
    )

ELSE()
  ADD_TPL_EMPTY( PETSC )
ENDIF()

# Add the appropriate fields to FindTPLs.cmake
CONFIGURE_FILE( ${CMAKE_CURRENT_SOURCE_DIR}/cmake/FindPetsc.cmake "${CMAKE_INSTALL_PREFIX}/cmake/FindPetsc.cmake" COPYONLY )
FILE( APPEND "${FIND_TPLS_CMAKE}" "\n# Find PETSC\n" )
FILE( APPEND "${FIND_TPLS_CMAKE}" "IF ( TPLs_FIND_PETSC AND NOT TPLs_PETSC_FOUND )\n" )
FILE( APPEND "${FIND_TPLS_CMAKE}" "    INCLUDE( \"${CMAKE_INSTALL_PREFIX}/cmake/FindPetsc.cmake\" )\n" )
FILE( APPEND "${FIND_TPLS_CMAKE}" "    PETSC_GET_VERSION( \"${PETSC_INSTALL_DIR}/include\" )\n" )
#FILE( APPEND "${FIND_TPLS_CMAKE}" "    PETSC_SET_LIBRARIES( \"${PETSC_INSTALL_DIR}/${PETSC_ARCH}/lib\" )\n" )
FILE( APPEND "${FIND_TPLS_CMAKE}" "    PETSC_SET_LIBRARIES( \"${PETSC_INSTALL_DIR}/lib\" )\n" )
FILE( APPEND "${FIND_TPLS_CMAKE}" "    SET( PETSC_INSTALL_DIR \"${PETSC_INSTALL_DIR}\" )\n" )
FILE( APPEND "${FIND_TPLS_CMAKE}" "    SET( PETSC_INCLUDE_DIR \"${PETSC_INSTALL_DIR}/include\" )\n" )
IF ( NOT USE_MPI )
    FILE( APPEND "${FIND_TPLS_CMAKE}" "    IF ( EXISTS \"${PETSC_INSTALL_DIR}/include/petsc/mpiuni\" )\n" )
    FILE( APPEND "${FIND_TPLS_CMAKE}" "        SET( PETSC_INCLUDE_DIR $\{PETSC_INCLUDE_DIR} \"${PETSC_INSTALL_DIR}/include/petsc/mpiuni\" )\n" )
    FILE( APPEND "${FIND_TPLS_CMAKE}" "    ENDIF()\n" )
ENDIF()
FILE( APPEND "${FIND_TPLS_CMAKE}" "    ADD_TPL_LIBRARY( PETSC $\{PETSC_LIBS} )\n" )
FILE( APPEND "${FIND_TPLS_CMAKE}" "ENDIF()\n" )
FILE( APPEND "${FIND_TPLS_CMAKE}" "\n" )


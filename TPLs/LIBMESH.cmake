# This will configure and build libmesh
# User can configure the source path by specifying LIBMESH_SRC_DIR,
#    the download path by specifying LIBMESH_URL, or the installed 
#    location by specifying LIBMESH_INSTALL_DIR


# Intialize download/src/install vars
SET( LIBMESH_BUILD_DIR "${CMAKE_BINARY_DIR}/LIBMESH-prefix/src/LIBMESH-build" )
IF ( LIBMESH_URL ) 
    MESSAGE_TPL("   LIBMESH_URL = ${LIBMESH_URL}")
    SET( LIBMESH_CMAKE_URL            "${LIBMESH_URL}"       )
    SET( LIBMESH_CMAKE_DOWNLOAD_DIR   "${LIBMESH_BUILD_DIR}" )
    SET( LIBMESH_CMAKE_SOURCE_DIR     "${LIBMESH_BUILD_DIR}" )
    SET( LIBMESH_CMAKE_INSTALL_DIR "${CMAKE_INSTALL_PREFIX}/libmesh" )
    SET( CMAKE_BUILD_LIBMESH TRUE )
ELSEIF ( LIBMESH_SRC_DIR )
    VERIFY_PATH("${LIBMESH_SRC_DIR}")
    MESSAGE_TPL("   LIBMESH_SRC_DIR = ${LIBMESH_SRC_DIR}" )
    SET( LIBMESH_CMAKE_URL            ""                  )
    SET( LIBMESH_CMAKE_DOWNLOAD_DIR   ""                  )
    SET( LIBMESH_CMAKE_SOURCE_DIR     "${LIBMESH_SRC_DIR}" )
    SET( LIBMESH_CMAKE_INSTALL_DIR "${CMAKE_INSTALL_PREFIX}/libmesh" )
    SET( CMAKE_BUILD_LIBMESH TRUE )
ELSEIF ( LIBMESH_INSTALL_DIR ) 
    SET( LIBMESH_CMAKE_INSTALL_DIR "${LIBMESH_INSTALL_DIR}" )
    SET( CMAKE_BUILD_LIBMESH FALSE )
ELSE()
    MESSAGE(FATAL_ERROR "Please specify LIBMESH_SRC_DIR, LIBMESH_URL, or LIBMESH_INSTALL_DIR")
ENDIF()
IF ( ${CMAKE_BUILD_TYPE} STREQUAL "Debug" )
    SET( LIBMESH_METHOD dbg )
ELSEIF ( ${CMAKE_BUILD_TYPE} STREQUAL "Release" )
    SET( LIBMESH_METHOD opt )
ELSE()
    MESSAGE ( FATAL_ERROR "Unknown CMAKE_BUILD_TYPE=${CMAKE_BUILD_TYPE}" )
ENDIF()
SET( LIBMESH_HOSTTYPE x86_64-unknown-linux-gnu )
SET( LIBMESH_INSTALL_DIR "${LIBMESH_CMAKE_INSTALL_DIR}" )
MESSAGE_TPL( "   LIBMESH_INSTALL_DIR = ${LIBMESH_INSTALL_DIR}" )
FILE( APPEND "${CMAKE_INSTALL_PREFIX}/TPLs.cmake" "SET(LIBMESH_INSTALL_DIR \"${LIBMESH_INSTALL_DIR}\")\n" )
FILE( APPEND "${CMAKE_INSTALL_PREFIX}/TPLs.cmake" "SET(LIBMESH_HOST_TYPE ${LIBMESH_HOSTTYPE} )\n" )
FILE( APPEND "${CMAKE_INSTALL_PREFIX}/TPLs.cmake" "SET(LIBMESH_COMPILE_TYPE ${LIBMESH_METHOD} )\n" )


# Configure libmesh
IF ( CMAKE_BUILD_LIBMESH )
    SET( CONFIGURE_OPTIONS )
    SET( CONFIGURE_OPTIONS ${CONFIGURE_OPTIONS} --prefix=${CMAKE_INSTALL_PREFIX}/libmesh )
    SET( CONFIGURE_OPTIONS ${CONFIGURE_OPTIONS} --with-cc=${CMAKE_C_COMPILER} )
    SET( CONFIGURE_OPTIONS ${CONFIGURE_OPTIONS} --with-cxx=${CMAKE_CXX_COMPILER} )
    SET( CONFIGURE_OPTIONS ${CONFIGURE_OPTIONS} --with-fc=${CMAKE_Fortran_COMPILER} )
    SET( CONFIGURE_OPTIONS ${CONFIGURE_OPTIONS} --with-f77=${CMAKE_Fortran_COMPILER} )
    SET( CONFIGURE_OPTIONS ${CONFIGURE_OPTIONS} --with-methods=${LIBMESH_METHOD} )
    IF ( ENABLE_GXX_DEBUG ) 
        SET( CONFIGURE_OPTIONS ${CONFIGURE_OPTIONS} --enable-glibcxx-debugging=yes )
    ELSE()
        SET( CONFIGURE_OPTIONS ${CONFIGURE_OPTIONS} --enable-glibcxx-debugging=no )
    ENDIF ()
    SET( CONFIGURE_OPTIONS ${CONFIGURE_OPTIONS} --enable-pfem       )
    SET( CONFIGURE_OPTIONS ${CONFIGURE_OPTIONS} --enable-bzip2      )
    SET( CONFIGURE_OPTIONS ${CONFIGURE_OPTIONS} --enable-second     )
    SET( CONFIGURE_OPTIONS ${CONFIGURE_OPTIONS} --disable-boost     )
    SET( CONFIGURE_OPTIONS ${CONFIGURE_OPTIONS} --disable-cppunit   )
    SET( CONFIGURE_OPTIONS ${CONFIGURE_OPTIONS} --disable-eigen     )
    SET( CONFIGURE_OPTIONS ${CONFIGURE_OPTIONS} --enable-exodus=v509 )
    SET( CONFIGURE_OPTIONS ${CONFIGURE_OPTIONS} --enable-netcdf=v3  )
    SET( CONFIGURE_OPTIONS ${CONFIGURE_OPTIONS} --disable-fparser   )
    SET( CONFIGURE_OPTIONS ${CONFIGURE_OPTIONS} --disable-glpk      )
    SET( CONFIGURE_OPTIONS ${CONFIGURE_OPTIONS} --disable-gmv       )
    SET( CONFIGURE_OPTIONS ${CONFIGURE_OPTIONS} --enable-gzstreams  )
    SET( CONFIGURE_OPTIONS ${CONFIGURE_OPTIONS} --disable-hdf5      )
    SET( CONFIGURE_OPTIONS ${CONFIGURE_OPTIONS} --disable-laspack   )
    SET( CONFIGURE_OPTIONS ${CONFIGURE_OPTIONS} --disable-libHilbert )
    SET( CONFIGURE_OPTIONS ${CONFIGURE_OPTIONS} --enable-metis      )
    SET( CONFIGURE_OPTIONS ${CONFIGURE_OPTIONS} --enable-mpi        )
    SET( CONFIGURE_OPTIONS ${CONFIGURE_OPTIONS} --disable-nanoflann )
    SET( CONFIGURE_OPTIONS ${CONFIGURE_OPTIONS} --disable-nemesis   )
    SET( CONFIGURE_OPTIONS ${CONFIGURE_OPTIONS} --disable-openmp    )
    SET( CONFIGURE_OPTIONS ${CONFIGURE_OPTIONS} --enable-parmetis   )
    SET( CONFIGURE_OPTIONS ${CONFIGURE_OPTIONS} --disable-petsc     )
    SET( CONFIGURE_OPTIONS ${CONFIGURE_OPTIONS} --disable-pthreads  )
    SET( CONFIGURE_OPTIONS ${CONFIGURE_OPTIONS} --disable-sfcurves  )
    SET( CONFIGURE_OPTIONS ${CONFIGURE_OPTIONS} --disable-slepc     )
    SET( CONFIGURE_OPTIONS ${CONFIGURE_OPTIONS} --disable-tbb       )
    SET( CONFIGURE_OPTIONS ${CONFIGURE_OPTIONS} --disable-tecio     )
    SET( CONFIGURE_OPTIONS ${CONFIGURE_OPTIONS} --disable-tecplot   )
    SET( CONFIGURE_OPTIONS ${CONFIGURE_OPTIONS} --disable-tetgen    )
    SET( CONFIGURE_OPTIONS ${CONFIGURE_OPTIONS} --disable-triangle  )
    SET( CONFIGURE_OPTIONS ${CONFIGURE_OPTIONS} --disable-trilinos  )
    SET( CONFIGURE_OPTIONS ${CONFIGURE_OPTIONS} --disable-vtk       )
    SET( CONFIGURE_OPTIONS ${CONFIGURE_OPTIONS} --disable-examples  )
    # SET( CONFIGURE_OPTIONS ${CONFIGURE_OPTIONS} --host=x86_64-unknown-linux-gnu )
    IF ( ENABLE_SHARED AND ENABLE_STATIC )
        MESSAGE(FATAL_ERROR "Compiling libmesh with both static and shared libraries is not supported")
    ELSEIF ( ENABLE_SHARED )
        SET( CONFIGURE_OPTIONS ${CONFIGURE_OPTIONS} --enable-shared --disable-static )
    ELSEIF ( ENABLE_STATIC )
        SET( CONFIGURE_OPTIONS ${CONFIGURE_OPTIONS} --disable-shared --enable-static --enable-all-static )
    ENDIF()
    IF ( ${CXX_STD} STREQUAL 98 )
        SET( LIBMESH_CXX_FLAGS -std=c++98 )
    ELSEIF ( ${CXX_STD} STREQUAL 03 )
        SET( LIBMESH_CXX_FLAGS -std=c++03 )
    ELSEIF ( ${CXX_STD} STREQUAL 11 )
        SET( LIBMESH_CXX_FLAGS -std=c++11 )
    ELSEIF ( ${CXX_STD} STREQUAL 14 )
        SET( LIBMESH_CXX_FLAGS -std=c++14 )
    ENDIF()
ENDIF()


# Build libmesh
IF ( CMAKE_BUILD_LIBMESH )
    EXTERNALPROJECT_ADD( 
        LIBMESH
        URL                 "${LIBMESH_CMAKE_URL}"
        DOWNLOAD_DIR        "${LIBMESH_CMAKE_DOWNLOAD_DIR}"
        SOURCE_DIR          "${LIBMESH_CMAKE_SOURCE_DIR}"
        UPDATE_COMMAND      ""
        CONFIGURE_COMMAND   ${LIBMESH_CMAKE_SOURCE_DIR}/configure ${CONFIGURE_OPTIONS} CXXFLAGS=${LIBMESH_CXX_FLAGS}
        BUILD_COMMAND       make -j ${PROCS_INSTALL} VERBOSE=1
        BUILD_IN_SOURCE     0
        INSTALL_COMMAND     make install
        DEPENDS             
        LOG_DOWNLOAD 1   LOG_UPDATE 1   LOG_CONFIGURE 1   LOG_BUILD 1   LOG_TEST 1   LOG_INSTALL 1
    )
    ADD_TPL_SAVE_LOGS( LIBMESH )
    ADD_TPL_CLEAN( LIBMESH )
ELSE()
    ADD_TPL_EMPTY( LIBMESH )
ENDIF()



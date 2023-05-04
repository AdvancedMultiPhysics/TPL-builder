# This will configure and build libmesh
# User can configure the source path by specifying LIBMESH_SRC_DIR,
#    the download path by specifying LIBMESH_URL, or the installed 
#    location by specifying LIBMESH_INSTALL_DIR


# Intialize download/src/install vars
SET( LIBMESH_BUILD_DIR "${CMAKE_BINARY_DIR}/LIBMESH-prefix/src/LIBMESH-build" )
IF ( LIBMESH_URL ) 
    MESSAGE("   LIBMESH_URL = ${LIBMESH_URL}")
    SET( LIBMESH_CMAKE_URL            "${LIBMESH_URL}"       )
    SET( LIBMESH_CMAKE_DOWNLOAD_DIR   "${LIBMESH_BUILD_DIR}" )
    SET( LIBMESH_CMAKE_SOURCE_DIR     "${LIBMESH_BUILD_DIR}" )
    SET( LIBMESH_CMAKE_INSTALL_DIR "${CMAKE_INSTALL_PREFIX}/libmesh" )
    SET( CMAKE_BUILD_LIBMESH TRUE )
ELSEIF ( LIBMESH_SRC_DIR )
    VERIFY_PATH("${LIBMESH_SRC_DIR}")
    MESSAGE("   LIBMESH_SRC_DIR = ${LIBMESH_SRC_DIR}" )
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
ELSEIF ( (${CMAKE_BUILD_TYPE} STREQUAL "Release") OR (${CMAKE_BUILD_TYPE} STREQUAL "RelWithDebInfo") )
    SET( LIBMESH_METHOD opt )
ELSE()
    MESSAGE ( FATAL_ERROR "Unknown CMAKE_BUILD_TYPE=${CMAKE_BUILD_TYPE}" )
ENDIF()
SET( LIBMESH_HOSTTYPE x86_64-unknown-linux-gnu )
SET( LIBMESH_INSTALL_DIR "${LIBMESH_CMAKE_INSTALL_DIR}" )
MESSAGE( "   LIBMESH_INSTALL_DIR = ${LIBMESH_INSTALL_DIR}" )


# Configure libmesh
IF ( CMAKE_BUILD_LIBMESH )
    SET( LIBMESH_CONFIGURE_OPTIONS )
    SET( LIBMESH_CONFIGURE_OPTIONS ${LIBMESH_CONFIGURE_OPTIONS} --prefix=${CMAKE_INSTALL_PREFIX}/libmesh )
    SET( LIBMESH_CONFIGURE_OPTIONS ${LIBMESH_CONFIGURE_OPTIONS} --with-cc=${CMAKE_C_COMPILER} )
    SET( LIBMESH_CONFIGURE_OPTIONS ${LIBMESH_CONFIGURE_OPTIONS} --with-cxx=${CMAKE_CXX_COMPILER} )
    SET( LIBMESH_CONFIGURE_OPTIONS ${LIBMESH_CONFIGURE_OPTIONS} --with-fc=${CMAKE_Fortran_COMPILER} )
    SET( LIBMESH_CONFIGURE_OPTIONS ${LIBMESH_CONFIGURE_OPTIONS} --with-f77=${CMAKE_Fortran_COMPILER} )
    SET( LIBMESH_CONFIGURE_OPTIONS ${LIBMESH_CONFIGURE_OPTIONS} --with-methods=${LIBMESH_METHOD} )
    IF( LIBMESH_MPI_PATH )
        SET( LIBMESH_CONFIGURE_OPTIONS ${LIBMESH_CONFIGURE_OPTIONS} --with-mpi=${LIBMESH_MPI_PATH} )
    ENDIF()
    IF ( USE_MPI )
        SET( LIBMESH_CONFIGURE_OPTIONS ${LIBMESH_CONFIGURE_OPTIONS} --enable-mpi )
    ELSE()
        SET( LIBMESH_CONFIGURE_OPTIONS ${LIBMESH_CONFIGURE_OPTIONS} --disable-mpi )
    ENDIF()
    IF ( ENABLE_GXX_DEBUG ) 
        SET( LIBMESH_CONFIGURE_OPTIONS ${LIBMESH_CONFIGURE_OPTIONS} --enable-glibcxx-debugging=yes )
    ELSE()
        SET( LIBMESH_CONFIGURE_OPTIONS ${LIBMESH_CONFIGURE_OPTIONS} --enable-glibcxx-debugging=no )
    ENDIF ()
    SET( LIBMESH_CONFIGURE_OPTIONS ${LIBMESH_CONFIGURE_OPTIONS} --enable-pfem       )
    SET( LIBMESH_CONFIGURE_OPTIONS ${LIBMESH_CONFIGURE_OPTIONS} --enable-bzip2      )
    SET( LIBMESH_CONFIGURE_OPTIONS ${LIBMESH_CONFIGURE_OPTIONS} --enable-second     )
    SET( LIBMESH_CONFIGURE_OPTIONS ${LIBMESH_CONFIGURE_OPTIONS} --disable-boost     )
    SET( LIBMESH_CONFIGURE_OPTIONS ${LIBMESH_CONFIGURE_OPTIONS} --disable-cppunit   )
    SET( LIBMESH_CONFIGURE_OPTIONS ${LIBMESH_CONFIGURE_OPTIONS} --disable-eigen     )
    SET( LIBMESH_CONFIGURE_OPTIONS ${LIBMESH_CONFIGURE_OPTIONS} --enable-exodus=v522 )
    SET( LIBMESH_CONFIGURE_OPTIONS ${LIBMESH_CONFIGURE_OPTIONS} --enable-netcdf=v3  )
    SET( LIBMESH_CONFIGURE_OPTIONS ${LIBMESH_CONFIGURE_OPTIONS} --disable-fparser   )
    SET( LIBMESH_CONFIGURE_OPTIONS ${LIBMESH_CONFIGURE_OPTIONS} --disable-glpk      )
    SET( LIBMESH_CONFIGURE_OPTIONS ${LIBMESH_CONFIGURE_OPTIONS} --disable-gmv       )
    SET( LIBMESH_CONFIGURE_OPTIONS ${LIBMESH_CONFIGURE_OPTIONS} --enable-gzstreams  )
    SET( LIBMESH_CONFIGURE_OPTIONS ${LIBMESH_CONFIGURE_OPTIONS} --disable-hdf5      )
    SET( LIBMESH_CONFIGURE_OPTIONS ${LIBMESH_CONFIGURE_OPTIONS} --disable-laspack   )
    SET( LIBMESH_CONFIGURE_OPTIONS ${LIBMESH_CONFIGURE_OPTIONS} --disable-libHilbert )
    SET( LIBMESH_CONFIGURE_OPTIONS ${LIBMESH_CONFIGURE_OPTIONS} --enable-metis      )

    SET( LIBMESH_CONFIGURE_OPTIONS ${LIBMESH_CONFIGURE_OPTIONS} --disable-nanoflann )
    SET( LIBMESH_CONFIGURE_OPTIONS ${LIBMESH_CONFIGURE_OPTIONS} --disable-nemesis   )
    SET( LIBMESH_CONFIGURE_OPTIONS ${LIBMESH_CONFIGURE_OPTIONS} --disable-openmp    )
    SET( LIBMESH_CONFIGURE_OPTIONS ${LIBMESH_CONFIGURE_OPTIONS} --enable-parmetis   )
    SET( LIBMESH_CONFIGURE_OPTIONS ${LIBMESH_CONFIGURE_OPTIONS} --disable-petsc     )
    SET( LIBMESH_CONFIGURE_OPTIONS ${LIBMESH_CONFIGURE_OPTIONS} --disable-pthreads  )
    SET( LIBMESH_CONFIGURE_OPTIONS ${LIBMESH_CONFIGURE_OPTIONS} --disable-sfcurves  )
    SET( LIBMESH_CONFIGURE_OPTIONS ${LIBMESH_CONFIGURE_OPTIONS} --disable-slepc     )
    SET( LIBMESH_CONFIGURE_OPTIONS ${LIBMESH_CONFIGURE_OPTIONS} --disable-tbb       )
    SET( LIBMESH_CONFIGURE_OPTIONS ${LIBMESH_CONFIGURE_OPTIONS} --disable-tecio     )
    SET( LIBMESH_CONFIGURE_OPTIONS ${LIBMESH_CONFIGURE_OPTIONS} --disable-tecplot   )
    SET( LIBMESH_CONFIGURE_OPTIONS ${LIBMESH_CONFIGURE_OPTIONS} --disable-tetgen    )
    SET( LIBMESH_CONFIGURE_OPTIONS ${LIBMESH_CONFIGURE_OPTIONS} --disable-triangle  )
    SET( LIBMESH_CONFIGURE_OPTIONS ${LIBMESH_CONFIGURE_OPTIONS} --disable-trilinos  )
    SET( LIBMESH_CONFIGURE_OPTIONS ${LIBMESH_CONFIGURE_OPTIONS} --disable-vtk       )
    SET( LIBMESH_CONFIGURE_OPTIONS ${LIBMESH_CONFIGURE_OPTIONS} --disable-examples  )
    # SET( LIBMESH_CONFIGURE_OPTIONS ${LIBMESH_CONFIGURE_OPTIONS} --host=x86_64-unknown-linux-gnu )
    IF ( ENABLE_SHARED AND ENABLE_STATIC )
        MESSAGE(FATAL_ERROR "Compiling libmesh with both static and shared libraries is not supported")
    ELSEIF ( ENABLE_SHARED )
        SET( LIBMESH_CONFIGURE_OPTIONS ${LIBMESH_CONFIGURE_OPTIONS} --enable-shared --disable-static )
    ELSEIF ( ENABLE_STATIC )
        SET( LIBMESH_CONFIGURE_OPTIONS ${LIBMESH_CONFIGURE_OPTIONS} --disable-shared --enable-static )
    ENDIF()
    IF ( ${CXX_STD} STREQUAL 98 )
        SET( LIBMESH_CXX_FLAGS -std=c++98 )
    ELSEIF ( ${CXX_STD} STREQUAL 03 )
        SET( LIBMESH_CXX_FLAGS -std=c++03 )
    ELSEIF ( ${CXX_STD} STREQUAL 11 )
        SET( LIBMESH_CXX_FLAGS -std=c++11 )
    ELSEIF ( ${CXX_STD} STREQUAL 14 )
        SET( LIBMESH_CXX_FLAGS -std=c++14 )
    ELSEIF ( ${CXX_STD} STREQUAL 17 )
        SET( LIBMESH_CXX_FLAGS -std=c++17 )
    ENDIF()
    # for some strange reason this is required for linking when MPI is not turned on
    # even if pthreads is disabled   
    SET( LIBMESH_LD_FLAGS -pthread )
ENDIF()


# Build libmesh
ADD_TPL( 
    LIBMESH
    URL                 "${LIBMESH_CMAKE_URL}"
    DOWNLOAD_DIR        "${LIBMESH_CMAKE_DOWNLOAD_DIR}"
    SOURCE_DIR          "${LIBMESH_CMAKE_SOURCE_DIR}"
    UPDATE_COMMAND      ""
    CONFIGURE_COMMAND   ${LIBMESH_CMAKE_SOURCE_DIR}/configure ${LIBMESH_CONFIGURE_OPTIONS} CXXFLAGS=${LIBMESH_CXX_FLAGS} LDFLAGS=${LIBMESH_LD_FLAGS}
    BUILD_COMMAND       $(MAKE) VERBOSE=1
    BUILD_IN_SOURCE     0
    INSTALL_COMMAND     $(MAKE) install
    CLEAN_COMMAND       $(MAKE) clean
    DEPENDS             
    LOG_DOWNLOAD 1   LOG_UPDATE 1   LOG_CONFIGURE 1   LOG_BUILD 1   LOG_TEST 1   LOG_INSTALL 1
)


# Add the appropriate fields to FindTPLs.cmake
CONFIGURE_FILE( ${CMAKE_CURRENT_SOURCE_DIR}/cmake/FindLibmesh.cmake "${CMAKE_INSTALL_PREFIX}/cmake/FindLibmesh.cmake" COPYONLY )
FILE( APPEND "${FIND_TPLS_CMAKE}" "\n# Find LIBMESH\n" )
FILE( APPEND "${FIND_TPLS_CMAKE}" "IF ( TPLs_FIND_LIBMESH AND NOT TPL_FOUND_LIBMESH )\n" )
FILE( APPEND "${FIND_TPLS_CMAKE}" "    INCLUDE( \"${CMAKE_INSTALL_PREFIX}/cmake/FindLibmesh.cmake\" )\n" )
FILE( APPEND "${FIND_TPLS_CMAKE}" "    SET( LIBMESH_DIR \"${LIBMESH_INSTALL_DIR}\" )\n" )
FILE( APPEND "${FIND_TPLS_CMAKE}" "    SET( LIBMESH_DIRECTORY \"${LIBMESH_INSTALL_DIR}\" )\n" )
FILE( APPEND "${FIND_TPLS_CMAKE}" "    SET( LIBMESH_INCLUDE \"${LIBMESH_INSTALL_DIR}/include\" )\n" )
FILE( APPEND "${FIND_TPLS_CMAKE}" "    FIND_PACKAGE( OpenMP )\n" )  # Libmesh disable-openmp does not actually disable OpenMP
FILE( APPEND "${FIND_TPLS_CMAKE}" "    LIBMESH_SET_INCLUDES( $\{LIBMESH_DIRECTORY} )\n" )
FILE( APPEND "${FIND_TPLS_CMAKE}" "    LIBMESH_SET_LIBRARIES( $\{LIBMESH_DIRECTORY} )\n" )
FILE( APPEND "${FIND_TPLS_CMAKE}" "    SET( TPL_INCLUDE_DIRS $\{TPL_INCLUDE_DIRS} $\{LIBMESH_INCLUDE} )\n" )
FILE( APPEND "${FIND_TPLS_CMAKE}" "    SET( TPL_LIBRARIES $\{LIBMESH_LIBS} $\{OpenMP_CXX_LIBRARIES} $\{TPL_LIBRARIES} )\n" )
FILE( APPEND "${FIND_TPLS_CMAKE}" "    SET( LIBMESH_FOUND TRUE )\n" )
FILE( APPEND "${FIND_TPLS_CMAKE}" "    SET( TPL_FOUND_LIBMESH TRUE )\n" )
FILE( APPEND "${FIND_TPLS_CMAKE}" "ENDIF()\n" )
FILE( APPEND "${FIND_TPLS_CMAKE}" "\n" )


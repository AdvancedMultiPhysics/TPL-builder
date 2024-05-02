# This will configure and build hdf5
# User can configure the source path by specifying HDF5_SRC_DIR
#    the download path by specifying HDF5_URL, or the installed 
#    location by specifying HDF5_INSTALL_DIR


# Intialize download/src/install vars
SET( HDF5_BUILD_DIR "${CMAKE_BINARY_DIR}/HDF5-prefix/src/HDF5-build" )
IF ( HDF5_URL ) 
    MESSAGE("   HDF5_URL = ${HDF5_URL}")
    SET( HDF5_SRC_DIR "${CMAKE_BINARY_DIR}/HDF5-prefix/src/HDF5-src" )
    SET( HDF5_CMAKE_URL            "${HDF5_URL}"       )
    SET( HDF5_CMAKE_DOWNLOAD_DIR   "${HDF5_SRC_DIR}" )
    SET( HDF5_CMAKE_SOURCE_DIR     "${HDF5_SRC_DIR}" )
    SET( HDF5_CMAKE_INSTALL_DIR "${CMAKE_INSTALL_PREFIX}/hdf5" )
    SET( CMAKE_BUILD_HDF5 TRUE )
ELSEIF ( HDF5_SRC_DIR )
    VERIFY_PATH("${HDF5_SRC_DIR}")
    MESSAGE("   HDF5_SRC_DIR = ${HDF5_SRC_DIR}")
    SET( HDF5_CMAKE_URL            ""   )
    SET( HDF5_CMAKE_DOWNLOAD_DIR   "" )
    SET( HDF5_CMAKE_SOURCE_DIR     "${HDF5_SRC_DIR}" )
    SET( HDF5_CMAKE_INSTALL_DIR "${CMAKE_INSTALL_PREFIX}/hdf5" )
    SET( CMAKE_BUILD_HDF5 TRUE )
ELSEIF ( HDF5_INSTALL_DIR ) 
    SET( HDF5_CMAKE_INSTALL_DIR "${HDF5_INSTALL_DIR}" )
    SET( CMAKE_BUILD_HDF5 FALSE )
ELSE()
    MESSAGE(FATAL_ERROR "Please specify HDF5_URL, HDF5_SRC_DIR, or HDF5_INSTALL_DIR")
ENDIF()
FILE( MAKE_DIRECTORY "${HDF5_CMAKE_INSTALL_DIR}" )
SET( HDF5_INSTALL_DIR "${HDF5_CMAKE_INSTALL_DIR}" )
MESSAGE( "   HDF5_INSTALL_DIR = ${HDF5_INSTALL_DIR}" )

# Configure hdf5
IF ( CMAKE_BUILD_HDF5 )
    IF ( "${HDF5_VERSION}" VERSION_LESS "1.12.0" )
        MESSAGE ( FATAL_ERROR "HDF5 1.12.0 or greater required" )
    ENDIF()    
    EXECUTE_PROCESS( COMMAND ${CMAKE_COMMAND} -E make_directory "${HDF5_INSTALL_DIR}/include" )
    EXECUTE_PROCESS( COMMAND ${CMAKE_COMMAND} -E make_directory "${HDF5_INSTALL_DIR}/lib" )
    SET( HDF5_CONFIGURE_OPTIONS -DCMAKE_INSTALL_PREFIX=${HDF5_CMAKE_INSTALL_DIR} )
    SET( HDF5_CONFIGURE_OPTIONS ${HDF5_CONFIGURE_OPTIONS} -DCTEST_BUILD_CONFIGURATION=${CMAKE_BUILD_TYPE} )
    SET( HDF5_COMPONENTS "C" )
    SET( HDF5_DEPENDS )
    IF ( HDF5_ENABLE_CXX )
        SET( HDF5_COMPONENTS "${HDF5_COMPONENTS} CXX" )
        SET( HDF5_CONFIGURE_OPTIONS ${HDF5_CONFIGURE_OPTIONS} -DHDF5_BUILD_CPP_LIB:BOOL=ON )
    ELSE()
        SET( HDF5_CONFIGURE_OPTIONS ${HDF5_CONFIGURE_OPTIONS} -DHDF5_BUILD_CPP_LIB:BOOL=OFF )
    ENDIF()
    IF ( HDF5_ENABLE_UNSUPPORTED )
        SET( HDF5_CONFIGURE_OPTIONS ${HDF5_CONFIGURE_OPTIONS} -DALLOW_UNSUPPORTED:BOOL=ON )
    ENDIF()
    IF ( USE_MPI )
        SET( HDF5_CONFIGURE_OPTIONS ${HDF5_CONFIGURE_OPTIONS} -DHDF5_ENABLE_PARALLEL:BOOL=ON )
        IF ( MPIEXEC )
            SET( HDF5_CONFIGURE_OPTIONS ${HDF5_CONFIGURE_OPTIONS} -DMPIEXEC:FILEPATH=${MPIEXEC} )
        ENDIF()
    ELSE()
        SET( HDF5_CONFIGURE_OPTIONS ${HDF5_CONFIGURE_OPTIONS} -DHDF5_ENABLE_PARALLEL:BOOL=OFF )
    ENDIF()
    IF ( NOT DEFINED HDF5_ENABLE_FORTRAN )
        SET( HDF5_ENABLE_FORTRAN 1 )
    ENDIF()
    IF ( HDF5_ENABLE_FORTRAN )
        SET( HDF5_COMPONENTS "${HDF5_COMPONENTS} Fortran" )
        SET( HDF5_CONFIGURE_OPTIONS ${HDF5_CONFIGURE_OPTIONS} -DHDF5_BUILD_FORTRAN:BOOL=ON )
    ENDIF()
    IF ( ZLIB_INCLUDE_DIR )
        SET( HDF5_DEPENDS ZLIB )
        SET( HDF5_CONFIGURE_OPTIONS ${HDF5_CONFIGURE_OPTIONS} -DHDF5_ENABLE_Z_LIB_SUPPORT:BOOL=ON )
    ENDIF()
    SET( HDF5_CONFIGURE_OPTIONS ${HDF5_CONFIGURE_OPTIONS} -DZLIB_USE_EXTERNAL:BOOL=OFF -DZLIB_INCLUDE_DIR:PATH='${ZLIB_INCLUDE_DIR}' )
    IF ( ENABLE_SHARED )
        SET( HDF5_CONFIGURE_OPTIONS ${HDF5_CONFIGURE_OPTIONS} -DZLIB_LIBRARY:FILEPATH='${ZLIB_LIB_DIR}/libz.so' )
        SET( HDF5_CONFIGURE_OPTIONS ${HDF5_CONFIGURE_OPTIONS} -DBUILD_SHARED_LIBS:BOOL=ON )
        IF ( "${CMAKE_SYSTEM_NAME}" STREQUAL "Darwin" AND HDF5_ENABLE_FORTRAN )
            MESSAGE( WARNING "Shared fortran libraries are not supported by HDF5 on MAC and will likely fail to configure")
        ENDIF()
    ELSE()
        SET( HDF5_CONFIGURE_OPTIONS ${HDF5_CONFIGURE_OPTIONS} -DZLIB_LIBRARY:FILEPATH='${ZLIB_LIB_DIR}/libz.a' )
        SET( HDF5_CONFIGURE_OPTIONS ${HDF5_CONFIGURE_OPTIONS} -DBUILD_SHARED_LIBS:BOOL=OFF )
    ENDIF()
    IF ( ENABLE_STATIC )
        SET( HDF5_CONFIGURE_OPTIONS ${HDF5_CONFIGURE_OPTIONS} -DBUILD_SHARED_LIBS:BOOL=OFF )
    ELSE()
        SET( HDF5_CONFIGURE_OPTIONS ${HDF5_CONFIGURE_OPTIONS} -DBUILD_SHARED_LIBS:BOOL=ON )
    ENDIF()
    SET( HDF5_CONFIGURE_OPTIONS ${HDF5_CONFIGURE_OPTIONS} -DBUILD_TESTING:BOOL=OFF )
ELSE()
    SET( HDF5_COMPONENTS "C" )
    FIND_LIBRARY( HDF5_CXX_LIBRARY  NAMES hdf5_cxx PATHS "${HDF5_INSTALL_DIR}/lib"  NO_DEFAULT_PATH )
    FIND_LIBRARY( HDF5_Fortran_LIBRARY  NAMES hdf5_fortran PATHS "${HDF5_INSTALL_DIR}/lib"  NO_DEFAULT_PATH )
    IF ( HDF5_CXX_LIBRARY )
        SET( HDF5_COMPONENTS "${HDF5_COMPONENTS} CXX" )
    ENDIF()
    IF ( HDF5_Fortran_LIBRARY )
        SET( HDF5_COMPONENTS "${HDF5_COMPONENTS} Fortran" )
    ENDIF()
ENDIF()

IF ( CMAKE_BUILD_HDF5 )

    # Build hdf5
    ADD_TPL(
        HDF5
        URL                 "${HDF5_CMAKE_URL}"
        DOWNLOAD_DIR        "${HDF5_CMAKE_DOWNLOAD_DIR}"
        SOURCE_DIR          "${HDF5_CMAKE_SOURCE_DIR}"
        UPDATE_COMMAND      ""
        CMAKE_ARGS          ${HDF5_CONFIGURE_OPTIONS} ${ENV_VARS}
        BUILD_COMMAND       $(MAKE) install VERBOSE=1
        BUILD_IN_SOURCE     0
        INSTALL_COMMAND     ""
        CLEAN_COMMAND       $(MAKE) clean
        DEPENDS             ${HDF5_DEPENDS}
        LOG_DOWNLOAD 1   LOG_UPDATE 1   LOG_CONFIGURE 1   LOG_BUILD 1   LOG_TEST 1   LOG_INSTALL 1
    )

ELSE()
    ADD_TPL_EMPTY( HDF5 )
ENDIF()

# Add the appropriate fields to FindTPLs.cmake
FILE( APPEND "${FIND_TPLS_CMAKE}" "\n# Find HDF5\n" )
FILE( APPEND "${FIND_TPLS_CMAKE}" "IF ( TPLs_FIND_HDF5 AND NOT TPL_FOUND_HDF5 )\n" )
FILE( APPEND "${FIND_TPLS_CMAKE}" "    SET( HDF5_ROOT \"${HDF5_INSTALL_DIR}\" )\n" )
IF ( ENABLE_SHARED )
    FILE( APPEND "${FIND_TPLS_CMAKE}" "    SET( HDF5_USE_STATIC_LIBRARIES FALSE )\n" )
ELSE()
    FILE( APPEND "${FIND_TPLS_CMAKE}" "    SET( HDF5_USE_STATIC_LIBRARIES TRUE )\n" )
ENDIF()
FILE( APPEND "${FIND_TPLS_CMAKE}" "    FIND_PACKAGE( HDF5 COMPONENTS ${HDF5_COMPONENTS} )\n" )
FILE( APPEND "${FIND_TPLS_CMAKE}" "    SET( CMAKE_INSTALL_RPATH $\{CMAKE_INSTALL_RPATH} \"$\{HDF5_ROOT}/lib\" )\n" )
FILE( APPEND "${FIND_TPLS_CMAKE}" "    SET( TPL_INCLUDE_DIRS $\{TPL_INCLUDE_DIRS} $\{HDF5_INCLUDE_DIRS} )\n" )
FILE( APPEND "${FIND_TPLS_CMAKE}" "    SET( TPL_LIBRARIES $\{HDF5_LIBRARIES} $\{TPL_LIBRARIES} )\n" )
FILE( APPEND "${FIND_TPLS_CMAKE}" "    SET( TPL_FOUND_HDF5 $\{HDF5_FOUND} )\n" )
FILE( APPEND "${FIND_TPLS_CMAKE}" "ENDIF()\n" )
FILE( APPEND "${FIND_TPLS_CMAKE}" "\n" )

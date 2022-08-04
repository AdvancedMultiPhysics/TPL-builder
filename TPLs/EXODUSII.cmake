# This will configure and build exodusii
# User can configure the source path by specifying EXODUSII_SRC_DIR,
#    the download path by specifying EXODUSII_URL, or the installed 
#    location by specifying EXODUSII_INSTALL_DIR


# Intialize download/src/install vars
SET( EXODUSII_BUILD_DIR "${CMAKE_BINARY_DIR}/EXODUSII-prefix/src/EXODUSII-build" )
IF ( EXODUSII_URL ) 
    MESSAGE("   EXODUSII_URL = ${EXODUSII_URL}")
    SET( EXODUSII_SRC_DIR "${CMAKE_BINARY_DIR}/EXODUSII-prefix/src/EXODUSII-src" )
    SET( EXODUSII_CMAKE_URL            "${EXODUSII_URL}"     )
    SET( EXODUSII_CMAKE_DOWNLOAD_DIR   "${EXODUSII_SRC_DIR}" )
    SET( EXODUSII_CMAKE_SOURCE_DIR     "${EXODUSII_SRC_DIR}" )
    SET( EXODUSII_CMAKE_INSTALL_DIR "${CMAKE_INSTALL_PREFIX}/exodusii" )
    SET( CMAKE_BUILD_EXODUSII TRUE )
ELSEIF ( EXODUSII_SRC_DIR )
    VERIFY_PATH("${EXODUSII_SRC_DIR}")
    MESSAGE("   EXODUSII_SRC_DIR = ${EXODUSII_SRC_DIR}")
    SET( EXODUSII_CMAKE_URL            ""                  )
    SET( EXODUSII_CMAKE_DOWNLOAD_DIR   ""                  )
    SET( EXODUSII_CMAKE_SOURCE_DIR     "${EXODUSII_SRC_DIR}" )
    SET( EXODUSII_CMAKE_INSTALL_DIR "${CMAKE_INSTALL_PREFIX}/exodusii" )
    SET( CMAKE_BUILD_EXODUSII TRUE )
ELSEIF ( EXODUSII_INSTALL_DIR ) 
    SET( EXODUSII_CMAKE_INSTALL_DIR "${EXODUSII_INSTALL_DIR}" )
    SET( CMAKE_BUILD_EXODUSII FALSE )
ELSE()
    MESSAGE(FATAL_ERROR "Please specify EXODUSII_SRC_DIR, EXODUSII_URL, or EXODUSII_INSTALL_DIR")
ENDIF()
SET( EXODUSII_INSTALL_DIR "${EXODUSII_CMAKE_INSTALL_DIR}" )
MESSAGE( "   EXODUSII_INSTALL_DIR = ${EXODUSII_INSTALL_DIR}" )


# Configure exodusii
IF ( CMAKE_BUILD_EXODUSII )
    SET( EXODUSII_CONFIGURE_OPTIONS "${CMAKE_ARGS};-DCMAKE_INSTALL_PREFIX=${CMAKE_INSTALL_PREFIX}/exodusii" )
    SET( EXODUSII_CONFIGURE_OPTIONS "${EXODUSII_CONFIGURE_OPTIONS};-DHDF5HL_LIBRARY=${CMAKE_INSTALL_PREFIX}/hdf5/lib/libhdf5_hl.a" )
    SET( EXODUSII_CONFIGURE_OPTIONS "${EXODUSII_CONFIGURE_OPTIONS};-DHDF5_LIBRARY=${CMAKE_INSTALL_PREFIX}/hdf5/lib/libhdf5.a" )
    SET( EXODUSII_CONFIGURE_OPTIONS "${EXODUSII_CONFIGURE_OPTIONS};-DNETCDF_INCLUDE_DIR:PATH=${CMAKE_INSTALL_PREFIX}/netcdf/include" )
    SET( EXODUSII_CONFIGURE_OPTIONS "${EXODUSII_CONFIGURE_OPTIONS};-DNETCDF_LIBRARY=${CMAKE_INSTALL_PREFIX}/netcdf/lib/libnetcdf.a" )
    SET( EXODUSII_CONFIGURE_OPTIONS "${EXODUSII_CONFIGURE_OPTIONS};-DNETCDF_NCDUMP=${CMAKE_INSTALL_PREFIX}/netcdf/bin/ncdump" )
    SET( EXODUSII_CONFIGURE_OPTIONS "${EXODUSII_CONFIGURE_OPTIONS};-DZ_LIBRARY:PATH=${CMAKE_INSTALL_PREFIX}/zlib/lib/libz.a" )
    SET( EXODUSII_CONFIGURE_OPTIONS "${EXODUSII_CONFIGURE_OPTIONS};-DCMAKE_C_STANDARD_LIBRARIES=${CMAKE_INSTALL_PREFIX}/zlib/lib/libz.a" )
    SET( EXODUSII_CONFIGURE_OPTIONS "${EXODUSII_CONFIGURE_OPTIONS};-DCMAKE_CXX_STANDARD_LIBRARIES=${CMAKE_INSTALL_PREFIX}/zlib/lib/libz.a" )
ENDIF()


# Build exodusii
ADD_TPL(
    EXODUSII
    URL                 "${EXODUSII_CMAKE_URL}"
    DOWNLOAD_DIR        "${EXODUSII_CMAKE_DOWNLOAD_DIR}"
    SOURCE_DIR          "${EXODUSII_CMAKE_SOURCE_DIR}"
    UPDATE_COMMAND      ""
    BUILD_IN_SOURCE     0
    INSTALL_DIR         ${CMAKE_INSTALL_PREFIX}/exodusii
    CMAKE_ARGS          "${EXODUSII_CONFIGURE_OPTIONS}"
    BUILD_COMMAND       $(MAKE) install VERBOSE=1
    DEPENDS             HDF5 ZLIB NETCDF
    LOG_DOWNLOAD 1   LOG_UPDATE 1   LOG_CONFIGURE 1   LOG_BUILD 1   LOG_TEST 1   LOG_INSTALL 1
)



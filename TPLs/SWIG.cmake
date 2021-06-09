# This will configure and build swig
# User can configure the source path by specifying SWIG_SRC_DIR
#    the download path by specifying SWIG_URL, or the installed 
#    location by specifying SWIG_INSTALL_DIR


# Intialize download/src/install vars
SET( SWIG_BUILD_DIR "${CMAKE_BINARY_DIR}/SWIG-prefix/src/SWIG-build" )
IF ( SWIG_URL ) 
    MESSAGE("   SWIG_URL = ${SWIG_URL}")
    SET( SWIG_CMAKE_URL            "${SWIG_URL}"       )
    SET( SWIG_CMAKE_DOWNLOAD_DIR   "${SWIG_BUILD_DIR}" )
    SET( SWIG_CMAKE_SOURCE_DIR     "${SWIG_BUILD_DIR}" )
    SET( SWIG_CMAKE_INSTALL_DIR "${CMAKE_INSTALL_PREFIX}/swig" )
    SET( CMAKE_BUILD_SWIG TRUE )
ELSEIF ( SWIG_SRC_DIR )
    MESSAGE("   SWIG_SRC_DIR = ${SWIG_SRC_DIR}")
    SET( SWIG_CMAKE_URL            "${SWIG_SRC_DIR}"   )
    SET( SWIG_CMAKE_DOWNLOAD_DIR   "${SWIG_BUILD_DIR}" )
    SET( SWIG_CMAKE_SOURCE_DIR     "${SWIG_BUILD_DIR}" )
    SET( SWIG_CMAKE_INSTALL_DIR "${CMAKE_INSTALL_PREFIX}/swig" )
    SET( CMAKE_BUILD_SWIG TRUE )
ELSEIF ( SWIG_INSTALL_DIR ) 
    SET( SWIG_CMAKE_INSTALL_DIR "${SWIG_INSTALL_DIR}" )
    SET( CMAKE_BUILD_SWIG FALSE )
ELSE()
    MESSAGE(FATAL_ERROR "Please specify SWIG_SRC_DIR")
ENDIF()
FILE( MAKE_DIRECTORY "${SWIG_CMAKE_INSTALL_DIR}" )
SET( SWIG_INSTALL_DIR "${SWIG_CMAKE_INSTALL_DIR}" )
MESSAGE( "   SWIG_INSTALL_DIR = ${SWIG_INSTALL_DIR}" )

# Configure swig
IF ( CMAKE_BUILD_SWIG )
    EXECUTE_PROCESS( COMMAND ${CMAKE_COMMAND} -E make_directory "${SWIG_INSTALL_DIR}/include" )
    EXECUTE_PROCESS( COMMAND ${CMAKE_COMMAND} -E make_directory "${SWIG_INSTALL_DIR}/lib" )
    SET( CONFIGURE_OPTIONS --prefix=${SWIG_INSTALL_DIR} )
ENDIF()

# Build swig
ADD_TPL(
    SWIG
    URL                 "${SWIG_CMAKE_URL}"
    DOWNLOAD_DIR        "${SWIG_CMAKE_DOWNLOAD_DIR}"
    SOURCE_DIR          "${SWIG_CMAKE_SOURCE_DIR}"
    UPDATE_COMMAND      ""
    CONFIGURE_COMMAND   ${SWIG_CMAKE_SOURCE_DIR}/configure ${CONFIGURE_OPTIONS} ${ENV_VARS}
    BUILD_COMMAND       make -j ${PROCS_INSTALL} VERBOSE=1
    BUILD_IN_SOURCE     0
    INSTALL_COMMAND     make install
    DEPENDS             ZLIB
    LOG_DOWNLOAD 1   LOG_UPDATE 1   LOG_CONFIGURE 1   LOG_BUILD 1   LOG_TEST 1   LOG_INSTALL 1
)


# Add the appropriate fields to FindTPLs.cmake
FILE( APPEND "${FIND_TPLS_CMAKE}" "\n# Find SWIG\n" )
FILE( APPEND "${FIND_TPLS_CMAKE}" "IF ( TPLs_FIND_SWIG AND NOT TPL_FOUND_SWIG )\n" )
FILE( APPEND "${FIND_TPLS_CMAKE}" "    SET( ENV{SWIG_ROOT} \"${SWIG_INSTALL_DIR}\" )\n" )
FILE( APPEND "${FIND_TPLS_CMAKE}" "    FIND_PACKAGE( SWIG COMPONENTS ${SWIG_COMPONENTS} )\n" )
FILE( APPEND "${FIND_TPLS_CMAKE}" "    SET( TPL_INCLUDE_DIRS $\{TPL_INCLUDE_DIRS} $\{SWIG_INCLUDE_DIRS} )\n" )
FILE( APPEND "${FIND_TPLS_CMAKE}" "    SET( TPL_LIBRARIES $\{SWIG_LIBRARIES} $\{TPL_LIBRARIES} )\n" )
FILE( APPEND "${FIND_TPLS_CMAKE}" "    SET( TPL_FOUND_SWIG $\{SWIG_FOUND} )\n" )
FILE( APPEND "${FIND_TPLS_CMAKE}" "ENDIF()\n" )
FILE( APPEND "${FIND_TPLS_CMAKE}" "\n" )

# This will configure and build boost
# User can configure the source path by specifying BOOST_SRC_DIR,
#    the download path by specifying BOOST_URL, or the installed 
#    location by specifying BOOST_INSTALL_DIR


# Intialize download/src/install vars
SET( BOOST_BUILD_DIR "${CMAKE_BINARY_DIR}/BOOST-prefix/src/BOOST-build" )
IF ( BOOST_URL ) 
    MESSAGE("   BOOST_URL = ${BOOST_URL}")
    SET( BOOST_CMAKE_URL            "${BOOST_URL}"       )
    SET( BOOST_CMAKE_DOWNLOAD_DIR   "${BOOST_BUILD_DIR}" )
    SET( BOOST_CMAKE_SOURCE_DIR     "${BOOST_BUILD_DIR}" )
    SET( BOOST_CMAKE_INSTALL_DIR "${CMAKE_INSTALL_PREFIX}/boost" )
    SET( CMAKE_BUILD_BOOST TRUE )
ELSEIF ( BOOST_SRC_DIR )
    VERIFY_PATH("${BOOST_SRC_DIR}")
    MESSAGE("   BOOST_SRC_DIR = ${BOOST_SRC_DIR}")
    SET( BOOST_CMAKE_URL            "${BOOST_SRC_DIR}"   )
    SET( BOOST_CMAKE_DOWNLOAD_DIR   "${BOOST_BUILD_DIR}" )
    SET( BOOST_CMAKE_SOURCE_DIR     "${BOOST_BUILD_DIR}" )
    SET( BOOST_CMAKE_INSTALL_DIR "${CMAKE_INSTALL_PREFIX}/boost" )
    SET( CMAKE_BUILD_BOOST TRUE )
ELSEIF ( BOOST_INSTALL_DIR ) 
    SET( BOOST_CMAKE_INSTALL_DIR "${BOOST_INSTALL_DIR}" )
    SET( CMAKE_BUILD_BOOST FALSE )
ELSE()
    MESSAGE(FATAL_ERROR "Please specify BOOST_SRC_DIR, BOOST_URL, or BOOST_INSTALL_DIR")
ENDIF()
SET( BOOST_INSTALL_DIR "${BOOST_CMAKE_INSTALL_DIR}" )
MESSAGE( "   BOOST_INSTALL_DIR = ${BOOST_INSTALL_DIR}" )


# Configure optional/required TPLs
CONFIGURE_DEPENDENCIES( BOOST OPTIONAL ZLIB )


# Add the search/include of boost to FindTPLs.cmake
IF ( BOOST_ONLY_COPY_HEADERS )
    SET( BOOST_COMPONENTS )
ELSE()
    SET( BOOST_COMPONENTS thread date_time system )
ENDIF()


# Configure boost
IF ( CMAKE_BUILD_BOOST ) 
    SET( BUILD_OPTIONS )
    SET( BOOST_CONFIGURE_OPTIONS )
    IF ( ENABLE_SHARED AND ENABLE_STATIC )
        MESSAGE(FATAL_ERROR "Compiling boost with both static and shared libraries is not yet supported")
    ELSEIF ( ENABLE_SHARED )
        SET( BOOST_CONFIGURE_OPTIONS ${BOOST_CONFIGURE_OPTIONS} link=shared )
    ELSEIF ( ENABLE_STATIC )
        SET( BOOST_CONFIGURE_OPTIONS ${BOOST_CONFIGURE_OPTIONS} link=static )
    ENDIF()

    SET( BOOST_CONFIGURE_OPTIONS ${BOOST_CONFIGURE_OPTIONS} --with-libraries= )

    IF( USING_GCC )
        SET( TOOLSET gcc )
    ELSEIF( MSVC OR MSVC_IDE OR MSVC60 OR MSVC70 OR MSVC71 OR MSVC80 OR CMAKE_COMPILER_2005 OR MSVC90 OR MSVC10 )
        SET( TOOLSET msvc )
    ELSEIF( (${CMAKE_C_COMPILER_ID} MATCHES "Intel") OR (${CMAKE_CXX_COMPILER_ID} MATCHES "Intel") ) 
        SET( TOOLSET intel-linux )
    ELSEIF( (${CMAKE_C_COMPILER_ID} MATCHES "CLANG") OR (${CMAKE_C_COMPILER_ID} MATCHES "Clang") )
        SET( TOOLSET clang )        
    ELSE()
        MESSAGE(FATAL_ERROR "BOOST toolset not set")
    ENDIF()

    SET( BUILD_OPTIONS ${BUILD_OPTIONS} -sNO_BZIP2=1 --without-mpi --without-python ) 
ENDIF()


# Build boost
IF ( CMAKE_BUILD_BOOST ) 
    IF ( BOOST_ONLY_COPY_HEADERS )
        ADD_TPL(
            BOOST
            URL                 "${BOOST_CMAKE_URL}"
            DOWNLOAD_DIR        "${BOOST_CMAKE_DOWNLOAD_DIR}"
            SOURCE_DIR          "${BOOST_CMAKE_SOURCE_DIR}"
            UPDATE_COMMAND      ""
            CONFIGURE_COMMAND   ls  "${BOOST_CMAKE_SOURCE_DIR}"
            BUILD_COMMAND       ls "${BOOST_CMAKE_SOURCE_DIR}"
            BUILD_IN_SOURCE     0
            INSTALL_COMMAND     ${CMAKE_COMMAND} -E copy_directory "${BOOST_CMAKE_SOURCE_DIR}/boost"
                                "${BOOST_CMAKE_INSTALL_DIR}/include/boost"
            WORKING_DIRECTORY   "${BOOST_CMAKE_SOURCE_DIR}"
            LOG_DOWNLOAD 1   LOG_UPDATE 1   LOG_CONFIGURE 1   LOG_BUILD 1   LOG_TEST 1   LOG_INSTALL 1
        )
    ELSE()
        ADD_TPL(
            BOOST
            URL                 "${BOOST_CMAKE_URL}"
            DOWNLOAD_DIR        "${BOOST_CMAKE_DOWNLOAD_DIR}"
            SOURCE_DIR          "${BOOST_CMAKE_SOURCE_DIR}"
            UPDATE_COMMAND      ""
            CONFIGURE_COMMAND   ./bootstrap.sh --with-toolset=${TOOLSET} ${BOOST_CONFIGURE_OPTIONS} --prefix=${BOOST_CMAKE_INSTALL_DIR}
            BUILD_COMMAND       ./b2 install ${BUILD_OPTIONS} -j 8
            BUILD_IN_SOURCE     1
            INSTALL_COMMAND     ${CMAKE_COMMAND} -E echo "Install complete"
            LOG_DOWNLOAD 1   LOG_UPDATE 1   LOG_CONFIGURE 1   LOG_BUILD 1   LOG_TEST 1   LOG_INSTALL 1
        )
    ENDIF()
ELSE()
    ADD_TPL_EMPTY( BOOST )
ENDIF()

FILE( APPEND "${FIND_TPLS_CMAKE}" "\n# Find Boost\n" )
FILE( APPEND "${FIND_TPLS_CMAKE}" "IF ( TPLs_FIND_BOOST AND NOT TPLs_BOOST_FOUND )\n" )
FILE( APPEND "${FIND_TPLS_CMAKE}" "    SET( Boost_NO_SYSTEM_PATHS TRUE )\n" )
FILE( APPEND "${FIND_TPLS_CMAKE}" "    SET( Boost_ROOT \"${BOOST_INSTALL_DIR}\" )\n" )
FILE( APPEND "${FIND_TPLS_CMAKE}" "    SET( Boost_INCLUDEDIR \"${BOOST_INSTALL_DIR}/include\" )\n" )

IF ( BOOST_ONLY_COPY_HEADERS )
    FILE( APPEND "${FIND_TPLS_CMAKE}" "    SET( BOOST_DEBUG 1 )\n" )
    FILE( APPEND "${FIND_TPLS_CMAKE}" "    FIND_PACKAGE( Boost )\n" )
    FILE( APPEND "${FIND_TPLS_CMAKE}" "    SET( BOOST_INCLUDE_DIR $\{Boost_INCLUDE_DIRS} )\n" )
    FILE( APPEND "${FIND_TPLS_CMAKE}" "    ADD_TPL_LIBRARY( BOOST Boost::headers )\n" )
ELSE()
    FILE( APPEND "${FIND_TPLS_CMAKE}" "    SET( Boost_LIBRARYDIR \"${BOOST_INSTALL_DIR}/lib\" )\n" ) 
    FILE( APPEND "${FIND_TPLS_CMAKE}" "    SET( Boost_LIBRARY_DIR_DEBUG \"${BOOST_INSTALL_DIR}/lib\" )\n" )
    FILE( APPEND "${FIND_TPLS_CMAKE}" "    SET( Boost_LIBRARY_DIR_RELEASE \"${BOOST_INSTALL_DIR}/lib\" )\n" )
    FILE( APPEND "${FIND_TPLS_CMAKE}" "    FIND_PACKAGE( Boost REQUIRED COMPONENTS ${BOOST_COMPONENTS} QUIET )\n" )
    FILE( APPEND "${FIND_TPLS_CMAKE}" "    SET( BOOST_INCLUDE_DIR $\{Boost_INCLUDE_DIRS} )\n" )
    FILE( APPEND "${FIND_TPLS_CMAKE}" "    ADD_TPL_LIBRARY( BOOST Boost::thread Boost::date_time Boost::system  )\n" )
ENDIF()

FILE( APPEND "${FIND_TPLS_CMAKE}" "ENDIF()\n" )

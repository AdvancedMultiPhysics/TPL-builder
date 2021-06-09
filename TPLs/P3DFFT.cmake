# This will configure and build p3dfft
# User can configure the source path by specifying P3DFFT_SRC_DIR,
#    the download path by specifying P3DFFT_URL, or the installed 
#    location by specifying P3DFFT_INSTALL_DIR


# Intialize download/src/install vars
SET( P3DFFT_BUILD_DIR "${CMAKE_BINARY_DIR}/P3DFFT-prefix/src/P3DFFT-build" )
IF ( P3DFFT_URL ) 
    MESSAGE("   P3DFFT_URL = ${P3DFFT_URL}")
    SET( P3DFFT_CMAKE_URL            "${P3DFFT_URL}"       )
    SET( P3DFFT_CMAKE_DOWNLOAD_DIR   "${P3DFFT_BUILD_DIR}" )
    SET( P3DFFT_CMAKE_SOURCE_DIR     "${P3DFFT_BUILD_DIR}" )
    SET( P3DFFT_CMAKE_INSTALL_DIR "${CMAKE_INSTALL_PREFIX}/p3dfft" )
    SET( CMAKE_BUILD_P3DFFT TRUE )
ELSEIF ( P3DFFT_SRC_DIR )
    VERIFY_PATH("${P3DFFT_SRC_DIR}")
    MESSAGE("   P3DFFT_SRC_DIR = ${P3DFFT_SRC_DIR}" )
    SET( P3DFFT_CMAKE_URL            ""                  )
    SET( P3DFFT_CMAKE_DOWNLOAD_DIR   ""                  )
    SET( P3DFFT_CMAKE_SOURCE_DIR     "${P3DFFT_SRC_DIR}" )
    SET( P3DFFT_CMAKE_INSTALL_DIR "${CMAKE_INSTALL_PREFIX}/p3dfft" )
    SET( CMAKE_BUILD_P3DFFT TRUE )
ELSEIF ( P3DFFT_INSTALL_DIR ) 
    SET( P3DFFT_CMAKE_INSTALL_DIR "${P3DFFT_INSTALL_DIR}" )
    SET( CMAKE_BUILD_P3DFFT FALSE )
ELSE()
    MESSAGE(FATAL_ERROR "Please specify P3DFFT_SRC_DIR, P3DFFT_URL, or P3DFFT_INSTALL_DIR")
ENDIF()
IF ( ${CMAKE_BUILD_TYPE} STREQUAL "Debug" )
    SET( P3DFFT_METHOD dbg )
ELSEIF ( ${CMAKE_BUILD_TYPE} STREQUAL "Release" )
    SET( P3DFFT_METHOD opt )
ELSE()
    MESSAGE ( FATAL_ERROR "Unknown CMAKE_BUILD_TYPE=${CMAKE_BUILD_TYPE}" )
ENDIF()
SET( P3DFFT_HOSTTYPE x86_64-unknown-linux-gnu )
SET( P3DFFT_INSTALL_DIR "${P3DFFT_CMAKE_INSTALL_DIR}" )
MESSAGE( "   P3DFFT_INSTALL_DIR = ${P3DFFT_INSTALL_DIR}" )


# Configure p3dfft
IF ( CMAKE_BUILD_P3DFFT )
    SET( CONFIGURE_OPTIONS )
    SET( P3DFFT_LD_FLAGS )
    SET( P3DFFT_LIBS )
    SET( CONFIGURE_OPTIONS ${CONFIGURE_OPTIONS} --prefix=${CMAKE_INSTALL_PREFIX}/p3dfft )
    SET( CONFIGURE_OPTIONS ${CONFIGURE_OPTIONS} --enable-fftw )
    SET( CONFIGURE_OPTIONS ${CONFIGURE_OPTIONS} --with-fftw=${CMAKE_INSTALL_PREFIX}/fftw )
    IF( CMAKE_COMPILER_IS_GNUCC OR CMAKE_COMPILER_IS_GNUCXX )
        SET( CONFIGURE_OPTIONS ${CONFIGURE_OPTIONS} --enable-gcc )
        SET( P3DFFT_LIBS "-lmpifort -lgfortran -lm" )
    ELSEIF( (${CMAKE_C_COMPILER_ID} MATCHES "Intel") OR (${CMAKE_CXX_COMPILER_ID} MATCHES "Intel") OR
            (${CMAKE_Fortran_COMPILER_ID} MATCHES "Intel") ) 
        SET( CONFIGURE_OPTIONS ${CONFIGURE_OPTIONS} --enable-intel )
    ELSEIF( (${CMAKE_C_COMPILER_ID} MATCHES "PGI") OR (${CMAKE_CXX_COMPILER_ID} MATCHES "PGI") )
        SET( CONFIGURE_OPTIONS ${CONFIGURE_OPTIONS} --enable-pgi )
    ELSE()
        MESSAGE(FATAL_ERROR "Unknown compiler")
    ENDIF()
ENDIF()


# Build p3dfft
IF ( CMAKE_BUILD_P3DFFT )
    EXTERNALPROJECT_ADD( 
        P3DFFT
        URL                 "${P3DFFT_CMAKE_URL}"
        DOWNLOAD_DIR        "${P3DFFT_CMAKE_DOWNLOAD_DIR}"
        SOURCE_DIR          "${P3DFFT_CMAKE_SOURCE_DIR}"
        UPDATE_COMMAND      ""
        CONFIGURE_COMMAND   ${P3DFFT_CMAKE_SOURCE_DIR}/configure ${CONFIGURE_OPTIONS} CXXFLAGS=${P3DFFT_CXX_FLAGS} LDFLAGS=${P3DFFT_LD_FLAGS} LIBS=${P3DFFT_LIBS}
        BUILD_COMMAND       make VERBOSE=1
        BUILD_IN_SOURCE     0
        INSTALL_COMMAND     make install
        DEPENDS             FFTW
        LOG_DOWNLOAD 1   LOG_UPDATE 1   LOG_CONFIGURE 1   LOG_BUILD 1   LOG_TEST 1   LOG_INSTALL 1
    )
    ADD_TPL(
        ${TPL}
        fix-install
        COMMAND             ${CMAKE_COMMAND} -E copy ${P3DFFT_CMAKE_SOURCE_DIR}/include/config.h ${P3DFFT_INSTALL_DIR}/include/
        COMMAND             ${CMAKE_COMMAND} -E copy ${P3DFFT_CMAKE_SOURCE_DIR}/include/p3dfft.h ${P3DFFT_INSTALL_DIR}/include/
        COMMAND             ${CMAKE_COMMAND} -E copy ${P3DFFT_CMAKE_SOURCE_DIR}/include/p3dfft.mod ${P3DFFT_INSTALL_DIR}/include/
        COMMENT             ""
        DEPENDEES           install
        ALWAYS              0
        LOG                 0
    )
ELSE()
    ADD_TPL_EMPTY( P3DFFT )
ENDIF()


# Add the appropriate fields to FindTPLs.cmake



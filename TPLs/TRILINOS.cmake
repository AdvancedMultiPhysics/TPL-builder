# This will configure and build trilinos
# User can configure the source path by speficfying TRILINOS_SRC_DIR,
#    the download path by specifying TRILINOS_URL, or the installed 
#    location by specifying TRILINOS_INSTALL_DIR


# Intialize download/src/install vars
SET( TRILINOS_BUILD_DIR "${CMAKE_BINARY_DIR}/TRILINOS-prefix/src/TRILINOS-build" )
IF ( TRILINOS_URL ) 
    MESSAGE_TPL("   TRILINOS_URL = ${TRILINOS_URL}")
    SET( TRILINOS_SRC_DIR "${CMAKE_BINARY_DIR}/TRILINOS-prefix/src/TRILINOS-src" )
    SET( TRILINOS_CMAKE_URL            "${TRILINOS_URL}"     )
    SET( TRILINOS_CMAKE_DOWNLOAD_DIR   "${TRILINOS_SRC_DIR}" )
    SET( TRILINOS_CMAKE_SOURCE_DIR     "${TRILINOS_SRC_DIR}" )
    SET( TRILINOS_CMAKE_INSTALL_DIR "${CMAKE_INSTALL_PREFIX}/trilinos" )
    SET( CMAKE_BUILD_TRILINOS TRUE )
ELSEIF ( TRILINOS_SRC_DIR )
    VERIFY_PATH("${TRILINOS_SRC_DIR}")
    MESSAGE_TPL("   TRILINOS_SRC_DIR = ${TRILINOS_SRC_DIR}")
    SET( TRILINOS_CMAKE_URL            ""                  )
    SET( TRILINOS_CMAKE_DOWNLOAD_DIR   ""                  )
    SET( TRILINOS_CMAKE_SOURCE_DIR     "${TRILINOS_SRC_DIR}" )
    SET( TRILINOS_CMAKE_INSTALL_DIR "${CMAKE_INSTALL_PREFIX}/trilinos" )
    SET( CMAKE_BUILD_TRILINOS TRUE )
ELSEIF ( TRILINOS_INSTALL_DIR ) 
    SET( TRILINOS_CMAKE_INSTALL_DIR "${TRILINOS_INSTALL_DIR}" )
    SET( CMAKE_BUILD_TRILINOS FALSE )
ELSE()
    MESSAGE(FATAL_ERROR "Please specify TRILINOS_SRC_DIR, TRILINOS_URL, or TRILINOS_INSTALL_DIR")
ENDIF()
SET( TRILINOS_INSTALL_DIR "${TRILINOS_CMAKE_INSTALL_DIR}" )
MESSAGE_TPL( "   TRILINOS_INSTALL_DIR = ${TRILINOS_INSTALL_DIR}" )
FILE( APPEND "${CMAKE_INSTALL_PREFIX}/TPLs.cmake" "SET(TRILINOS_INSTALL_DIR \"${TRILINOS_INSTALL_DIR}\")\n" )


# Configure trilinos
IF ( CMAKE_BUILD_TRILINOS )
    SET( TRILINOS_DEPENDS LAPACK )
    SET( CONFIGURE_OPTIONS "${CMAKE_ARGS};-DCMAKE_INSTALL_PREFIX=${CMAKE_INSTALL_PREFIX}/trilinos" )
    SET( CONFIGURE_OPTIONS "${CONFIGURE_OPTIONS};-DTPL_ENABLE_MPI:BOOL=ON" )
    SET( CONFIGURE_OPTIONS "${CONFIGURE_OPTIONS};-DTPL_BLAS_LIBRARIES:STRING=${BLAS_LIBS}" )
    SET( CONFIGURE_OPTIONS "${CONFIGURE_OPTIONS};-DTPL_LAPACK_LIBRARIES:STRING=${LAPACK_LIBS}" )
    IF ( BOOST_INSTALL_DIR )
        SET( CONFIGURE_OPTIONS "${CONFIGURE_OPTIONS};-DBoost_INCLUDE_DIRS=${BOOST_INSTALL_DIR}/include" )
        SET( TRILINOS_DEPENDS ${TRILINOS_DEPENDS} BOOST )
    ENDIF()
    SET( CONFIGURE_OPTIONS "${CONFIGURE_OPTIONS};-DTPL_ENABLE_Matio=OFF" )
    IF ( ${CXX_STD} STREQUAL 98 )
        SET( CONFIGURE_OPTIONS "${CONFIGURE_OPTIONS};-DTrilinos_ENABLE_CXX11=OFF" )
    ELSEIF ( ( ${CXX_STD} STREQUAL 11 ) OR ( ${CXX_STD} STREQUAL 14 ) )
        SET( CONFIGURE_OPTIONS "${CONFIGURE_OPTIONS};-DTrilinos_ENABLE_CXX11=ON" )
    ENDIF()
    IF ( TRILINOS_PACKAGES )
        STRING( REPLACE ";" "," TRILINOS_PACKAGES "${TRILINOS_PACKAGES}" )
        FOREACH( package ${TRILINOS_PACKAGES} )
            SET( CONFIGURE_OPTIONS "${CONFIGURE_OPTIONS};-DTrilinos_ENABLE_${package}:BOOL=ON" )
        ENDFOREACH()
    ELSE()
        SET( CONFIGURE_OPTIONS "${CONFIGURE_OPTIONS};-DTrilinos_ENABLE_ALL_PACKAGES:BOOL=ON" )
    ENDIF()
    STRING( REPLACE ";" "," TRILINOS_EXTRA_PACKAGES "${TRILINOS_EXTRA_PACKAGES}" )
    FOREACH( package ${TRILINOS_EXTRA_PACKAGES} )
        SET( CONFIGURE_OPTIONS "${CONFIGURE_OPTIONS};-DTrilinos_ENABLE_${package}:BOOL=ON" )
    ENDFOREACH()
    STRING( REPLACE ";" "," TRILINOS_EXTRA_REPOSITORIES "${TRILINOS_EXTRA_REPOSITORIES}" )
    FOREACH( repo ${TRILINOS_EXTRA_REPOSITORIES} )
        SET( CONFIGURE_OPTIONS "${CONFIGURE_OPTIONS};-DTrilinos_EXTRA_REPOSITORIES=${repo}" )
    ENDFOREACH()
    STRING( REPLACE ";" "," TRILINOS_EXTRA_FLAGS "${TRILINOS_EXTRA_FLAGS}" )
    FOREACH( flags ${TRILINOS_EXTRA_FLAGS} )
        SET( CONFIGURE_OPTIONS "${CONFIGURE_OPTIONS};${flags}" )
    ENDFOREACH()
    SET( PARALLEL_BUILD_OPTIONS )
    IF ( PROCS_INSTALL )
        IF ( ${PROCS_INSTALL} GREATER "1" )
            SET( PARALLEL_BUILD_OPTIONS -j ${PROCS_INSTALL} )
        ENDIF()
    ENDIF()
ENDIF()


# Configure trilinos
IF ( CMAKE_BUILD_TRILINOS )
    EXTERNALPROJECT_ADD(
        TRILINOS
        URL                 "${TRILINOS_CMAKE_URL}"
        DOWNLOAD_DIR        "${TRILINOS_CMAKE_DOWNLOAD_DIR}"
        SOURCE_DIR          "${TRILINOS_CMAKE_SOURCE_DIR}"
        UPDATE_COMMAND      ""
        BUILD_IN_SOURCE     0
        INSTALL_DIR         ${CMAKE_INSTALL_PREFIX}/trilinos
        CMAKE_ARGS          "${CONFIGURE_OPTIONS}"
        BUILD_COMMAND       ${CMAKE_MAKE_PROGRAM} install ${PARALLEL_BUILD_OPTIONS} VERBOSE=1
        DEPENDS             ${TRILINOS_DEPENDS}
        LOG_DOWNLOAD 1   LOG_UPDATE 1   LOG_CONFIGURE 1   LOG_BUILD 1   LOG_TEST 1   LOG_INSTALL 1
    )
    ADD_TPL_SAVE_LOGS( TRILINOS )
    ADD_TPL_CLEAN( TRILINOS )
ELSE()
    ADD_TPL_EMPTY( TRILINOS )
ENDIF()


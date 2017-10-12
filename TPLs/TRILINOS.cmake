# This will configure and build trilinos
# User can configure the source path by specifying TRILINOS_SRC_DIR,
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


# Helper function to write variable to config file
SET( TRILINOS_CMAKE_CONFIGURE "${TRILINOS_BUILD_DIR}/TrilinosConfigure.cmake" )
FUNCTION( WRITE_TRILINOS_CONFIG VAR )
    FILE( APPEND "${TRILINOS_CMAKE_CONFIGURE}" "SET( ${VAR} ${ARGN} )\n" )
ENDFUNCTION()


# Configure trilinos
IF ( CMAKE_BUILD_TRILINOS )
    SET( TRILINOS_CMAKE "${TRILINOS_BUILD_DIR}/TrilinosConfigure.cmake" )
    FILE( WRITE  "${TRILINOS_CMAKE}" "# Include file to configure Trilinos\n" )
    WRITE_TRILINOS_CONFIG( CMAKE_INSTALL_PREFIX ${CMAKE_INSTALL_PREFIX}/trilinos )
    WRITE_TRILINOS_CONFIG( CMAKE_BUILD_TYPE ${CMAKE_BUILD_TYPE} )
    IF ( ${CXX_STD} STREQUAL 98 )
        WRITE_TRILINOS_CONFIG( Trilinos_ENABLE_CXX11 OFF )
    ELSEIF ( ( ${CXX_STD} STREQUAL 11 ) OR ( ${CXX_STD} STREQUAL 14 ) )
        WRITE_TRILINOS_CONFIG( Trilinos_ENABLE_CXX11 ON )
    ENDIF()
    # Configure Blas/Lapack
    SET( TRILINOS_DEPENDS LAPACK )
    SET( BLAS_LIBS2 ${BLAS_LIBS} )
    SET( LAPACK_LIBS2 ${LAPACK_LIBS} )
    IF ( USING_GFORTRAN )
        SET( BLAS_LIBS2 ${BLAS_LIBS2} -lgfortran )
        SET( LAPACK_LIBS2 ${LAPACK_LIBS2} -lgfortran )
    ENDIF()
    WRITE_TRILINOS_CONFIG( TPL_BLAS_LIBRARIES ${BLAS_LIBS2} )
    WRITE_TRILINOS_CONFIG( TPL_LAPACK_LIBRARIES ${LAPACK_LIBS2} )
    # Configure MPI
    IF ( USE_MPI )
        WRITE_TRILINOS_CONFIG( TPL_ENABLE_MPI ON )
    ELSE()
        WRITE_TRILINOS_CONFIG( TPL_ENABLE_MPI OFF )
    ENDIF()
    # Configure Boost
    IF ( BOOST_INSTALL_DIR )
        SET( TRILINOS_DEPENDS ${TRILINOS_DEPENDS} BOOST )
        WRITE_TRILINOS_CONFIG( Boost_INCLUDE_DIRS ${BOOST_INSTALL_DIR}/include )
    ELSE()
        WRITE_TRILINOS_CONFIG( TPL_ENABLE_Boost OFF )
    ENDIF()
    # Configure Netcdf
    IF ( NETCDF_INSTALL_DIR AND NOT Trilinos_DISABLE_Netcdf )
        SET( TRILINOS_DEPENDS ${TRILINOS_DEPENDS} NETCDF )
        WRITE_TRILINOS_CONFIG( TPL_ENABLE_Netcdf ON )
        WRITE_TRILINOS_CONFIG( Netcdf_LIBRARY_DIRS ${NETCDF_INSTALL_DIR}/lib )
        WRITE_TRILINOS_CONFIG( Netcdf_INCLUDE_DIRS ${NETCDF_INSTALL_DIR}/include )
        IF ( ENABLE_STATIC )
            WRITE_TRILINOS_CONFIG( TPL_Netcdf_LIBRARIES ${NETCDF_INSTALL_DIR}/lib/libnetcdf.a )
        ELSE()
            WRITE_TRILINOS_CONFIG( TPL_Netcdf_LIBRARIES ${NETCDF_INSTALL_DIR}/lib/libnetcdf.so )
        ENDIF()
    ELSE()
        WRITE_TRILINOS_CONFIG( TPL_ENABLE_Netcdf OFF )
    ENDIF()
    # Configure HDF5
    IF ( HDF5_INSTALL_DIR AND NOT Trilinos_DISABLE_HDF5 )
        SET( TRILINOS_DEPENDS ${TRILINOS_DEPENDS} HDF5 )
        WRITE_TRILINOS_CONFIG( TPL_ENABLE_HDF5 ON )
        WRITE_TRILINOS_CONFIG( HDF5_LIBRARY_DIRS ${HDF5_INSTALL_DIR}/lib )
        WRITE_TRILINOS_CONFIG( HDF5_INCLUDE_DIRS ${HDF5_INSTALL_DIR}/include )
    ELSE()
        WRITE_TRILINOS_CONFIG( TPL_ENABLE_HDF5 OFF )
    ENDIF()
    WRITE_TRILINOS_CONFIG( TPL_ENABLE_Matio OFF )
    IF ( TRILINOS_PACKAGES )
        STRING( REPLACE "," ";" TRILINOS_PACKAGES "${TRILINOS_PACKAGES}" )
        FOREACH( package ${TRILINOS_PACKAGES} )
            WRITE_TRILINOS_CONFIG( Trilinos_ENABLE_${package} ON )
        ENDFOREACH()
    ELSE()
        WRITE_TRILINOS_CONFIG( Trilinos_ENABLE_ALL_PACKAGES ON )
        WRITE_TRILINOS_CONFIG( Trilinos_ENABLE_STK OFF )
        WRITE_TRILINOS_CONFIG( Trilinos_ENABLE_Sundance OFF )
    ENDIF()
    IF ( Trilinos_EXTRA_LINK_FLAGS )
        WRITE_TRILINOS_CONFIG( Trilinos_EXTRA_LINK_FLAGS ${Trilinos_EXTRA_LINK_FLAGS} )
    ENDIF()
    STRING( REPLACE "," ";" TRILINOS_EXTRA_PACKAGES "${TRILINOS_EXTRA_PACKAGES}" )
    FOREACH( package ${TRILINOS_EXTRA_PACKAGES} )
        WRITE_TRILINOS_CONFIG( Trilinos_ENABLE_${package} ON )
    ENDFOREACH()
    STRING( REPLACE "," ";" TRILINOS_EXTRA_REPOSITORIES "${TRILINOS_EXTRA_REPOSITORIES}" )
    FOREACH( repo ${TRILINOS_EXTRA_REPOSITORIES} )
        WRITE_TRILINOS_CONFIG( Trilinos_EXTRA_REPOSITORIES ${repo} )
    ENDFOREACH()
    STRING( REPLACE "," ";" TRILINOS_EXTRA_FLAGS "${TRILINOS_EXTRA_FLAGS}" )
    FOREACH( flags ${TRILINOS_EXTRA_FLAGS} )
        SET( CONFIGURE_OPTIONS ${CONFIGURE_OPTIONS} ${flags} )
    ENDFOREACH()
    WRITE_TRILINOS_CONFIG( Trilinos_DUMP_LINK_LIBS ON )
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
        CMAKE_ARGS          ${CMAKE_ARGS} -DCMAKE_INSTALL_PREFIX=${CMAKE_INSTALL_PREFIX}/trilinos -DTrilinos_CONFIGURE_OPTIONS_FILE=${TRILINOS_CMAKE_CONFIGURE}
        BUILD_COMMAND       ${CMAKE_MAKE_PROGRAM} install ${PARALLEL_BUILD_OPTIONS} VERBOSE=1
        DEPENDS             ${TRILINOS_DEPENDS}
        LOG_DOWNLOAD 1   LOG_UPDATE 1   LOG_CONFIGURE 1   LOG_BUILD 1   LOG_TEST 1   LOG_INSTALL 1
    )
    ADD_TPL_SAVE_LOGS( TRILINOS )
    ADD_TPL_CLEAN( TRILINOS )
ELSE()
    ADD_TPL_EMPTY( TRILINOS )
ENDIF()


# Add the appropriate fields to FindTPLs.cmake
FILE( APPEND "${FIND_TPLS_CMAKE}" "\n# Find TRILINOS\n" )
FILE( APPEND "${FIND_TPLS_CMAKE}" "IF ( TPLs_FIND_TRILINOS AND NOT TPL_FOUND_TRILINOS )\n" )
FILE( APPEND "${FIND_TPLS_CMAKE}" "    FIND_PACKAGE(Trilinos PATHS ${TRILINOS_INSTALL_DIR}/lib/cmake/Trilinos)\n" )
FILE( APPEND "${FIND_TPLS_CMAKE}" "    IF ( NOT Trilinos_FOUND )\n" )
FILE( APPEND "${FIND_TPLS_CMAKE}" "        MESSAGE(FATAL_ERROR \"Trilinos not found\")\n" )
FILE( APPEND "${FIND_TPLS_CMAKE}" "    ENDIF()\n" )
FILE( APPEND "${FIND_TPLS_CMAKE}" "    LIST(REMOVE_DUPLICATES Trilinos_LIBRARIES)\n" )
FILE( APPEND "${FIND_TPLS_CMAKE}" "    IF ( NOT TPLs_FIND_QUIETLY )\n" )
FILE( APPEND "${FIND_TPLS_CMAKE}" "        MESSAGE(\"Found Trilinos:\")\n" )
FILE( APPEND "${FIND_TPLS_CMAKE}" "        MESSAGE(\"   Trilinos_DIR = $\{Trilinos_DIR}\")\n" )
FILE( APPEND "${FIND_TPLS_CMAKE}" "        MESSAGE(\"   Trilinos_VERSION = $\{Trilinos_VERSION}\"\)\n" )
FILE( APPEND "${FIND_TPLS_CMAKE}" "        MESSAGE(\"   Trilinos_PACKAGE_LIST = $\{Trilinos_PACKAGE_LIST}\")\n" )
FILE( APPEND "${FIND_TPLS_CMAKE}" "        MESSAGE(\"   Trilinos_LIBRARIES = $\{Trilinos_LIBRARIES}\")\n" )
FILE( APPEND "${FIND_TPLS_CMAKE}" "        MESSAGE(\"   Trilinos_INCLUDE_DIRS = $\{Trilinos_INCLUDE_DIRS}\")\n" )
FILE( APPEND "${FIND_TPLS_CMAKE}" "        MESSAGE(\"   Trilinos_TPL_LIST = $\{Trilinos_TPL_LIST}\")\n" )
FILE( APPEND "${FIND_TPLS_CMAKE}" "    ENDIF()\n" )
FILE( APPEND "${FIND_TPLS_CMAKE}" "    FOREACH( tmp $\{Trilinos_PACKAGE_LIST} )\n" )
FILE( APPEND "${FIND_TPLS_CMAKE}" "        STRING(TOUPPER $\{tmp} tmp)\n")
FILE( APPEND "${FIND_TPLS_CMAKE}" "        SET( USE_TRILINOS_$\{tmp} 1 )\n" )
FILE( APPEND "${FIND_TPLS_CMAKE}" "        ADD_DEFINITIONS( -D USE_TRILINOS_$\{tmp} )\n" )
FILE( APPEND "${FIND_TPLS_CMAKE}" "    ENDFOREACH()\n" )
FILE( APPEND "${FIND_TPLS_CMAKE}" "    LINK_DIRECTORIES( ${Trilinos_LIBRARY_DIRS} )\n" )
FILE( APPEND "${FIND_TPLS_CMAKE}" "    SET( TPL_INCLUDE_DIRS $\{TPL_INCLUDE_DIRS} $\{Trilinos_INCLUDE_DIRS} )\n" )
FILE( APPEND "${FIND_TPLS_CMAKE}" "    SET( TPL_LIBRARIES $\{Trilinos_LIBRARIES} $\{TPL_LIBRARIES} )\n" )
FILE( APPEND "${FIND_TPLS_CMAKE}" "    SET( TRILINOS_FOUND TRUE )\n" )
FILE( APPEND "${FIND_TPLS_CMAKE}" "    SET( TPL_FOUND_TRILINOS TRUE )\n" )
FILE( APPEND "${FIND_TPLS_CMAKE}" "ENDIF()\n" )
FILE( APPEND "${FIND_TPLS_CMAKE}" "\n" )


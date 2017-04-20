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


# Configure trilinos
IF ( CMAKE_BUILD_TRILINOS )
    SET( TRILINOS_DEPENDS LAPACK )
    SET( CONFIGURE_OPTIONS "${CMAKE_ARGS};-DCMAKE_INSTALL_PREFIX=${CMAKE_INSTALL_PREFIX}/trilinos" )
    SET( CONFIGURE_OPTIONS "${CONFIGURE_OPTIONS};-DCMAKE_BUILD_TYPE=${CMAKE_BUILD_TYPE}" )
    SET( CONFIGURE_OPTIONS "${CONFIGURE_OPTIONS};-DTPL_BLAS_LIBRARIES:STRING=${BLAS_LIBS}" )
    SET( CONFIGURE_OPTIONS "${CONFIGURE_OPTIONS};-DTPL_LAPACK_LIBRARIES:STRING=${LAPACK_LIBS}" )
    IF ( USE_MPI )
        SET( CONFIGURE_OPTIONS "${CONFIGURE_OPTIONS};-DTPL_ENABLE_MPI:BOOL=ON" )
    ELSE()
        SET( CONFIGURE_OPTIONS "${CONFIGURE_OPTIONS};-DTPL_ENABLE_MPI:BOOL=OFF" )
    ENDIF()
    IF ( BOOST_INSTALL_DIR )
        SET( CONFIGURE_OPTIONS "${CONFIGURE_OPTIONS};-DBoost_INCLUDE_DIRS=${BOOST_INSTALL_DIR}/include" )
        SET( TRILINOS_DEPENDS ${TRILINOS_DEPENDS} BOOST )
    ENDIF()
    IF ( NETCDF_INSTALL_DIR )
        MESSAGE( STATUS "Disabling Netcfd in Trilinos due to link order error" )
        SET( CONFIGURE_OPTIONS "${CONFIGURE_OPTIONS};-DTPL_ENABLE_Netcdf:BOOL=OFF" )
        #SET( CONFIGURE_OPTIONS "${CONFIGURE_OPTIONS};-DTPL_ENABLE_Netcdf=ON" )
        #SET( CONFIGURE_OPTIONS "${CONFIGURE_OPTIONS};-DNetcdf_LIBRARY_DIRS=${NETCDF_INSTALL_DIR}/lib" )
        #SET( CONFIGURE_OPTIONS "${CONFIGURE_OPTIONS};-DNetcdf_INCLUDE_DIRS=${NETCDF_INSTALL_DIR}/include" )
        #SET( CONFIGURE_OPTIONS "${CONFIGURE_OPTIONS};-DNetcdf_LIBRARY_NAMES='netcdf;hdf5_hl;hdf5;z'" )
        #SET( TRILINOS_DEPENDS ${TRILINOS_DEPENDS} NETCDF )
    ELSE()
        SET( CONFIGURE_OPTIONS "${CONFIGURE_OPTIONS};-DTPL_ENABLE_Netcdf:BOOL=OFF" )
    ENDIF()
    IF ( HDF5_INSTALL_DIR )
        MESSAGE( STATUS "Disabling HDF5 in Trilinos due to link order error" )
        SET( CONFIGURE_OPTIONS "${CONFIGURE_OPTIONS};-DTPL_ENABLE_HDF5:BOOL=OFF" )
        #SET( CONFIGURE_OPTIONS "${CONFIGURE_OPTIONS};-DTPL_ENABLE_HDF5=ON" )
        #SET( CONFIGURE_OPTIONS "${CONFIGURE_OPTIONS};-DHDF5_LIBRARY_DIRS=${HDF5_INSTALL_DIR}/lib" )
        #SET( CONFIGURE_OPTIONS "${CONFIGURE_OPTIONS};-DHDF5_INCLUDE_DIRS=${HDF5_INSTALL_DIR}/include" )
        #SET( TRILINOS_DEPENDS ${TRILINOS_DEPENDS} HDF5 )
    ELSE()
        SET( CONFIGURE_OPTIONS "${CONFIGURE_OPTIONS};-DTPL_ENABLE_HDF5:BOOL=OFF" )
    ENDIF()
    SET( CONFIGURE_OPTIONS "${CONFIGURE_OPTIONS};-DTPL_ENABLE_Matio=OFF" )
    IF ( ${CXX_STD} STREQUAL 98 )
        SET( CONFIGURE_OPTIONS "${CONFIGURE_OPTIONS};-DTrilinos_ENABLE_CXX11=OFF" )
    ELSEIF ( ( ${CXX_STD} STREQUAL 11 ) OR ( ${CXX_STD} STREQUAL 14 ) )
        SET( CONFIGURE_OPTIONS "${CONFIGURE_OPTIONS};-DTrilinos_ENABLE_CXX11=ON" )
    ENDIF()
    IF ( TRILINOS_PACKAGES )
        STRING( REPLACE "," ";" TRILINOS_PACKAGES "${TRILINOS_PACKAGES}" )
        FOREACH( package ${TRILINOS_PACKAGES} )
            SET( CONFIGURE_OPTIONS "${CONFIGURE_OPTIONS};-DTrilinos_ENABLE_${package}:BOOL=ON" )
        ENDFOREACH()
    ELSE()
        SET( CONFIGURE_OPTIONS "${CONFIGURE_OPTIONS};-DTrilinos_ENABLE_ALL_PACKAGES:BOOL=ON" )
        SET( CONFIGURE_OPTIONS "${CONFIGURE_OPTIONS};-DTrilinos_ENABLE_STK:BOOL=OFF" )
    ENDIF()
    STRING( REPLACE "," ";" TRILINOS_EXTRA_PACKAGES "${TRILINOS_EXTRA_PACKAGES}" )
    FOREACH( package ${TRILINOS_EXTRA_PACKAGES} )
        SET( CONFIGURE_OPTIONS "${CONFIGURE_OPTIONS};-DTrilinos_ENABLE_${package}:BOOL=ON" )
    ENDFOREACH()
    STRING( REPLACE "," ";" TRILINOS_EXTRA_REPOSITORIES "${TRILINOS_EXTRA_REPOSITORIES}" )
    FOREACH( repo ${TRILINOS_EXTRA_REPOSITORIES} )
        SET( CONFIGURE_OPTIONS "${CONFIGURE_OPTIONS};-DTrilinos_EXTRA_REPOSITORIES=${repo}" )
    ENDFOREACH()
    STRING( REPLACE "," ";" TRILINOS_EXTRA_FLAGS "${TRILINOS_EXTRA_FLAGS}" )
    FOREACH( flags ${TRILINOS_EXTRA_FLAGS} )
        SET( CONFIGURE_OPTIONS "${CONFIGURE_OPTIONS};${flags}" )
    ENDFOREACH()
    SET( CONFIGURE_OPTIONS "${CONFIGURE_OPTIONS};-DTrilinos_DUMP_LINK_LIBS=ON" )
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


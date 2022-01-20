# This will configure and build trilinos
# User can configure the source path by specifying TRILINOS_SRC_DIR,
#    the download path by specifying TRILINOS_URL, or the installed 
#    location by specifying TRILINOS_INSTALL_DIR


# Intialize download/src/install vars
SET( TRILINOS_BUILD_DIR "${CMAKE_BINARY_DIR}/TRILINOS-prefix/src/TRILINOS-build" )
IF ( TRILINOS_URL ) 
    MESSAGE("   TRILINOS_URL = ${TRILINOS_URL}")
    SET( TRILINOS_SRC_DIR "${CMAKE_BINARY_DIR}/TRILINOS-prefix/src/TRILINOS-src" )
    SET( TRILINOS_CMAKE_URL            "${TRILINOS_URL}"     )
    SET( TRILINOS_CMAKE_DOWNLOAD_DIR   "${TRILINOS_SRC_DIR}" )
    SET( TRILINOS_CMAKE_SOURCE_DIR     "${TRILINOS_SRC_DIR}" )
    SET( TRILINOS_CMAKE_INSTALL_DIR "${CMAKE_INSTALL_PREFIX}/trilinos" )
    SET( CMAKE_BUILD_TRILINOS TRUE )
ELSEIF ( TRILINOS_SRC_DIR )
    VERIFY_PATH("${TRILINOS_SRC_DIR}")
    MESSAGE("   TRILINOS_SRC_DIR = ${TRILINOS_SRC_DIR}")
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
MESSAGE( "   TRILINOS_INSTALL_DIR = ${TRILINOS_INSTALL_DIR}" )




# Configure trilinos
IF ( CMAKE_BUILD_TRILINOS )
    # Helper function to write variable to config file
    SET( TRILINOS_CMAKE_CONFIGURE "${CMAKE_BINARY_DIR}/TRILINOS-prefix/src/TrilinosConfigure.cmake" )
    FILE( WRITE  "${TRILINOS_CMAKE_CONFIGURE}" "# Include file to configure Trilinos\n" )
    FUNCTION( WRITE_TRILINOS_CONFIG VAR )
        FILE( APPEND "${TRILINOS_CMAKE_CONFIGURE}" "SET( ${VAR} ${ARGN} )\n" )
    ENDFUNCTION()
    FUNCTION( WRITE_TRILINOS_CONFIG_BOOL VAR )
        FILE( APPEND "${TRILINOS_CMAKE_CONFIGURE}" "SET( ${VAR} ${ARGN} CACHE BOOL \"\" )\n" )
    ENDFUNCTION()
    FUNCTION( WRITE_TRILINOS_CONFIG_PATH VAR )
        FILE( APPEND "${TRILINOS_CMAKE_CONFIGURE}" "SET( ${VAR} ${ARGN} CACHE PATH \"\" )\n" )
    ENDFUNCTION()
    FUNCTION( WRITE_TRILINOS_CONFIG_STRING VAR )
        FILE( APPEND "${TRILINOS_CMAKE_CONFIGURE}" "SET( ${VAR} ${ARGN} CACHE STRING \"\" )\n" )
    ENDFUNCTION()
    # Include the configure file
    SET( TRILINOS_CONFIGURE_OPTS
        ${CMAKE_ARGS}
        -DCMAKE_INSTALL_PREFIX=${CMAKE_INSTALL_PREFIX}/trilinos
        -DTrilinos_CONFIGURE_OPTIONS_FILE=${TRILINOS_CMAKE_CONFIGURE}
    )
    # Set basic info
    WRITE_TRILINOS_CONFIG_BOOL( Trilinos_VERBOSE_CONFIGURE ON )
    WRITE_TRILINOS_CONFIG( CMAKE_INSTALL_PREFIX ${CMAKE_INSTALL_PREFIX}/trilinos )
    WRITE_TRILINOS_CONFIG( CMAKE_BUILD_TYPE ${CMAKE_BUILD_TYPE} )
    IF ( ${CXX_STD} STREQUAL 98 )
        WRITE_TRILINOS_CONFIG_BOOL( Trilinos_ENABLE_CXX11 OFF )
    ELSEIF ( ( ${CXX_STD} STREQUAL 11 ) OR ( ${CXX_STD} STREQUAL 14 ) )
        WRITE_TRILINOS_CONFIG_BOOL( Trilinos_ENABLE_CXX11 ON )
    ENDIF()
    STRING( REPLACE "," ";" TRILINOS_EXTRA_FLAGS "${TRILINOS_EXTRA_FLAGS}" )
    FOREACH( flags ${TRILINOS_EXTRA_FLAGS} )
        SET( TRILINOS_CONFIGURE_OPTS ${TRILINOS_CONFIGURE_OPTS} ${flags} )
    ENDFOREACH()
    WRITE_TRILINOS_CONFIG( Trilinos_EXTRA_LIBS ${TRILINOS_EXTRA_LINK_FLAGS} )
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
        WRITE_TRILINOS_CONFIG_BOOL( TPL_ENABLE_MPI ON )
    ELSE()
        WRITE_TRILINOS_CONFIG_BOOL( TPL_ENABLE_MPI OFF )
    ENDIF()
    IF ( USE_OPENMP )
        WRITE_TRILINOS_CONFIG_BOOL( Trilinos_ENABLE_OpenMP ON )
    ELSE()
        WRITE_TRILINOS_CONFIG_BOOL( Trilinos_ENABLE_OpenMP OFF )
    ENDIF()
    # Configure Boost
    IF ( BOOST_INSTALL_DIR )
        SET( TRILINOS_DEPENDS ${TRILINOS_DEPENDS} BOOST )
        WRITE_TRILINOS_CONFIG_PATH( Boost_INCLUDE_DIRS "${BOOST_INSTALL_DIR}/include" )
    ELSE()
        WRITE_TRILINOS_CONFIG_BOOL( TPL_ENABLE_Boost OFF )
    ENDIF()
    # Configure HDF5
    IF ( HDF5_INSTALL_DIR AND NOT Trilinos_DISABLE_HDF5 )
        SET( TRILINOS_DEPENDS ${TRILINOS_DEPENDS} HDF5 )
        WRITE_TRILINOS_CONFIG_BOOL( TPL_ENABLE_HDF5 ON )
        SET( ENV{HDF5_ROOT} "${HDF5_INSTALL_DIR}" )
        SET( TRILINOS_CONFIGURE_OPTS ${TRILINOS_CONFIGURE_OPTS} -DHDF5_HOME=${HDF5_INSTALL_DIR} )
        SET( TRILINOS_CONFIGURE_OPTS ${TRILINOS_CONFIGURE_OPTS} -DHDF5_ROOT=${HDF5_INSTALL_DIR} )
        SET( TRILINOS_CONFIGURE_OPTS ${TRILINOS_CONFIGURE_OPTS} -DHDF5_LIBRARY_DIRS=${HDF5_INSTALL_DIR}/lib )
        FILE( APPEND "${TRILINOS_CMAKE_CONFIGURE}" "SET( ENV{HDF5_HOME} \"${HDF5_INSTALL_DIR}\" )\n" )
        FILE( APPEND "${TRILINOS_CMAKE_CONFIGURE}" "SET( ENV{HDF5_ROOT} \"${HDF5_INSTALL_DIR}\" )\n" )
        FILE( APPEND "${TRILINOS_CMAKE_CONFIGURE}" "SET( ENV{HDF5_ROOT} \"${HDF5_INSTALL_DIR}\" )\n" )
        FILE( APPEND "${TRILINOS_CMAKE_CONFIGURE}" "FIND_LIBRARY( HDF5_LIB    NAMES hdf5    PATHS \"${HDF5_INSTALL_DIR}/lib\" NO_DEFAULT_PATH )\n" )
        FILE( APPEND "${TRILINOS_CMAKE_CONFIGURE}" "FIND_LIBRARY( HDF5_HL_LIB NAMES hdf5_hl PATHS \"${HDF5_INSTALL_DIR}/lib\" NO_DEFAULT_PATH )\n" )
        FILE( APPEND "${TRILINOS_CMAKE_CONFIGURE}" "SET( TPL_HDF5_LIBRARIES $\{HDF5_HL_LIB} $\{HDF5_LIB} )\n" )
        WRITE_TRILINOS_CONFIG_PATH( HDF5_LIBRARY_DIRS "${HDF5_INSTALL_DIR}/lib" )
        WRITE_TRILINOS_CONFIG_PATH( HDF5_INCLUDE_DIRS "${HDF5_INSTALL_DIR}/include" )
        WRITE_TRILINOS_CONFIG_PATH( TPL_HDF5_INCLUDE_DIRS "${HDF5_INSTALL_DIR}/include" )
    ELSE()
        WRITE_TRILINOS_CONFIG_BOOL( TPL_ENABLE_HDF5 OFF )
    ENDIF()
    # Configure Netcdf
    IF ( NETCDF_INSTALL_DIR AND NOT Trilinos_DISABLE_Netcdf )
        SET( TRILINOS_DEPENDS ${TRILINOS_DEPENDS} NETCDF )
        WRITE_TRILINOS_CONFIG_BOOL( TPL_ENABLE_Netcdf ON )
        WRITE_TRILINOS_CONFIG_PATH( Netcdf_LIBRARY_DIRS "${NETCDF_INSTALL_DIR}/lib" )
        WRITE_TRILINOS_CONFIG_PATH( Netcdf_INCLUDE_DIRS "${NETCDF_INSTALL_DIR}/include" )
        WRITE_TRILINOS_CONFIG_PATH( TPL_Netcdf_INCLUDE_DIRS "${NETCDF_INSTALL_DIR}/include" )
        FILE( APPEND "${TRILINOS_CMAKE_CONFIGURE}" "FIND_LIBRARY( NETCDF_LIB      NAMES netcdf   PATHS \"${NETCDF_INSTALL_DIR}/lib\" NO_DEFAULT_PATH )\n" )
        FILE( APPEND "${TRILINOS_CMAKE_CONFIGURE}" "FIND_LIBRARY( NETCDF_HDF5_LIB NAMES hdf5     PATHS \"${HDF5_INSTALL_DIR}/lib\" NO_DEFAULT_PATH )\n" )
        FILE( APPEND "${TRILINOS_CMAKE_CONFIGURE}" "FIND_LIBRARY( NETCDF_HL_LIB   NAMES hdf5_hl  PATHS \"${HDF5_INSTALL_DIR}/lib\" NO_DEFAULT_PATH )\n" )
        FILE( APPEND "${TRILINOS_CMAKE_CONFIGURE}" "FIND_LIBRARY( NETCDF_ZLIB     NAMES z        PATHS \"${ZLIB_INSTALL_DIR}/lib\" NO_DEFAULT_PATH )\n" )
        FILE( APPEND "${TRILINOS_CMAKE_CONFIGURE}" "FIND_LIBRARY( NETCDF_DL       NAMES dl       PATHS /usr/local/lib /usr/lib /lib /usr/lib/x86_64-linux-gnu ${CMAKE_EXTRA_LIBRARIES})\n" )
        FILE( APPEND "${TRILINOS_CMAKE_CONFIGURE}" "STRING( REPLACE \"/lib/\" \"/lib/../lib/\" NETCDF_HDF5_LIB $\{NETCDF_HDF5_LIB} )\n" )
        FILE( APPEND "${TRILINOS_CMAKE_CONFIGURE}" "SET( TPL_Netcdf_LIBRARIES $\{NETCDF_LIB} $\{NETCDF_HL_LIB} $\{NETCDF_HDF5_LIB} $\{NETCDF_ZLIB} $\{NETCDF_DL} )\n" )
    ELSE()
        WRITE_TRILINOS_CONFIG_BOOL( TPL_ENABLE_Netcdf OFF )
    ENDIF()
    WRITE_TRILINOS_CONFIG_BOOL( TPL_ENABLE_Matio OFF )
    IF ( TRILINOS_PACKAGES )
        STRING( REPLACE "," ";" TRILINOS_PACKAGES "${TRILINOS_PACKAGES}" )
        FOREACH( package ${TRILINOS_PACKAGES} )
            WRITE_TRILINOS_CONFIG_BOOL( Trilinos_ENABLE_${package} ON )
        ENDFOREACH()
    ELSE()
        WRITE_TRILINOS_CONFIG_BOOL( Trilinos_ENABLE_ALL_PACKAGES ON )
        WRITE_TRILINOS_CONFIG_BOOL( Trilinos_ENABLE_Sundance OFF )
        WRITE_TRILINOS_CONFIG_BOOL( Trilinos_ENABLE_Pike OFF )
        WRITE_TRILINOS_CONFIG_BOOL( Trilinos_ENABLE_Teko OFF )
        WRITE_TRILINOS_CONFIG_BOOL( Trilinos_ENABLE_SEACAS OFF )
        WRITE_TRILINOS_CONFIG_BOOL( Trilinos_ENABLE_MOOCHO OFF )
        IF ( NETCDF_INSTALL_DIR AND NOT Trilinos_DISABLE_Netcdf )
            WRITE_TRILINOS_CONFIG_BOOL( Trilinos_ENABLE_STKClassic ON )
        ELSE()
            WRITE_TRILINOS_CONFIG_BOOL( Trilinos_ENABLE_STK OFF )
        ENDIF()
    ENDIF()
    STRING( REPLACE "," ";" TRILINOS_EXTRA_PACKAGES "${TRILINOS_EXTRA_PACKAGES}" )
    FOREACH( package ${TRILINOS_EXTRA_PACKAGES} )
        WRITE_TRILINOS_CONFIG_BOOL( Trilinos_ENABLE_${package} ON )
    ENDFOREACH()
    STRING( REPLACE "," ";" TRILINOS_EXTRA_REPOSITORIES "${TRILINOS_EXTRA_REPOSITORIES}" )
    FOREACH( repo ${TRILINOS_EXTRA_REPOSITORIES} )
        WRITE_TRILINOS_CONFIG_STRING( Trilinos_EXTRA_REPOSITORIES ${repo} )
    ENDFOREACH()
    WRITE_TRILINOS_CONFIG_BOOL( Trilinos_DUMP_LINK_LIBS ON )
    FILE( APPEND "${TRILINOS_CMAKE_CONFIGURE}" "SET( Trilinos_EXTRA_LINK_FLAGS $\{TRILINOS_EXTRA_LIBS} CACHE STRING \"\" FORCE )\n" )
    FILE( APPEND "${TRILINOS_CMAKE_CONFIGURE}" "MESSAGE( \"Trilinos_EXTRA_LINK_FLAGS=$\{Trilinos_EXTRA_LINK_FLAGS}\")\n" )
ENDIF()


# Configure trilinos
ADD_TPL(
    TRILINOS
    URL                 "${TRILINOS_CMAKE_URL}"
    TIMEOUT             300
    DOWNLOAD_DIR        "${TRILINOS_CMAKE_DOWNLOAD_DIR}"
    SOURCE_DIR          "${TRILINOS_CMAKE_SOURCE_DIR}"
    UPDATE_COMMAND      ""
    BUILD_IN_SOURCE     0
    INSTALL_DIR         ${CMAKE_INSTALL_PREFIX}/trilinos
    CMAKE_ARGS          ${TRILINOS_CONFIGURE_OPTS}
    BUILD_COMMAND       ${CMAKE_MAKE_PROGRAM} install -j ${PROCS_INSTALL} VERBOSE=1
    DEPENDS             ${TRILINOS_DEPENDS}
    CLEAN_COMMAND       make clean -j ${PROCS_INSTALL}
    LOG_DOWNLOAD 1   LOG_UPDATE 1   LOG_CONFIGURE 1   LOG_BUILD 1   LOG_TEST 1   LOG_INSTALL 1
)


# Add the appropriate fields to FindTPLs.cmake
FILE( APPEND "${FIND_TPLS_CMAKE}" "\n# Find TRILINOS\n" )
FILE( APPEND "${FIND_TPLS_CMAKE}" "IF ( TPLs_FIND_TRILINOS AND NOT TPL_FOUND_TRILINOS )\n" )
FILE( APPEND "${FIND_TPLS_CMAKE}" "    FIND_PACKAGE(Trilinos PATHS ${TRILINOS_INSTALL_DIR}/lib/cmake/Trilinos)\n" )
FILE( APPEND "${FIND_TPLS_CMAKE}" "    IF ( NOT Trilinos_FOUND )\n" )
FILE( APPEND "${FIND_TPLS_CMAKE}" "        MESSAGE(FATAL_ERROR \"Trilinos not found\")\n" )
FILE( APPEND "${FIND_TPLS_CMAKE}" "    ENDIF()\n" )
FILE( APPEND "${FIND_TPLS_CMAKE}" "    LIST(REVERSE Trilinos_LIBRARIES)\n" )
FILE( APPEND "${FIND_TPLS_CMAKE}" "    LIST(REMOVE_DUPLICATES Trilinos_LIBRARIES)\n" )
FILE( APPEND "${FIND_TPLS_CMAKE}" "    LIST(REVERSE Trilinos_LIBRARIES)\n" )
FILE( APPEND "${FIND_TPLS_CMAKE}" "    IF ( NOT TPLs_FIND_QUIETLY )\n" )
FILE( APPEND "${FIND_TPLS_CMAKE}" "        MESSAGE(\"Found Trilinos:\")\n" )
FILE( APPEND "${FIND_TPLS_CMAKE}" "        MESSAGE(\"   Trilinos_DIR = $\{Trilinos_DIR}\")\n" )
FILE( APPEND "${FIND_TPLS_CMAKE}" "        MESSAGE(\"   Trilinos_VERSION = $\{Trilinos_VERSION}\"\)\n" )
FILE( APPEND "${FIND_TPLS_CMAKE}" "        MESSAGE(\"   Trilinos_PACKAGE_LIST = $\{Trilinos_PACKAGE_LIST}\")\n" )
FILE( APPEND "${FIND_TPLS_CMAKE}" "        MESSAGE(\"   Trilinos_LIBRARIES = $\{Trilinos_LIBRARIES}\")\n" )
FILE( APPEND "${FIND_TPLS_CMAKE}" "        MESSAGE(\"   Trilinos_INCLUDE_DIRS = $\{Trilinos_INCLUDE_DIRS}\")\n" )
FILE( APPEND "${FIND_TPLS_CMAKE}" "        MESSAGE(\"   Trilinos_TPL_LIST = $\{Trilinos_TPL_LIST}\")\n" )
FILE( APPEND "${FIND_TPLS_CMAKE}" "    ENDIF()\n" )
FILE( APPEND "${FIND_TPLS_CMAKE}" "    SET( TRILINOS_PACKAGE_LIST $\{Trilinos_PACKAGE_LIST} )\n" )
FILE( APPEND "${FIND_TPLS_CMAKE}" "    FOREACH( tmp $\{Trilinos_PACKAGE_LIST} )\n" )
FILE( APPEND "${FIND_TPLS_CMAKE}" "        STRING(TOUPPER $\{tmp} tmp)\n")
FILE( APPEND "${FIND_TPLS_CMAKE}" "        STRING(REPLACE \"-\" \"_\" tmp $\{tmp} )\n")
FILE( APPEND "${FIND_TPLS_CMAKE}" "        SET( USE_TRILINOS_$\{tmp} 1 )\n" )
FILE( APPEND "${FIND_TPLS_CMAKE}" "    ENDFOREACH()\n" )
FILE( APPEND "${FIND_TPLS_CMAKE}" "    LINK_DIRECTORIES( ${Trilinos_LIBRARY_DIRS} )\n" )
FILE( APPEND "${FIND_TPLS_CMAKE}" "    SET( TPL_INCLUDE_DIRS $\{TPL_INCLUDE_DIRS} $\{Trilinos_INCLUDE_DIRS} )\n" )
FILE( APPEND "${FIND_TPLS_CMAKE}" "    SET( TPL_LIBRARIES $\{Trilinos_LIBRARIES} $\{TPL_LIBRARIES} )\n" )
FILE( APPEND "${FIND_TPLS_CMAKE}" "    SET( TRILINOS_FOUND TRUE )\n" )
FILE( APPEND "${FIND_TPLS_CMAKE}" "    SET( TPL_FOUND_TRILINOS TRUE )\n" )
FILE( APPEND "${FIND_TPLS_CMAKE}" "ENDIF()\n" )
FILE( APPEND "${FIND_TPLS_CMAKE}" "\n" )


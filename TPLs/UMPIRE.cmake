# This will configure and build umpire
# User can configure the source path by specifying UMPIRE_SRC_DIR,
#    the download path by specifying UMPIRE_URL, or the installed 
#    location by specifying UMPIRE_INSTALL_DIR


# Intialize download/src/install vars
SET( UMPIRE_BUILD_DIR "${CMAKE_BINARY_DIR}/UMPIRE-prefix/src/UMPIRE-build" )
IF ( UMPIRE_URL ) 
    MESSAGE("   UMPIRE_URL = ${UMPIRE_URL}")
    SET( UMPIRE_SRC_DIR "${CMAKE_BINARY_DIR}/UMPIRE-prefix/src/UMPIRE-src" )
    SET( UMPIRE_CMAKE_URL            "${UMPIRE_URL}"       )
    SET( UMPIRE_CMAKE_DOWNLOAD_DIR   "${UMPIRE_SRC_DIR}" )
    SET( UMPIRE_CMAKE_SOURCE_DIR     "${UMPIRE_SRC_DIR}" )
    SET( UMPIRE_CMAKE_INSTALL_DIR "${CMAKE_INSTALL_PREFIX}/umpire" )
    SET( CMAKE_BUILD_UMPIRE TRUE )
ELSEIF ( UMPIRE_SRC_DIR )
    VERIFY_PATH("${UMPIRE_SRC_DIR}")
    MESSAGE("   UMPIRE_SRC_DIR = ${UMPIRE_SRC_DIR}")
    SET( UMPIRE_CMAKE_URL            ""   )
    SET( UMPIRE_CMAKE_DOWNLOAD_DIR   "" )
    SET( UMPIRE_CMAKE_SOURCE_DIR     "${UMPIRE_SRC_DIR}" )
    SET( UMPIRE_CMAKE_INSTALL_DIR "${CMAKE_INSTALL_PREFIX}/umpire" )
    SET( CMAKE_BUILD_UMPIRE TRUE )
ELSEIF ( UMPIRE_INSTALL_DIR ) 
    SET( UMPIRE_CMAKE_INSTALL_DIR "${UMPIRE_INSTALL_DIR}" )
    SET( CMAKE_BUILD_UMPIRE FALSE )
ELSE()
    MESSAGE(FATAL_ERROR "Please specify UMPIRE_SRC_DIR, UMPIRE_URL, or UMPIRE_INSTALL_DIR")
ENDIF()
SET( UMPIRE_INSTALL_DIR "${UMPIRE_CMAKE_INSTALL_DIR}" )
MESSAGE( "   UMPIRE_INSTALL_DIR = ${UMPIRE_INSTALL_DIR}" )


# Configure umpire
IF ( NOT DEFINED UMPIRE_USE_CUDA )
    SET( UMPIRE_USE_CUDA ${USE_CUDA} )
ENDIF()
IF ( NOT DEFINED UMPIRE_USE_OPENMP )
    SET( UMPIRE_USE_OPENMP ${USE_OPENMP} )
ENDIF()
IF ( CMAKE_BUILD_UMPIRE )
    SET( UMPIRE_CONFIGURE_OPTIONS -DCMAKE_INSTALL_PREFIX=${UMPIRE_CMAKE_INSTALL_DIR} )
        # Note that the dev version changes this to UMPIRE_ENABLE_C according to the documentation
        # -DENABLE_C appears to be the correct option for Umpire 6.0.0
        SET( UMPIRE_CONFIGURE_OPTIONS ${UMPIRE_CONFIGURE_OPTIONS} -DCMAKE_BUILD_TYPE=${CMAKE_BUILD_TYPE} -DENABLE_C=ON )
    IF ( UMPIRE_USE_OPENMP )
        MESSAGE( "Enabling OpenMP support for Umpire" )
        SET( UMPIRE_CONFIGURE_OPTIONS ${UMPIRE_CONFIGURE_OPTIONS} -DENABLE_OPENMP=ON )
    ENDIF()
    IF ( UMPIRE_USE_CUDA )
        MESSAGE( "Enabling CUDA support for Umpire" )
        IF ( UMPIRE_CUDA_ARCH_FLAGS )
             SET( UMPIRE_CONFIGURE_OPTIONS ${UMPIRE_CONFIGURE_OPTIONS} -DENABLE_CUDA=ON -DCMAKE_CUDA_FLAGS=${UMPIRE_CUDA_ARCH_FLAGS} )
	ELSE()
	     MESSAGE(FATAL_ERROR "Please specify UMPIRE_CUDA_ARCH_FLAGS if using CUDA")      
        ENDIF()
        # Set more options
        SET( UMPIRE_CONFIGURE_OPTIONS ${UMPIRE_CONFIGURE_OPTIONS} -DCMAKE_CXX_COMPILER=${CMAKE_CXX_COMPILER} )
        MESSAGE("   UMPIRE configured with cuda:")
    ELSE()
        SET( UMPIRE_CONFIGURE_OPTIONS ${UMPIRE_CONFIGURE_OPTIONS} -DCMAKE_CXX_COMPILER=${CMAKE_CXX_COMPILER} )
        MESSAGE("   UMPIRE configured without cuda")
    ENDIF()
    IF ( ENABLE_SHARED AND ENABLE_STATIC )
        MESSAGE(FATAL_ERROR "Compiling umpire with both static and shared libraries is not yet supported")
    ELSEIF ( ENABLE_SHARED )
        SET( UMPIRE_CONFIGURE_OPTIONS ${UMPIRE_CONFIGURE_OPTIONS} )
    ELSEIF ( ENABLE_STATIC )
        SET( UMPIRE_CONFIGURE_OPTIONS ${UMPIRE_CONFIGURE_OPTIONS} )
    ENDIF()
    MESSAGE("   UMPIRE configure options: ${UMPIRE_CONFIGURE_OPTIONS}")
ENDIF()


# Build umpire
IF ( CMAKE_BUILD_UMPIRE )
    ADD_TPL( 
        UMPIRE
        URL                 "${UMPIRE_CMAKE_URL}"
        DOWNLOAD_DIR        "${UMPIRE_CMAKE_DOWNLOAD_DIR}"
        SOURCE_DIR          "${UMPIRE_CMAKE_SOURCE_DIR}"
        UPDATE_COMMAND      ""
        CMAKE_ARGS          ${UMPIRE_CONFIGURE_OPTIONS}
        BUILD_COMMAND       ${CMAKE_MAKE_PROGRAM} -j ${PROCS_INSTALL} VERBOSE=1
        BUILD_IN_SOURCE     0
        INSTALL_COMMAND     ${CMAKE_MAKE_PROGRAM} install; 
        DEPENDS             
        LOG_DOWNLOAD 1   LOG_UPDATE 1   LOG_CONFIGURE 1   LOG_BUILD 1   LOG_TEST 1   LOG_INSTALL 1
    )
ELSE()
    ADD_TPL_EMPTY( UMPIRE )
ENDIF()


# Add the appropriate fields to FindTPLs.cmake
FILE( APPEND "${FIND_TPLS_CMAKE}" "\n# Find UMPIRE\n" )
FILE( APPEND "${FIND_TPLS_CMAKE}" "IF ( TPLs_FIND_UMPIRE AND NOT TPL_FOUND_UMPIRE )\n" )
FILE( APPEND "${FIND_TPLS_CMAKE}" "    SET( UMPIRE_DIR \"${UMPIRE_INSTALL_DIR}\" )\n" )
FILE( APPEND "${FIND_TPLS_CMAKE}" "    SET( UMPIRE_DIRECTORY \"${UMPIRE_INSTALL_DIR}\" )\n" )
FILE( APPEND "${FIND_TPLS_CMAKE}" "    SET( UMPIRE_INCLUDE \"${UMPIRE_INSTALL_DIR}/include\" )\n" )
FILE( APPEND "${FIND_TPLS_CMAKE}" "    FIND_LIBRARY( UMPIRE_LIB  NAMES umpire  PATHS \"$\{UMPIRE_DIRECTORY}/lib\"  NO_DEFAULT_PATH )\n" )
FILE( APPEND "${FIND_TPLS_CMAKE}" "    IF ( NOT UMPIRE_LIB )\n" )
FILE( APPEND "${FIND_TPLS_CMAKE}" "        MESSAGE(FATAL_ERROR \"umpire library not found in $\{UMPIRE_DIRECTORY}/lib\")\n" )
FILE( APPEND "${FIND_TPLS_CMAKE}" "    ENDIF()\n" )
FILE( APPEND "${FIND_TPLS_CMAKE}" "    SET( CMAKE_CXX_FLAGS \"$\{CMAKE_CXX_FLAGS} -Wno-unused-parameter -fopenmp\" )\n" )
FILE( APPEND "${FIND_TPLS_CMAKE}" "    SET( TPL_INCLUDE_DIRS $\{TPL_INCLUDE_DIRS} $\{UMPIRE_INCLUDE} )\n" )
FILE( APPEND "${FIND_TPLS_CMAKE}" "    SET( TPL_LIBRARIES $\{UMPIRE_LIB} $\{TPL_LIBRARIES} )\n" )
FILE( APPEND "${FIND_TPLS_CMAKE}" "    SET( UMPIRE_FOUND TRUE )\n" )
FILE( APPEND "${FIND_TPLS_CMAKE}" "    SET( TPL_FOUND_UMPIRE TRUE )\n" )
FILE( APPEND "${FIND_TPLS_CMAKE}" "ENDIF()\n" )
FILE( APPEND "${FIND_TPLS_CMAKE}" "\n" )


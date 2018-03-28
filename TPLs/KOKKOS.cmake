# This will configure and build kokkos
# User can configure the source path by specifying KOKKOS_SRC_DIR,
#    the download path by specifying KOKKOS_URL, or the installed 
#    location by specifying KOKKOS_INSTALL_DIR


# Intialize download/src/install vars
SET( KOKKOS_BUILD_DIR "${CMAKE_BINARY_DIR}/KOKKOS-prefix/src/KOKKOS-build" )
IF ( KOKKOS_URL ) 
    MESSAGE("   KOKKOS_URL = ${KOKKOS_URL}")
    SET( KOKKOS_CMAKE_URL            "${KOKKOS_URL}"       )
    SET( KOKKOS_CMAKE_DOWNLOAD_DIR   "${KOKKOS_BUILD_DIR}" )
    SET( KOKKOS_CMAKE_SOURCE_DIR     "${KOKKOS_BUILD_DIR}" )
    SET( KOKKOS_CMAKE_INSTALL_DIR "${CMAKE_INSTALL_PREFIX}/kokkos" )
    SET( CMAKE_BUILD_KOKKOS TRUE )
ELSEIF ( KOKKOS_SRC_DIR )
    VERIFY_PATH("${KOKKOS_SRC_DIR}")
    MESSAGE("   KOKKOS_SRC_DIR = ${KOKKOS_SRC_DIR}")
    SET( KOKKOS_CMAKE_URL            ""   )
    SET( KOKKOS_CMAKE_DOWNLOAD_DIR   "" )
    SET( KOKKOS_CMAKE_SOURCE_DIR     "${KOKKOS_SRC_DIR}" )
    SET( KOKKOS_CMAKE_INSTALL_DIR "${CMAKE_INSTALL_PREFIX}/kokkos" )
    SET( CMAKE_BUILD_KOKKOS TRUE )
ELSEIF ( KOKKOS_INSTALL_DIR ) 
    SET( KOKKOS_CMAKE_INSTALL_DIR "${KOKKOS_INSTALL_DIR}" )
    SET( CMAKE_BUILD_KOKKOS FALSE )
ELSE()
    MESSAGE(FATAL_ERROR "Please specify KOKKOS_SRC_DIR, KOKKOS_URL, or KOKKOS_INSTALL_DIR")
ENDIF()
SET( KOKKOS_INSTALL_DIR "${KOKKOS_CMAKE_INSTALL_DIR}" )
MESSAGE( "   KOKKOS_INSTALL_DIR = ${KOKKOS_INSTALL_DIR}" )


# Configure kokkos
IF ( CMAKE_BUILD_KOKKOS )
    FILE( WRITE "${CMAKE_INSTALL_PREFIX}/kokkos/KOKKOS.cmake" "# This file is automatically generated by the TPL builder\n" )
    FILE( APPEND "${CMAKE_INSTALL_PREFIX}/kokkos/KOKKOS.cmake" "SET( KOKKOS_INCLUDE \"${KOKKOS_CMAKE_INSTALL_DIR}/include\" )\n" )
    FILE( APPEND "${CMAKE_INSTALL_PREFIX}/kokkos/KOKKOS.cmake" "SET( KOKKOS_LIBDIR \"${KOKKOS_CMAKE_INSTALL_DIR}/lib\" )\n" )
    SET( CONFIGURE_OPTIONS --prefix=${KOKKOS_CMAKE_INSTALL_DIR} )
    IF ( CUDA_INSTALL )
        IF ( NOT CUDA_ARCH )
            MESSAGE(FATAL_ERROR "CUDA_ARCH must be set")
        ENDIF()
        FILE(READ "${KOKKOS_CMAKE_SOURCE_DIR}/config/nvcc_wrapper" NVCC_WRAPPER_CONTENTS)
        STRING(REGEX REPLACE "#default_arch=[^\n]*" "" NVCC_WRAPPER_CONTENTS "${NVCC_WRAPPER_CONTENTS}")
        STRING(REGEX REPLACE "default_arch=[^\n]*" "default_arch=\"${CUDA_ARCH}\"" NVCC_WRAPPER_CONTENTS "${NVCC_WRAPPER_CONTENTS}")
        STRING(REGEX REPLACE "#default_compiler=[^\n]*" "" NVCC_WRAPPER_CONTENTS "${NVCC_WRAPPER_CONTENTS}")
        STRING(REGEX REPLACE "default_compiler=[^\n]*" "default_compiler=\"${CMAKE_CXX_COMPILER}\"" NVCC_WRAPPER_CONTENTS "${NVCC_WRAPPER_CONTENTS}")
        SET( NVCC_WRAPPER_OUT "${CMAKE_BINARY_DIR}/KOKKOS-prefix/src/nvcc_wrapper" )
        FILE(WRITE "${NVCC_WRAPPER_OUT}" "${NVCC_WRAPPER_CONTENTS}")
        FILE(COPY "${NVCC_WRAPPER_OUT}" DESTINATION "${KOKKOS_BUILD_DIR}"
            FILE_PERMISSIONS OWNER_READ OWNER_WRITE OWNER_EXECUTE GROUP_READ GROUP_EXECUTE WORLD_READ WORLD_EXECUTE )
        FILE(COPY "${NVCC_WRAPPER_OUT}" DESTINATION "${CMAKE_INSTALL_PREFIX}/kokkos"
            FILE_PERMISSIONS OWNER_READ OWNER_WRITE OWNER_EXECUTE GROUP_READ GROUP_EXECUTE WORLD_READ WORLD_EXECUTE )
        #EXECUTE_PROCESS( COMMAND ${CMAKE_COMMAND} -E copy "${KOKKOS_CMAKE_SOURCE_DIR}/config/nvcc_wrapper" "${CMAKE_INSTALL_PREFIX}/kokkos/nvcc_wrapper" )
        SET( CONFIGURE_OPTIONS ${CONFIGURE_OPTIONS} --compiler=${CMAKE_INSTALL_PREFIX}/kokkos/nvcc_wrapper )
        SET( CONFIGURE_OPTIONS ${CONFIGURE_OPTIONS} --with-pthread --with-openmp --with-serial )
        SET( CONFIGURE_OPTIONS ${CONFIGURE_OPTIONS} --with-cuda=${CUDA_INSTALL} )
        FILE( APPEND "${CMAKE_INSTALL_PREFIX}/kokkos/KOKKOS.cmake" "SET( KOKKOS_COMPILER \"${CMAKE_INSTALL_PREFIX}/kokkos/nvcc_wrapper\" )\n" )
        FILE( APPEND "${CMAKE_INSTALL_PREFIX}/kokkos/KOKKOS.cmake" "SET( KOKKOS_SERIAL ON )\n" )
        FILE( APPEND "${CMAKE_INSTALL_PREFIX}/kokkos/KOKKOS.cmake" "SET( KOKKOS_OPENMP ON )\n" )
        FILE( APPEND "${CMAKE_INSTALL_PREFIX}/kokkos/KOKKOS.cmake" "SET( KOKKOS_PTHREAD ON )\n" )
        FILE( APPEND "${CMAKE_INSTALL_PREFIX}/kokkos/KOKKOS.cmake" "SET( KOKKOS_CUDA ON )\n" )
        MESSAGE("   KOKKOS configured with cuda (${CUDA_INSTALL})")
    ELSE()
        SET( CONFIGURE_OPTIONS ${CONFIGURE_OPTIONS} --compiler=${CMAKE_CXX_COMPILER} )
        SET( CONFIGURE_OPTIONS ${CONFIGURE_OPTIONS} --cxxflags=${CMAKE_CXX_FLAGS} )
        SET( CONFIGURE_OPTIONS ${CONFIGURE_OPTIONS} --with-pthread --with-openmp --with-serial )
        FILE( APPEND "${CMAKE_INSTALL_PREFIX}/kokkos/KOKKOS.cmake" "SET( KOKKOS_COMPILER \"${CMAKE_CXX_COMPILER}\")\n" )
        FILE( APPEND "${CMAKE_INSTALL_PREFIX}/kokkos/KOKKOS.cmake" "SET( KOKKOS_SERIAL ON )\n" )
        FILE( APPEND "${CMAKE_INSTALL_PREFIX}/kokkos/KOKKOS.cmake" "SET( KOKKOS_OPENMP ON )\n" )
        FILE( APPEND "${CMAKE_INSTALL_PREFIX}/kokkos/KOKKOS.cmake" "SET( KOKKOS_PTHREAD ON )\n" )
        MESSAGE("   KOKKOS configured without cuda")
    ENDIF()
    IF ( ${CMAKE_BUILD_TYPE} STREQUAL "Debug" )
        SET( CONFIGURE_OPTIONS ${CONFIGURE_OPTIONS} --debug )
    ELSEIF ( ${CMAKE_BUILD_TYPE} STREQUAL "Release" )
        SET( CONFIGURE_OPTIONS ${CONFIGURE_OPTIONS} )
    ELSE()
        MESSAGE ( FATAL_ERROR "Unknown CMAKE_BUILD_TYPE=${CMAKE_BUILD_TYPE}" )
    ENDIF()
    IF ( ENABLE_SHARED AND ENABLE_STATIC )
        MESSAGE(FATAL_ERROR "Compiling kokkos with both static and shared libraries is not yet supported")
    ELSEIF ( ENABLE_SHARED )
        SET( CONFIGURE_OPTIONS ${CONFIGURE_OPTIONS} )
    ELSEIF ( ENABLE_STATIC )
        SET( CONFIGURE_OPTIONS ${CONFIGURE_OPTIONS} )
    ENDIF()
    MESSAGE("   KOKKOS configure options: ${CONFIGURE_OPTIONS}")
ENDIF()


# Build kokkos
IF ( CMAKE_BUILD_KOKKOS )
    EXTERNALPROJECT_ADD( 
        KOKKOS
        URL                 "${KOKKOS_CMAKE_URL}"
        DOWNLOAD_DIR        "${KOKKOS_CMAKE_DOWNLOAD_DIR}"
        SOURCE_DIR          "${KOKKOS_CMAKE_SOURCE_DIR}"
        UPDATE_COMMAND      ""
        CONFIGURE_COMMAND   ${KOKKOS_CMAKE_SOURCE_DIR}/generate_makefile.bash ${CONFIGURE_OPTIONS}
        BUILD_COMMAND       make
        BUILD_IN_SOURCE     0
        INSTALL_COMMAND     make install
        DEPENDS             
        LOG_DOWNLOAD 1   LOG_UPDATE 1   LOG_CONFIGURE 1   LOG_BUILD 1   LOG_TEST 1   LOG_INSTALL 1
    )
    ADD_TPL_SAVE_LOGS( KOKKOS )
    ADD_TPL_CLEAN( KOKKOS )
ELSE()
    ADD_TPL_EMPTY( KOKKOS )
ENDIF()


# Add the appropriate fields to FindTPLs.cmake
FILE( APPEND "${FIND_TPLS_CMAKE}" "\n# Find KOKKOS\n" )
FILE( APPEND "${FIND_TPLS_CMAKE}" "IF ( TPLs_FIND_KOKKOS AND NOT TPL_FOUND_KOKKOS )\n" )
FILE( APPEND "${FIND_TPLS_CMAKE}" "    SET( KOKKOS_DIR \"${KOKKOS_INSTALL_DIR}\" )\n" )
FILE( APPEND "${FIND_TPLS_CMAKE}" "    SET( KOKKOS_DIRECTORY \"${KOKKOS_INSTALL_DIR}\" )\n" )
FILE( APPEND "${FIND_TPLS_CMAKE}" "    FIND_LIBRARY( KOKKOS_LIB  NAMES kokkos  PATHS \"$\{KOKKOS_DIRECTORY}/lib\"  NO_DEFAULT_PATH )\n" )
FILE( APPEND "${FIND_TPLS_CMAKE}" "    IF ( NOT KOKKOS_LIB )\n" )
FILE( APPEND "${FIND_TPLS_CMAKE}" "        MESSAGE(FATAL_ERROR \"kokkos library not found in $\{KOKKOS_DIRECTORY}/lib\")\n" )
FILE( APPEND "${FIND_TPLS_CMAKE}" "    ENDIF()\n" )
FILE( APPEND "${FIND_TPLS_CMAKE}" "    SET( CMAKE_CXX_FLAGS \"$\{CMAKE_CXX_FLAGS} -Wno-unused-parameter -fopenmp\" )\n" )
FILE( APPEND "${FIND_TPLS_CMAKE}" "    # IF ( EXISTS \"$\{KOKKOS_DIRECTORY}/nvcc_wrapper\" )\n" )
FILE( APPEND "${FIND_TPLS_CMAKE}" "    #    SET( CMAKE_CXX_COMPILER \"$\{KOKKOS_DIRECTORY}/nvcc_wrapper\" )\n" )
FILE( APPEND "${FIND_TPLS_CMAKE}" "    # ENDIF()\n" )
FILE( APPEND "${FIND_TPLS_CMAKE}" "    SET( TPL_INCLUDE_DIRS $\{TPL_INCLUDE_DIRS} $\{KOKKOS_INCLUDE} )\n" )
FILE( APPEND "${FIND_TPLS_CMAKE}" "    SET( TPL_LIBRARIES $\{KOKKOS_LIB} $\{TPL_LIBRARIES} )\n" )
FILE( APPEND "${FIND_TPLS_CMAKE}" "    SET( KOKKOS_FOUND TRUE )\n" )
FILE( APPEND "${FIND_TPLS_CMAKE}" "    SET( TPL_FOUND_KOKKOS TRUE )\n" )
FILE( APPEND "${FIND_TPLS_CMAKE}" "ENDIF()\n" )
FILE( APPEND "${FIND_TPLS_CMAKE}" "\n" )


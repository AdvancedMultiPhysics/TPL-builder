# Set some CMake properties
CMAKE_MINIMUM_REQUIRED( VERSION 3.28.3 )
CMAKE_POLICY( SET CMP0135 NEW )


MESSAGE("================")
MESSAGE("Configuring TPLS")
MESSAGE("================")


# Print the CMake version
MESSAGE( "CMake Version: ${CMAKE_VERSION}" )


# Set the compilers (must be done before PROJECT)
IF ( NOT CMAKE_C_COMPILER AND C_COMPILER )
    SET( CMAKE_C_COMPILER "${C_COMPILER}" )
ENDIF()
IF ( NOT CMAKE_CXX_COMPILER AND CXX_COMPILER )
    SET( CMAKE_CXX_COMPILER "${CXX_COMPILER}" )
ENDIF()
IF ( NOT CMAKE_Fortran_COMPILER AND Fortran_COMPILER )
    SET( CMAKE_Fortran_COMPILER "${Fortran_COMPILER}" )
ELSEIF ( NOT CMAKE_Fortran_COMPILER AND FORTRAN_COMPILER )
    SET( CMAKE_Fortran_COMPILER "${FORTRAN_COMPILER}" )
ENDIF()


# Set the project name
PROJECT( TPLS )


# Set the install path
IF( PREFIX )
    SET( CMAKE_INSTALL_PREFIX ${PREFIX} )
ELSEIF( INSTALL_DIR )
    SET( CMAKE_INSTALL_PREFIX ${INSTALL_DIR} )
ELSEIF( TPL_INSTALL_DIR )
    SET( CMAKE_INSTALL_PREFIX ${TPL_INSTALL_DIR} )
ELSE()
    SET( CMAKE_INSTALL_PREFIX ${CMAKE_CURRENT_BINARY_DIR} )
ENDIF()
IF ( NOT TPL_INSTALL_DIR )
    SET( TPL_INSTALL_DIR ${CMAKE_INSTALL_PREFIX} )
ENDIF()
IF ( "${CMAKE_CURRENT_BINARY_DIR}" MATCHES "[\*\+\?]" )
    MESSAGE( WARNING "Some packages may have issues with special characters (build path)" )
ENDIF()
IF ( "${CMAKE_INSTALL_PREFIX}" MATCHES "[\*\+\?]" )
    MESSAGE( WARNING "Some packages may have issues with special characters (install path)" )
ENDIF()
INCLUDE_DIRECTORIES( "${CMAKE_INSTALL_PREFIX}" )
MESSAGE("Installing TPLs in: ${CMAKE_INSTALL_PREFIX}")


# Enable the desired languages
IF ( NOT LANGUAGES )
    SET( LANGUAGES "C" "CXX" "Fortran" )
ENDIF()
STRING( REPLACE "," ";" LANGUAGES "${LANGUAGES}" )
FOREACH( lang ${LANGUAGES} )
    IF ( NOT DISABLE_${lang} )
        ENABLE_LANGUAGE( ${lang} )
    ENDIF()
ENDFOREACH()


# Include CMake files
INCLUDE(ExternalProject)
INCLUDE(macros.cmake)
INCLUDE(GNUInstallDirs)
NULL_USE( USE_MATLAB MATLAB_DIRECTORY BOOST_SRC_DIR BLAS_LIB LAPACK_LIB )


# Set the system name
IF (CMAKE_SIZEOF_VOID_P MATCHES 8) 
    SET( SYSTEM_NAME "${CMAKE_SYSTEM_NAME}_64" ) 
ELSE()
    SET( SYSTEM_NAME "${CMAKE_SYSTEM_NAME}_32" ) 
ENDIF() 


# Set the default compiler flags
SET_COMPILER_DEFAULTS()


# Configure MPI
CONFIGURE_MPI()


# Configure CUDA / HIP
CONFIGURE_CUDA()
CONFIGURE_HIP()


# Configure OpenMP
CHECK_ENABLE_FLAG( USE_OPENMP 0 )
IF ( USE_OPENMP )
    ADD_DEFINITIONS( -DUSE_OPENMP )
    FIND_PACKAGE( OpenMP )
    SET( CMAKE_C_FLAGS "${CMAKE_C_FLAGS} ${OpenMP_C_FLAGS}" )
    SET( CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} ${OpenMP_CXX_FLAGS}" )
# The next line should be uncommented if the correct openmp flags are not added    
#    SET( CMAKE_CXX_FLAGS ${CMAKE_CXX_FLAGS} "-Wno-unused-parameter -fopenmp" )
    SET( CMAKE_Fortran_FLAGS "${CMAKE_Fortran_FLAGS} ${OpenMP_Fortran_FLAGS}" )
ENDIF()


# SET the global compile and link flags
SET_CMAKE_ARGS()


# Set TPL list
IF ( NOT DEFINED TPL_LIST )
    SET( TPL_LIST "LAPACK;ZLIB;PETSC;HDF5;HYPRE;SAMRAI" )
ENDIF()
STRING( REPLACE "," ";" TPL_LIST "${TPL_LIST}" )


# Add KOKKOS if needed
LIST( FIND TPL_LIST "TRILINOS" index_trilinos )
LIST( FIND TPL_LIST "KOKKOS" index_kokkos )
IF ( ${index_trilinos} GREATER -1 )
    SET( TRILINOS_KOKKOS TRUE )
ENDIF()
IF ( ${index_trilinos} GREATER -1 AND ${index_kokkos} EQUAL -1 )
    STRING( REPLACE "TRILINOS" "KOKKOS;TRILINOS" TPL_LIST "${TPL_LIST}" )
ENDIF()


# Disable LTO for certain configurations
IF ( ";${TPL_LIST};" MATCHES ";MATLAB;" )
    SET( DISABLE_LTO TRUE )
ENDIF()


# Set TPL defaults
SET_DEFAULT_TPL( ZLIB  URL http://zlib.net/zlib-1.2.11.tar.gz )
SET_DEFAULT_TPL( HDF5  URL https://bitbucket.org/AdvancedMultiPhysics/tpl-builder/downloads/hdf5-1.12.0.tar.gz  )
SET_DEFAULT_TPL( HYPRE URL https://bitbucket.org/AdvancedMultiPhysics/tpl-builder/downloads/hypre-2.30.0.tar.gz )
SET_DEFAULT_TPL( PETSC URL https://bitbucket.org/AdvancedMultiPhysics/tpl-builder/downloads/petsc-3.20.0.tar.gz )


# Copy cmake files to install dir
FILE( COPY cmake/macros.cmake           DESTINATION "${CMAKE_INSTALL_PREFIX}/cmake" )
FILE( COPY cmake/WriteRepoVersion.cmake DESTINATION "${CMAKE_INSTALL_PREFIX}/cmake" )
FILE( COPY cmake/dummyTimer             DESTINATION "${CMAKE_INSTALL_PREFIX}/cmake" )


# Set the version information
SET( TPLs_VERSION 3.0.0 )


# Create a FindTPLs.cmake file for subsequent projects that sets the compilers,
#    TPLs, links commands, and provides a macros file with additional cmake functions
SET( FIND_TPLS_CMAKE "${CMAKE_CURRENT_BINARY_DIR}/TPLs.cmake.in" )
SET( PACKAGE_INIT "@PACKAGE_INIT@" )
CONFIGURE_FILE( cmake/FindTPLs.header.cmake "${FIND_TPLS_CMAKE}" @ONLY )
IF ( USE_MATLAB )
    MESSAGE( FATAL_ERROR "USE_MATLAB is obsolete, please specify MATLAB as a TPL" )
ENDIF()


# Check test flags
IF ( DEFINED ENABLE_TESTS )
    MESSAGE( WARNING "ENABLE_TESTS is deprecated, use PACKAGE_ENABLE_TESTS, ENABLE_ALL_TESTS, DISABLE_TPL_TESTS, or DISABLE_ALL_TESTS" )
ENDIF()
CHECK_ENABLE_FLAG( ENABLE_ALL_TESTS FALSE )
CHECK_ENABLE_FLAG( DISABLE_TPL_TESTS FALSE )
CHECK_ENABLE_FLAG( DISABLE_ALL_TESTS FALSE )


# Configure TPLs
ADD_CUSTOM_TARGET( logs ALL )
FOREACH( TPL ${TPL_LIST} )
    CONFIGURE_TPL( ${TPL} )
ENDFOREACH()


# Add build-test target to print results of build process
ENABLE_TESTING()
INCLUDE(CTest)
ADD_TEST( echo-build ${CMAKE_COMMAND} -P "${CMAKE_CURRENT_SOURCE_DIR}/cmake/echo_last_build.cmake" )
SET_TESTS_PROPERTIES( echo-build PROPERTIES WORKING_DIRECTORY "${CMAKE_CURRENT_BINARY_DIR}" )
FOREACH( TPL ${TPL_LIST} )
    ADD_BUILD_TEST( ${TPL} )
ENDFOREACH()


# Add distclean
ADD_DISTCLEAN()
ADD_RECONFIGURE()


# Add target to list environment
EXTERNALPROJECT_ADD(
    environment
    DOWNLOAD_COMMAND    ${CMAKE_COMMAND} -E echo "Dummy download"
    CONFIGURE_COMMAND   ${CMAKE_COMMAND} -E echo "Dummy configure"
    BUILD_COMMAND       ${CMAKE_COMMAND} -E echo "Dummy build"
    INSTALL_COMMAND     ${CMAKE_COMMAND} -E environment
    DEPENDS             ${TPL_LIST}
    LOG_DOWNLOAD 0   LOG_UPDATE 0   LOG_CONFIGURE 0   LOG_BUILD 0   LOG_INSTALL 1
)
ADD_TPL_SAVE_LOGS( environment )
ADD_TPL_CLEAN( environment )


# Configure TPL-builder tests
IF ( NOT DISABLE_TPL_TESTS AND NOT DISABLE_ALL_TESTS )
    SET( TPLS_Test_INSTALL_DIR "${CMAKE_INSTALL_PREFIX}/tests" )
    SET( TPLS_Test_DEPENDS ${TPL_LIST} )
    ADD_TPL(
        TPLS_Test
        SOURCE_DIR          "${CMAKE_CURRENT_SOURCE_DIR}/tests"
        UPDATE_COMMAND      ""
        BUILD_IN_SOURCE     0
        CONFIGURE_ALWAYS
        CMAKE_ARGS          "-DTPL_DIRECTORY=${CMAKE_INSTALL_PREFIX};-DTPL_TEST_DIR=${CMAKE_BINARY_DIR};-DINSTALL_DIR=${TPLS_Test_INSTALL_DIR}"
        BUILD_COMMAND       $(MAKE) install
        INSTALL_DIR         "${TPLS_Test_INSTALL_DIR}"
        TEST_COMMAND        ${CMAKE_CTEST_COMMAND}
        LOG_DOWNLOAD 1   LOG_UPDATE 1   LOG_CONFIGURE 1   LOG_BUILD 1   LOG_TEST 1   LOG_INSTALL 1
    )
ENDIF()


# Add the timer if it is not installed
IF ( NOT TIMER_INSTALL_DIR )
    FILE( APPEND "${FIND_TPLS_CMAKE}" "\n# Find TIMER\n" )
    FILE( APPEND "${FIND_TPLS_CMAKE}" "FIND_PACKAGE( Timer REQUIRED PATHS \"${CMAKE_INSTALL_PREFIX}/cmake/dummyTimer\" )\n" )
    FILE( APPEND "${FIND_TPLS_CMAKE}" "SET( TPLs_TIMER_FOUND FALSE )\n" )
    FILE( APPEND "${FIND_TPLS_CMAKE}" "SET( TIMER_FOUND TRUE )\n\n\n" )
ENDIF()


# Add final lines to TPLs.cmake.in
FILE( READ "${CMAKE_CURRENT_SOURCE_DIR}/cmake/FindTPLs.footer.cmake" TPL_FOOTER )
FILE( APPEND "${FIND_TPLS_CMAKE}" "${TPL_FOOTER}" )


# Generate a Package Configuration File
INCLUDE( CMakePackageConfigHelpers )
SET( SYSCONFIG_INSTALL_DIR ${TPL_INSTALL_DIR} CACHE PATH "Location of configuration files" )
CONFIGURE_PACKAGE_CONFIG_FILE( "${FIND_TPLS_CMAKE}"
    ${TPL_INSTALL_DIR}/TPLsConfig.cmake
    INSTALL_DESTINATION "${TPL_INSTALL_DIR}"
    PATH_VARS SYSCONFIG_INSTALL_DIR )
WRITE_BASIC_PACKAGE_VERSION_FILE(
    ${TPL_INSTALL_DIR}/TPLsVersion.cmake
    VERSION ${TPLs_VERSION}
    COMPATIBILITY SameMajorVersion )


# Copy cmake files for cppcheck and cppclean
CONFIGURE_FILE( ${CMAKE_CURRENT_SOURCE_DIR}/cmake/FindCppcheck.cmake "${CMAKE_INSTALL_PREFIX}/cmake/FindCppcheck.cmake" COPYONLY )
CONFIGURE_FILE( ${CMAKE_CURRENT_SOURCE_DIR}/cmake/run.cppclean.template.cmake "${CMAKE_INSTALL_PREFIX}/cmake/run.cppclean.template.cmake" COPYONLY )
CONFIGURE_FILE( ${CMAKE_CURRENT_SOURCE_DIR}/cmake/FindCppclean.cmake "${CMAKE_INSTALL_PREFIX}/cmake/FindCppclean.cmake" COPYONLY )
CONFIGURE_FILE( ${CMAKE_CURRENT_SOURCE_DIR}/cmake/FindCoverage.cmake "${CMAKE_INSTALL_PREFIX}/cmake/FindCoverage.cmake" COPYONLY )


# Create a default resource file
SET( RESOURCE_FILE "${CMAKE_INSTALL_PREFIX}/resources.json" )
FILE( WRITE  "${RESOURCE_FILE}" "{\n" )
FILE( APPEND "${RESOURCE_FILE}" "  \"version\": {\n" )
FILE( APPEND "${RESOURCE_FILE}" "  \"major\": 1,\n" )
FILE( APPEND "${RESOURCE_FILE}" "  \"minor\": 0\n" )
FILE( APPEND "${RESOURCE_FILE}" "  },\n" )
FILE( APPEND "${RESOURCE_FILE}" "  \"local\": [\n" )
FILE( APPEND "${RESOURCE_FILE}" "    {\n" )
FILE( APPEND "${RESOURCE_FILE}" "      \"gpus\": [\n" )
FILE( APPEND "${RESOURCE_FILE}" "        {\n" )
FILE( APPEND "${RESOURCE_FILE}" "          \"id\": \"1\",\n" )
FILE( APPEND "${RESOURCE_FILE}" "          \"slots\": 1\n" )
FILE( APPEND "${RESOURCE_FILE}" "        }\n" )
IF ( "${NUMBER_OF_GPUS}" GREATER 1 )
    FOREACH( id RANGE 2 ${NUMBER_OF_GPUS} )
        FILE( APPEND "${RESOURCE_FILE}" "        ,{\n" )
        FILE( APPEND "${RESOURCE_FILE}" "          \"id\": \"${id}\",\n" )
        FILE( APPEND "${RESOURCE_FILE}" "          \"slots\": 1\n" )
        FILE( APPEND "${RESOURCE_FILE}" "        }\n" )
    ENDFOREACH()
ENDIF()
FILE( APPEND "${RESOURCE_FILE}" "      ]\n" )
FILE( APPEND "${RESOURCE_FILE}" "    }\n" )
FILE( APPEND "${RESOURCE_FILE}" "  ]\n" )
FILE( APPEND "${RESOURCE_FILE}" "}\n" )


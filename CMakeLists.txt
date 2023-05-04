# Set some CMake properties
CMAKE_MINIMUM_REQUIRED( VERSION 3.9 )
IF ( ${CMAKE_VERSION} VERSION_GREATER_EQUAL "3.24.0")
CMAKE_POLICY( SET CMP0135 OLD )
ENDIF()


MESSAGE("================")
MESSAGE("Configuring TPLS")
MESSAGE("================")


# Check if we are asking for help
IF ( HELP )
    UNSET( HELP CACHE )
    FILE(READ README.txt TMP )
    MESSAGE("")
    MESSAGE("${TMP}")
    MESSAGE(FATAL_ERROR)
ENDIF()


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
INCLUDE_DIRECTORIES( "${CMAKE_INSTALL_PREFIX}" )
MESSAGE("Installing TPLs in: ${CMAKE_INSTALL_PREFIX}")


# Enable the desired languages
IF ( LANGUAGES )
    STRING( REPLACE "," ";" LANGUAGES "${LANGUAGES}" )
    FOREACH( lang ${LANGUAGES} )
        ENABLE_LANGUAGE(${lang})
    ENDFOREACH()
ELSE()
    ENABLE_LANGUAGE(C)
    ENABLE_LANGUAGE(CXX)
    ENABLE_LANGUAGE(Fortran)
ENDIF()


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
CHECK_ENABLE_FLAG( USE_MPI 1 )
MESSAGE("MPIEXEC = ${MPIEXEC}")
IF ( USE_MPI )
    MESSAGE( "Configuring MPI" )
    IF ( MPIEXEC )
        SET( MPIEXEC_EXECUTABLE ${MPIEXEC} )
    ENDIF()
    IF ( NOT MPI_SKIP_SEARCH )
        FIND_PACKAGE( MPI )
    ELSE()
        # Write mpi test
        SET( MPI_TEST_SRC "${CMAKE_CURRENT_BINARY_DIR}/test_mpi.cpp" )
        FILE(WRITE  ${MPI_TEST_SRC} "#include <mpi.h>\n" )
        FILE(APPEND ${MPI_TEST_SRC} "int main(int argc, char** argv) {\n" )
        FILE(APPEND ${MPI_TEST_SRC} "    MPI_Init(NULL, NULL);\n")
        FILE(APPEND ${MPI_TEST_SRC} "    MPI_Finalize();\n" )
        FILE(APPEND ${MPI_TEST_SRC} "}\n" )
        # Test the compile
        FOREACH ( tmp C CXX Fortran )
            IF ( CMAKE_${tmp}_COMPILER )
                SET( TMP_FLAGS -DINCLUDE_DIRECTORIES=${MPI_CXX_INCLUDE_PATH} )
                TRY_COMPILE( MPI_TEST_${tmp} ${CMAKE_CURRENT_BINARY_DIR} ${MPI_TEST_SRC}
                    CMAKE_FLAGS ${TMP_FLAGS}
                    LINK_OPTIONS ${MPI_CXX_LINK_FLAGS}
                    LINK_LIBRARIES ${MPI_CXX_LIBRARIES}
                    OUTPUT_VARIABLE OUT_TXT)
                IF ( NOT ${MPI_TEST} )
                    MESSAGE( FATAL_ERROR "Skipping MPI search and default compile fails:\n${OUT_TXT}" )
                ENDIF()
                SET( MPI_C_FOUND TRUE )
                SET( MPI_CXX_FOUND TRUE )
                SET( MPI_Fortran_FOUND TRUE )
            ENDIF()
        ENDFOREACH()
    ENDIF()
    SET( MPI_LANG C CXX Fortran )
    FOREACH( tmp ${MPI_LANG} )
        STRING( STRIP "${MPI_${tmp}_COMPILE_FLAGS}" MPI_${tmp}_COMPILE_FLAGS )
        STRING( STRIP "${MPI_${tmp}_LINK_FLAGS}" MPI_${tmp}_LINK_FLAGS )
        STRING( STRIP "${MPI_${tmp}_LIBRARIES}" MPI_${tmp}_LIBRARIES )
        MESSAGE( "   MPI_${tmp}_FOUND = ${MPI_${tmp}_FOUND}" )
        MESSAGE( "   MPI_${tmp}_COMPILER = ${MPI_${tmp}_COMPILER}" )
        MESSAGE( "   MPI_${tmp}_COMPILE_FLAGS = ${MPI_${tmp}_COMPILE_FLAGS}" )
        MESSAGE( "   MPI_${tmp}_INCLUDE_DIRS = ${MPI_${tmp}_INCLUDE_DIRS}" )
        MESSAGE( "   MPI_${tmp}_LINK_FLAGS = ${MPI_${tmp}_LINK_FLAGS}" )
        MESSAGE( "   MPI_${tmp}_LIBRARIES = ${MPI_${tmp}_LIBRARIES}" )
    ENDFOREACH()
    MESSAGE( "   MPIEXEC = ${MPIEXEC}" )
    MESSAGE( "   MPIEXEC_NUMPROC_FLAG = ${MPIEXEC_NUMPROC_FLAG}" )
    MESSAGE( "   MPIEXEC_PREFLAGS = ${MPIEXEC_PREFLAGS}" )
    MESSAGE( "   MPIEXEC_POSTFLAGS = ${MPIEXEC_POSTFLAGS}" )
    IF ( NOT MPI_C_FOUND AND NOT MPI_CXX_FOUND AND NOT MPI_Fortran_FOUND )
        MESSAGE( FATAL_ERROR "MPI not found" )
    ENDIF()
ENDIF()
IF ( USE_MPI AND NOT MPIEXEC )
    MESSAGE( FATAL_ERROR "Unable to find MPIEXEC, please set it before continuing" )
ENDIF()


# Configure CUDA
CHECK_ENABLE_FLAG( USE_CUDA FALSE )
# Set CUDA standard (always required in case down-stream packages enable CUDA)
IF ( NOT DEFINED CMAKE_CUDA_STANDARD )
    IF ( (${CXX_STD} STREQUAL "98") OR (${CXX_STD} STREQUAL "03") )
        SET( CMAKE_CUDA_STANDARD 03 )
    ELSEIF ( ${CXX_STD} STREQUAL "11" )
        SET( CMAKE_CUDA_STANDARD 11 )
    ELSEIF ( ${CXX_STD} STREQUAL "14" )
        SET( CMAKE_CUDA_STANDARD 14 )
    ELSEIF ( ( ${CXX_STD} STREQUAL "17" ) OR ( ${CXX_STD} STREQUAL "20" ) OR ( ${CXX_STD} STREQUAL "23" ) )
        SET( CMAKE_CUDA_STANDARD 17 )
    ELSE()
        MESSAGE( FATAL_ERROR "Unknown C++ standard" )
    ENDIF()
ENDIF()
# Find and configure CUDA
IF ( USE_CUDA )
    ADD_DEFINITIONS( -DUSE_CUDA )
    IF ( ${CMAKE_VERSION} VERSION_LESS "3.17" )
        MESSAGE( FATAL_ERROR "We require CMake 3.17 or newer when compiling with CUDA" )
    ENDIF()
    ENABLE_LANGUAGE( CUDA )
    IF ( NOT DEFINED CUDA_HOME )
        GET_FILENAME_COMPONENT( CUDA_HOME "${CMAKE_CUDA_COMPILER}" DIRECTORY )
        GET_FILENAME_COMPONENT( CUDA_HOME "${CUDA_HOME}/.." REALPATH )
        MESSAGE( "CUDA_HOME = ${CUDA_HOME}")
    ENDIF()
    IF ( NOT DEFINED CUDA_ARCH_FLAGS )
        FOREACH ( arch ${CMAKE_CUDA_ARCHITECTURES} )
            SET( CUDA_ARCH_FLAGS ${CUDA_ARCH_FLAGS} sm_${arch} )
        ENDFOREACH()
        SET( CUDA_ARCH_FLAGS "${CUDA_ARCH_FLAGS}" )
    ENDIF()
    SET( CMAKE_CUDA_STANDARD_REQUIRED ON )
    SET( CMAKE_CUDA_FLAGS "${CMAKE_CUDA_FLAGS} ${CUDA_FLAGS_EXTRA}" )
    IF ( USE_OPENMP )
       SET( CMAKE_CUDA_FLAGS "${CMAKE_CUDA_FLAGS} -Xcompiler -fopenmp" )
    ENDIF()
    IF ( USE_MPI )
        SET( MPI_CUDA_INCLUDE_DIRS ${MPI_CXX_INCLUDE_DIRS} )
        IF ( NOT MPI_CUDA_INCLUDE_DIRS )
            EXECUTE_PROCESS( COMMAND ${CMAKE_C_COMPILER} -show OUTPUT_VARIABLE MPI_SHOW ERROR_VARIABLE MPI_SHOW )
            STRING( REGEX MATCHALL "\-I[^ ]*" MPI_CUDA_INCLUDE_DIRS ${MPI_SHOW} )
            STRING( REPLACE "-I" "" MPI_CUDA_INCLUDE_DIRS "${MPI_CUDA_INCLUDE_DIRS}" )
        ENDIF()
        MESSAGE( "MPI_CUDA_INCLUDE_DIRS=${MPI_CUDA_INCLUDE_DIRS}" )
        FOREACH( tmp ${MPI_CUDA_INCLUDE_DIRS} )
            SET( CMAKE_CUDA_FLAGS "${CMAKE_CUDA_FLAGS} -I${tmp}" )
        ENDFOREACH()
    ENDIF()
    # Detect the number of GPUs available
    IF ( NOT DEFINED NUMBER_OF_GPUS )
        TRY_RUN( RUN_RESULT_VAR COMPILE_RESULT_VAR
            ${CMAKE_BINARY_DIR} 
            ${CMAKE_CURRENT_SOURCE_DIR}/cmake/FindCudaGPUs.cu
            CMAKE_FLAGS 
                -DINCLUDE_DIRECTORIES:STRING=${CUDA_TOOLKIT_INCLUDE}
                -DLINK_LIBRARIES:STRING=${CUDA_CUDART_LIBRARY}
            COMPILE_OUTPUT_VARIABLE COMPILE_OUTPUT
            RUN_OUTPUT_VARIABLE NUMBER_OF_GPUS )
        IF ( NOT NUMBER_OF_GPUS )
            MESSAGE( FATAL_ERROR "NUMBER_OF_GPUS was not set and not CUDA capable GPUs were detected:\n${COMPILE_OUTPUT}" )
        ENDIF()
        MATH( EXPR NUMBER_OF_GPUS ${NUMBER_OF_GPUS} )
        MESSAGE( "Number of GPUs detected: ${NUMBER_OF_GPUS}" )
    ENDIF()
ELSE()
  SET( NUMBER_OF_GPUS 0 )
ENDIF()


# Configure OpenMP
CHECK_ENABLE_FLAG( USE_OPENMP 0 )
IF ( USE_OPENMP )
    ADD_DEFINITIONS( -DUSE_OPENMP )
    FIND_PACKAGE( OpenMP )
    SET( CMAKE_C_FLAGS "${CMAKE_C_FLAGS} ${OpenMP_C_FLAGS}" )
    SET( CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} ${OpenMP_CXX_FLAGS}" )
    SET( CMAKE_Fortran_FLAGS "${CMAKE_Fortran_FLAGS} ${OpenMP_Fortran_FLAGS}" )
ENDIF()


# SET the global compile and link flags
SET_CMAKE_ARGS()


# Set TPL list
IF ( NOT DEFINED TPL_LIST )
    SET( TPL_LIST "LAPACK;ZLIB;PETSC;HDF5;HYPRE;SAMRAI" )
ENDIF()
STRING( REPLACE "," ";" TPL_LIST "${TPL_LIST}" )


# Add the StackTrace
IF ( NOT DISABLE_STACKTRACE OR "${CXX_STD}" LESS "14" )
    IF ( ";${TPL_LIST};" MATCHES ";TIMER;" )
        STRING( REPLACE ";TIMER;" ";TIMER;STACKTRACE;" TPL_LIST "?;${TPL_LIST};?" )
        STRING( REPLACE "?;" "" TPL_LIST "${TPL_LIST}" )
        STRING( REPLACE ";?" "" TPL_LIST "${TPL_LIST}" )
    ELSE()
        SET( TPL_LIST "STACKTRACE;${TPL_LIST}" )
    ENDIF()
ENDIF()
MESSAGE("TPL_LIST=${TPL_LIST}")

# Add the lapack wrappers
IF ( ";${TPL_LIST};" MATCHES ";LAPACK;" )
    STRING( REPLACE ";LAPACK;" ";LAPACK;LAPACK_WRAPPERS;" TPL_LIST "?;${TPL_LIST};?" )
    STRING( REPLACE "?;" "" TPL_LIST "${TPL_LIST}" )
    STRING( REPLACE ";?" "" TPL_LIST "${TPL_LIST}" )
ELSEIF ( ";${TPL_LIST};" MATCHES ";OPENBLAS;" )
    STRING( REPLACE ";OPENBLAS;" ";OPENBLAS;LAPACK;LAPACK_WRAPPERS;" TPL_LIST "?;${TPL_LIST};?" )
    STRING( REPLACE "?;" "" TPL_LIST "${TPL_LIST}" )
    STRING( REPLACE ";?" "" TPL_LIST "${TPL_LIST}" )
ELSE()
    SET( TPL_LIST "LAPACK_WRAPPERS;${TPL_LIST}" )
ENDIF()
MESSAGE( "TPL_LIST = ${TPL_LIST}" )


# Disable LTO for certain configurations
IF ( ";${TPL_LIST};" MATCHES ";MATLAB;" )
    SET( DISABLE_LTO TRUE )
ENDIF()


# Set TPL defaults
SET_DEFAULT_TPL( ZLIB  URL http://zlib.net/zlib-1.2.11.tar.gz )
SET_DEFAULT_TPL( HDF5  URL https://bitbucket.org/AdvancedMultiPhysics/tpl-builder/downloads/hdf5-1.8.12.tar.gz  )
SET_DEFAULT_TPL( HYPRE URL https://bitbucket.org/AdvancedMultiPhysics/tpl-builder/downloads/hypre-2.18.2.tar.gz )
SET_DEFAULT_TPL( PETSC URL https://bitbucket.org/AdvancedMultiPhysics/tpl-builder/downloads/petsc-3.13.0.tar.gz )


# Copy cmake files to install dir
CONFIGURE_FILE( cmake/macros.cmake "${CMAKE_INSTALL_PREFIX}/cmake/macros.cmake" COPYONLY )
CONFIGURE_FILE( cmake/WriteRepoVersion.cmake "${CMAKE_INSTALL_PREFIX}/cmake/WriteRepoVersion.cmake" COPYONLY )


# Create a FindTPLs.cmake file for subsequent projects that sets the compilers,
#    TPLs, links commands, and provides a macros file with additional cmake functions
SET( FIND_TPLS_CMAKE "${CMAKE_INSTALL_PREFIX}/FindTPLs.cmake" )
CONFIGURE_FILE( cmake/FindTPLs.template.cmake "${FIND_TPLS_CMAKE}" @ONLY )
IF ( USE_MATLAB )
    MESSAGE( FATAL_ERROR "USE_MATLAB is obsolete, please specify MATLAB as a TPL" )
ENDIF()


# Check test flags
IF ( DEFINED ENABLE_TESTS )
    MESSAGE( WARNING "ENABLE_TESTS is depricated, use PACKAGE_ENABLE_TESTS, ENABLE_ALL_TESTS, DISABLE_TPL_TESTS, or DISABLE_ALL_TESTS" )
ENDIF()
CHECK_ENABLE_FLAG( ENABLE_ALL_TESTS FALSE )
CHECK_ENABLE_FLAG( DISABLE_TPL_TESTS FALSE )
CHECK_ENABLE_FLAG( DISABLE_ALL_TESTS FALSE )


# Configure TPLs
ADD_CUSTOM_TARGET( logs ALL )
FOREACH( TPL ${TPL_LIST} )
    MESSAGE("Configuring ${TPL}")
    INCLUDE(TPLs/${TPL}.cmake)
    SET( ${TPL_LIST}_ENABLE true )
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
        DEPENDS             ${TPL_LIST}
        LOG_DOWNLOAD 1   LOG_UPDATE 1   LOG_CONFIGURE 1   LOG_BUILD 1   LOG_TEST 1   LOG_INSTALL 1
    )
ENDIF()

### Add final lines to FindTPLs.cmake

# Add the timer if it is not installed
IF ( NOT TIMER_INSTALL_DIR )
    CONFIGURE_FILE( ${CMAKE_CURRENT_SOURCE_DIR}/cmake/FindTimer.cmake "${CMAKE_INSTALL_PREFIX}/cmake/FindTimer.cmake" COPYONLY )
    FILE( APPEND "${FIND_TPLS_CMAKE}" "# Configure timer\n" )
    FILE( APPEND "${FIND_TPLS_CMAKE}" "INCLUDE( \"${CMAKE_INSTALL_PREFIX}/cmake/FindTimer.cmake\" )\n" )
    FILE( APPEND "${FIND_TPLS_CMAKE}" "CONFIGURE_TIMER( FALSE \"$\{$\{PROJ}_INSTALL_DIR}/include\" TRUE )\n\n" )
ENDIF()

# Add a check to the FindTPLs.cmake to ensure all TPLs were found
FILE( APPEND "${FIND_TPLS_CMAKE}" "\n\n# Check that all desired TPLs were found\n" )
FILE( APPEND "${FIND_TPLS_CMAKE}" "FOREACH ( tmp $\{TPL_LIST} )\n" )
FILE( APPEND "${FIND_TPLS_CMAKE}" "    IF ( NOT TPL_FOUND_$\{tmp} AND TPLs_FIND_$\{tmp} )\n" )
FILE( APPEND "${FIND_TPLS_CMAKE}" "        IF ( TPLs_FIND_REQUIRED_$\{tmp} )\n" )
FILE( APPEND "${FIND_TPLS_CMAKE}" "            MESSAGE( ERROR \"$\{tmp} not found\" )\n" )
FILE( APPEND "${FIND_TPLS_CMAKE}" "        ELSE()\n" )
FILE( APPEND "${FIND_TPLS_CMAKE}" "            MESSAGE( \"  $\{tmp} not found\" )\n" )
FILE( APPEND "${FIND_TPLS_CMAKE}" "        ENDIF()\n" )
FILE( APPEND "${FIND_TPLS_CMAKE}" "    ENDIF()\n" )
FILE( APPEND "${FIND_TPLS_CMAKE}" "ENDFOREACH()\n" )

# Get the list of found TPLs
FILE( APPEND "${FIND_TPLS_CMAKE}" "SET( TPL_LIST_FOUND )\n" )
FILE( APPEND "${FIND_TPLS_CMAKE}" "FOREACH( tmp $\{TPL_LIST} )\n" )
FILE( APPEND "${FIND_TPLS_CMAKE}" "    IF ( TPL_FOUND_$\{tmp} )\n" )
FILE( APPEND "${FIND_TPLS_CMAKE}" "        SET( TPL_LIST_FOUND $\{TPL_LIST_FOUND} $\{tmp} )\n" )
FILE( APPEND "${FIND_TPLS_CMAKE}" "    ENDIF()\n" )
FILE( APPEND "${FIND_TPLS_CMAKE}" "ENDFOREACH()\n" )

# Write the TPLs.h file for the TPLs we included 
FILE( APPEND "${FIND_TPLS_CMAKE}" "\n\n# Write the TPLs.h\n" )
FILE( APPEND "${FIND_TPLS_CMAKE}" "SET( TPLs_HEADER \"$\{CMAKE_CURRENT_BINARY_DIR}/tmp/TPLs.h\" )\n" )
FILE( APPEND "${FIND_TPLS_CMAKE}" "FILE( WRITE \"$\{TPLs_HEADER}\" \"// This file sets the TPL list for C/C++ codes\\n\")\n" )
FILE( APPEND "${FIND_TPLS_CMAKE}" "FILE( APPEND \"$\{TPLs_HEADER}\" \"#ifndef TPL_LIST\\n\")\n" )
FILE( APPEND "${FIND_TPLS_CMAKE}" "FILE( APPEND \"$\{TPLs_HEADER}\" \"#define TPL_LIST \\\"$\{TPL_LIST}\\\"\\n\")\n")
FILE( APPEND "${FIND_TPLS_CMAKE}" "FILE( APPEND \"$\{TPLs_HEADER}\" \"#endif\\n\")\n" )
FILE( APPEND "${FIND_TPLS_CMAKE}" "FILE( APPEND \"$\{TPLs_HEADER}\" \"#ifndef $\{PROJ}_TPL_LIST\\n\")\n" )
FILE( APPEND "${FIND_TPLS_CMAKE}" "FILE( APPEND \"$\{TPLs_HEADER}\" \"#define $\{PROJ}_TPL_LIST \\\"$\{TPL_LIST_FOUND}\\\"\\n\")\n")
FILE( APPEND "${FIND_TPLS_CMAKE}" "FOREACH( TPL $\{TPL_LIST} )\n" )
FILE( APPEND "${FIND_TPLS_CMAKE}" "    IF ( TPL_FOUND_$\{TPL} )\n" )
FILE( APPEND "${FIND_TPLS_CMAKE}" "        SET( USE_$\{TPL} TRUE )\n" )
FILE( APPEND "${FIND_TPLS_CMAKE}" "        FILE( APPEND \"$\{TPLs_HEADER}\" \"#define $\{PROJ}_USE_$\{TPL}\\n\")\n" )
FILE( APPEND "${FIND_TPLS_CMAKE}" "        FOREACH( tmp $\{$\{TPL}_PACKAGE_LIST} )\n" )
FILE( APPEND "${FIND_TPLS_CMAKE}" "             STRING(TOUPPER $\{tmp} tmp)\n")
FILE( APPEND "${FIND_TPLS_CMAKE}" "             FILE( APPEND \"$\{TPLs_HEADER}\" \"#define $\{PROJ}_USE_$\{TPL}_$\{tmp}\\n\")\n" )
FILE( APPEND "${FIND_TPLS_CMAKE}" "        ENDFOREACH()\n" )
FILE( APPEND "${FIND_TPLS_CMAKE}" "    ENDIF()\n" )
FILE( APPEND "${FIND_TPLS_CMAKE}" "ENDFOREACH()\n" )
FILE( APPEND "${FIND_TPLS_CMAKE}" "FILE( APPEND \"$\{TPLs_HEADER}\" \"#endif\\n\")\n" )
FILE( APPEND "${FIND_TPLS_CMAKE}" "EXECUTE_PROCESS( COMMAND $\{CMAKE_COMMAND} -E copy_if_different \"$\{TPLs_HEADER}\" \"$\{$\{PROJ}_INSTALL_DIR}/include/$\{$\{PROJ}_INC}/$\{PROJ}_TPLs.h\" )\n" )


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


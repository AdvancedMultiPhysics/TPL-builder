# Set some CMake properties
CMAKE_MINIMUM_REQUIRED( VERSION 3.9 )


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
SET_N_PROCS()
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
    FIND_PACKAGE( MPI )
    SET( MPI_LANG C CXX Fortran )
    FOREACH( tmp ${MPI_LANG} )
        STRING( STRIP "${MPI_${tmp}_COMPILE_FLAGS}" MPI_${tmp}_COMPILE_FLAGS )
        STRING( STRIP "${MPI_${tmp}_LINK_FLAGS}" MPI_${tmp}_LINK_FLAGS )
        STRING( STRIP "${MPI_${tmp}_LIBRARIES}" MPI_${tmp}_LIBRARIES )
        MESSAGE( "   MPI_${tmp}_FOUND = ${MPI_${tmp}_FOUND}" )
        MESSAGE( "   MPI_${tmp}_COMPILER = ${MPI_${tmp}_COMPILER}" )
        MESSAGE( "   MPI_${tmp}_COMPILE_FLAGS = ${MPI_${tmp}_COMPILE_FLAGS}" )
        MESSAGE( "   MPI_${tmp}_INCLUDE_PATH = ${MPI_${tmp}_INCLUDE_PATH}" )
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
CHECK_ENABLE_FLAG( USE_CUDA 0 )
IF ( USE_CUDA )
    IF ( ${CMAKE_VERSION} VERSION_LESS "3.17" )
        MESSAGE( FATAL_ERROR "We require CMake 3.17 or newer when compiling with CUDA" )
    ENDIF()
    ADD_DEFINITIONS( -DUSE_CUDA )
    ENABLE_LANGUAGE( CUDA )
    IF ( NOT DEFINED CMAKE_CUDA_STANDARD )
        IF ( (${CXX_STD} STREQUAL "98") OR (${CXX_STD} STREQUAL "03") )
            SET( CMAKE_CUDA_STANDARD 03 )
        ELSEIF ( ${CXX_STD} STREQUAL "11" )
            SET( CMAKE_CUDA_STANDARD 11 )
        ELSEIF ( (${CXX_STD} STREQUAL "14") OR (${CXX_STD} STREQUAL "17") )
            SET( CMAKE_CUDA_STANDARD 14 )
        ELSE()
            MESSAGE( FATAL_ERROR "Unknown C++ standard" )
        ENDIF()
    ENDIF()
    SET( CMAKE_CUDA_STANDARD_REQUIRED ON )

    SET( CMAKE_CUDA_FLAGS "${CMAKE_CUDA_FLAGS} ${CUDA_FLAGS_EXTRA}" )
    
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
IF ( NOT TPL_LIST )
    SET( TPL_LIST "LAPACK;ZLIB;PETSC;HDF5;HYPRE;SAMRAI" )
ENDIF()
STRING( REPLACE "," ";" TPL_LIST "${TPL_LIST}" )


# Add the StackTrace
IF ( ";${TPL_LIST};" MATCHES ";TIMER;" )
    STRING( REPLACE ";TIMER;" ";TIMER;STACKTRACE;" TPL_LIST "?;${TPL_LIST};?" )
    STRING( REPLACE "?;" "" TPL_LIST "${TPL_LIST}" )
    STRING( REPLACE ";?" "" TPL_LIST "${TPL_LIST}" )
ELSE()
    SET( TPL_LIST "STACKTRACE;${TPL_LIST}" )
ENDIF()


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

# Run the test project as an external project
CHECK_ENABLE_FLAG( ENABLE_TESTS TRUE )
IF ( ENABLE_TESTS )
    SET( TPLS_Test_INSTALL_DIR "${CMAKE_INSTALL_PREFIX}/tests" )
    CHECK_ENABLE_FLAG( DISABLE_TESTS_AFTER_INSTALL FALSE )
    IF ( DISABLE_TESTS_AFTER_INSTALL )
        EXTERNALPROJECT_ADD(
            TPLS_Test
            SOURCE_DIR          "${CMAKE_CURRENT_SOURCE_DIR}/tests"
            BUILD_IN_SOURCE     0
            CMAKE_ARGS          "-DTPL_DIRECTORY=${CMAKE_INSTALL_PREFIX};-DTPL_TEST_DIR=${CMAKE_BINARY_DIR};-DINSTALL_DIR=${TPLS_Test_INSTALL_DIR}"
            BUILD_COMMAND       ${CMAKE_MAKE_PROGRAM}
            INSTALL_COMMAND     make install
            DEPENDS             ${TPL_LIST}
            LOG_DOWNLOAD 1   LOG_UPDATE 1   LOG_CONFIGURE 1   LOG_BUILD 1   LOG_INSTALL 1
        )
    ELSE()
        EXTERNALPROJECT_ADD(
            TPLS_Test
            SOURCE_DIR          "${CMAKE_CURRENT_SOURCE_DIR}/tests"
            BUILD_IN_SOURCE     0
            CMAKE_ARGS          "-DTPL_DIRECTORY=${CMAKE_INSTALL_PREFIX};-DTPL_TEST_DIR=${CMAKE_BINARY_DIR};-DINSTALL_DIR=${TPLS_Test_INSTALL_DIR}"
            BUILD_COMMAND       ${CMAKE_MAKE_PROGRAM}
            INSTALL_COMMAND     make install
            TEST_AFTER_INSTALL  ${CMAKE_COMMAND} -E echo "Installing"
            TEST_COMMAND        ctest -j ${PROCS_INSTALL} --output-on-failure
            DEPENDS             ${TPL_LIST}
            LOG_DOWNLOAD 1   LOG_UPDATE 1   LOG_CONFIGURE 1   LOG_BUILD 1   LOG_TEST 1   LOG_INSTALL 1
        )
        EXTERNALPROJECT_ADD_STEP(
            TPLS_Test
            post-test
            COMMAND             make log-TPLS_Test
            COMMENT             ""
            DEPENDEES           test
            ALWAYS              0
            LOG                 0
        )
    ENDIF()
    ExternalProject_Add_Step(
        TPLS_Test
        force_reconfigure
        COMMAND ${CMAKE_COMMAND} -E echo "Force configure of libhello"
        DEPENDEES update
        DEPENDERS configure
        ALWAYS 1
    )
    ADD_TPL_SAVE_LOGS( TPLS_Test )
    ADD_TPL_CLEAN( TPLS_Test )
    ADD_BUILD_TEST( TPLS_Test )
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
FILE( APPEND "${FIND_TPLS_CMAKE}" "IF ( NOT TPLs_FIND_QUIETLY )\n" )
FILE( APPEND "${FIND_TPLS_CMAKE}" "MESSAGE(\"TPLs Required: $\{TPL_LIST_REQUIRED}\")\n" )
FILE( APPEND "${FIND_TPLS_CMAKE}" "MESSAGE(\"TPLs Supported: $\{TPL_LIST_OPTIONAL}\")\n" )
FILE( APPEND "${FIND_TPLS_CMAKE}" "MESSAGE(\"TPLs Built: $\{TPL_LIST}\")\n" )
FILE( APPEND "${FIND_TPLS_CMAKE}" "MESSAGE(\"TPLs Included: $\{TPL_LIST_FOUND}\")\n" )
FILE( APPEND "${FIND_TPLS_CMAKE}" "MESSAGE(\"Include Paths: $\{TPL_INCLUDE_DIRS}\")\n" )
FILE( APPEND "${FIND_TPLS_CMAKE}" "MESSAGE(\"Libraries: $\{TPL_LIBRARIES}\")\n" )
FILE( APPEND "${FIND_TPLS_CMAKE}" "ENDIF()\n" )


# Write the TPLs.h file for the TPLs we will 
FILE( APPEND "${FIND_TPLS_CMAKE}" "\n\n# Write the TPLs.h\n" )
FILE( APPEND "${FIND_TPLS_CMAKE}" "SET( TPLs_HEADER \"$\{$\{PROJ}_INSTALL_DIR}/include/$\{$\{PROJ}_INC}/TPLs.h\" )\n" )
FILE( APPEND "${FIND_TPLS_CMAKE}" "FILE( WRITE \"$\{TPLs_HEADER}\" \"// This file sets the TPL list for C/C++ codes\\n\")\n" )
FILE( APPEND "${FIND_TPLS_CMAKE}" "FILE( APPEND \"$\{TPLs_HEADER}\" \"#define TPL_LIST \\\"${TPL_LIST}\\\"\\n\")\n")
FILE( APPEND "${FIND_TPLS_CMAKE}" "FOREACH( TPL $\{TPL_LIST} )\n" )
FILE( APPEND "${FIND_TPLS_CMAKE}" "    IF ( TPL_FOUND_$\{TPL} )\n" )
FILE( APPEND "${FIND_TPLS_CMAKE}" "        SET( USE_$\{TPL} TRUE )\n" )
FILE( APPEND "${FIND_TPLS_CMAKE}" "        ADD_DEFINITIONS( -DUSE_$\{TPL} )\n" )
FILE( APPEND "${FIND_TPLS_CMAKE}" "        FILE( APPEND \"$\{TPLs_HEADER}\" \"#ifndef USE_$\{TPL}\\n\")\n" )
FILE( APPEND "${FIND_TPLS_CMAKE}" "        FILE( APPEND \"$\{TPLs_HEADER}\" \"   #define USE_$\{TPL}\\n\")\n" )
FILE( APPEND "${FIND_TPLS_CMAKE}" "        FILE( APPEND \"$\{TPLs_HEADER}\" \"#endif\\n\")\n" )
FILE( APPEND "${FIND_TPLS_CMAKE}" "    ENDIF()\n" )
FILE( APPEND "${FIND_TPLS_CMAKE}" "ENDFOREACH()\n" )

# Copy cmake files for cppcheck and cppclean
CONFIGURE_FILE( ${CMAKE_CURRENT_SOURCE_DIR}/cmake/FindCppcheck.cmake "${CMAKE_INSTALL_PREFIX}/cmake/FindCppcheck.cmake" COPYONLY )
CONFIGURE_FILE( ${CMAKE_CURRENT_SOURCE_DIR}/cmake/run.cppclean.template.cmake "${CMAKE_INSTALL_PREFIX}/cmake/run.cppclean.template.cmake" COPYONLY )
CONFIGURE_FILE( ${CMAKE_CURRENT_SOURCE_DIR}/cmake/FindCppclean.cmake "${CMAKE_INSTALL_PREFIX}/cmake/FindCppclean.cmake" COPYONLY )
CONFIGURE_FILE( ${CMAKE_CURRENT_SOURCE_DIR}/cmake/FindCoverage.cmake "${CMAKE_INSTALL_PREFIX}/cmake/FindCoverage.cmake" COPYONLY )


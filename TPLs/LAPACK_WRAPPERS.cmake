# This will configure and build lapack wrappers
# User can configure the source path by specifying LAPACK_WRAPPERS_SRC_DIR
#    the download path by specifying LAPACK_WRAPPERS_URL, or the installed 
#    location by specifying LAPACK_WRAPPERS_INSTALL_DIR


# Intialize download/src/install vars
SET( LAPACK_WRAPPERS_SOURCE_DIR "${CMAKE_CURRENT_SOURCE_DIR}/TPLs/LapackWrappers" )
SET( LAPACK_WRAPPERS_INSTALL_DIR "${CMAKE_INSTALL_PREFIX}/LapackWrappers" )
VERIFY_PATH( "${LAPACK_WRAPPERS_SOURCE_DIR}" )

#INCLUDE_DIRECTORIES( "${LAPACK_WRAPPERS_INSTALL_DIR}/include" )
#CONFIGURE_FILE( "${LAPACK_WRAPPERS_SOURCE_DIR}/LapackWrappers.h"
#    "${LAPACK_WRAPPERS_INSTALL_DIR}/include/LapackWrappers.h" COPYONLY )
#CONFIGURE_FILE( "${LAPACK_WRAPPERS_SOURCE_DIR}/LapackWrappers.hpp"
#    "${LAPACK_WRAPPERS_INSTALL_DIR}/include/LapackWrappers.hpp" COPYONLY )
#ADD_LIBRARY( LapackWrappers ${LIB_TYPE} ${SOURCES} 
#    "${LAPACK_WRAPPERS_SOURCE_DIR}/LapackWrappers.cpp" )

# Configure lapack wrappers
EXTERNALPROJECT_ADD(
    LAPACK_WRAPPERS
    URL                 ""
    DOWNLOAD_DIR        ""
    SOURCE_DIR          "${LAPACK_WRAPPERS_SOURCE_DIR}"
    UPDATE_COMMAND      ""
    BUILD_IN_SOURCE     0
    INSTALL_DIR         "${LAPACK_WRAPPERS_INSTALL_DIR}"
    CMAKE_ARGS          "-DTPL_DIRECTORY=${CMAKE_INSTALL_PREFIX};-DINSTALL_DIR=${LAPACK_WRAPPERS_INSTALL_DIR}"
    BUILD_COMMAND       make install -j ${PROCS_INSTALL}  VERBOSE=1
    DEPENDS             LAPACK
    LOG_DOWNLOAD 1   LOG_UPDATE 1   LOG_CONFIGURE 1   LOG_BUILD 1   LOG_TEST 1   LOG_INSTALL 1
)
ADD_TPL_SAVE_LOGS( LAPACK_WRAPPERS )
ADD_TPL_CLEAN( LAPACK_WRAPPERS )


# Add the appropriate fields to FindTPLs.cmake
FILE( APPEND "${FIND_TPLS_CMAKE}" "\n# Find LAPACK_WRAPPERS\n" )
FILE( APPEND "${FIND_TPLS_CMAKE}" "IF ( TPLs_FIND_LAPACK_WRAPPERS AND NOT TPL_FOUND_LAPACK_WRAPPERS )\n" )
FILE( APPEND "${FIND_TPLS_CMAKE}" "    SET( TPL_INCLUDE_DIRS \"${LAPACK_WRAPPERS_SOURCE_DIR}\" $\{TPL_INCLUDE_DIRS} )\n" )
FILE( APPEND "${FIND_TPLS_CMAKE}" "    FIND_LIBRARY( LAPACK_WRAPPERS_LIB  NAMES LapackWrappers PATHS \"${LAPACK_WRAPPERS_INSTALL_DIR}/lib\"  NO_DEFAULT_PATH )\n" )
FILE( APPEND "${FIND_TPLS_CMAKE}" "    IF ( NOT LAPACK_WRAPPERS_LIB )\n" )
FILE( APPEND "${FIND_TPLS_CMAKE}" "        MESSAGE( FATAL_ERROR \"LapackWrappers library not found in ${LAPACK_WRAPPERS_INSTALL_DIR}/lib\" )\n" )
FILE( APPEND "${FIND_TPLS_CMAKE}" "    ENDIF()\n" )
FILE( APPEND "${FIND_TPLS_CMAKE}" "    SET( TPL_LIBRARIES $\{LAPACK_WRAPPERS_LIB} $\{TPL_LIBRARIES} )\n" )
FILE( APPEND "${FIND_TPLS_CMAKE}" "    SET( TPL_FOUND_LAPACK_WRAPPERS TRUE )\n" )
FILE( APPEND "${FIND_TPLS_CMAKE}" "ENDIF()\n" )
FILE( APPEND "${FIND_TPLS_CMAKE}" "\n" )

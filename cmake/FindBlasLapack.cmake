# FindBlasLapack
# ---------
#
# Find blas/lapack libraries 
#
# Use this module by invoking find_package with the form:
#
#   find_package( FindBlasLapack )
#
# This module finds headers and requested component libraries for 
#    different BLAS/LAPACK libraries.
#


# Check the install directory
IF ( NOT LAPACK_INSTALL_DIR )
    MESSAGE( FATAL_ERROR "LAPACK_INSTALL_DIR must be set" )
ENDIF()
IF ( NOT EXISTS "${LAPACK_INSTALL_DIR}" )
    MESSAGE( FATAL_ERROR "Path does not exist: ${LAPACK_INSTALL_DIR}" )
ENDIF()


# Begin search
INCLUDE( cmake/LAPACK_macros.cmake )
SET( BLAS_LAPACK_LINK )
IF ( (NOT BLAS_FOUND) OR (NOT LAPACK_FOUND) )
    CHECK_ACML( "${LAPACK_INSTALL_DIR}" "${LAPACK_OUT}" )
ENDIF()
IF ( (NOT BLAS_FOUND) OR (NOT LAPACK_FOUND) )
    #CHECK_ONEAPI( "${LAPACK_INSTALL_DIR}" "${LAPACK_OUT}" )
ENDIF()
IF ( (NOT BLAS_FOUND) OR (NOT LAPACK_FOUND) )
    CHECK_MKL( "${LAPACK_INSTALL_DIR}" "${LAPACK_OUT}" )
ENDIF()
IF ( (NOT BLAS_FOUND) OR (NOT LAPACK_FOUND) )
    CHECK_VECLIB( "${LAPACK_INSTALL_DIR}" "${LAPACK_OUT}" )
ENDIF()
IF ( (NOT BLAS_FOUND) OR (NOT LAPACK_FOUND) )
    CHECK_CRAY_LIBSCI( "${LAPACK_INSTALL_DIR}" "${LAPACK_OUT}" )
ENDIF()
IF ( (NOT BLAS_FOUND) OR (NOT LAPACK_FOUND) )
    CHECK_OPENBLAS( "${LAPACK_INSTALL_DIR}" "${LAPACK_OUT}" )
ENDIF()
IF ( NOT BLAS_DIR )
    SET( BLAS_DIR "${LAPACK_INSTALL_DIR}" )
ENDIF()
IF ( (NOT BLAS_FOUND) OR (NOT LAPACK_FOUND) )
    IF ( NOT BLAS_FOUND )
        CHECK_BLAS( "${BLAS_DIR}" "${LAPACK_OUT}" )
    ENDIF()
    IF ( NOT LAPACK_FOUND )
        CHECK_LAPACK( "${LAPACK_INSTALL_DIR}" "${LAPACK_OUT}" )
    ENDIF()
    SET( BLAS_LAPACK_LINK "-Wl,--start-group ${BLAS_LIBS} ${LAPACK_LIBS} -Wl,--end-group" )
ENDIF()
IF ( (NOT BLAS_FOUND) OR (NOT LAPACK_FOUND) )
    MESSAGE(FATAL_ERROR "No sutable blas or lapack libraries found in ${LAPACK_INSTALL_DIR}")
ENDIF()


# Check that some variables are set
IF ( NOT LAPACK_VENDOR )
    MESSAGE(FATAL_ERROR "Internal error: LAPACK_VENDOR not set" )
ENDIF()
IF ( NOT BLAS_FOUND )
    MESSAGE(FATAL_ERROR "Internal error: BLAS_FOUND not set" )
ENDIF()
IF ( NOT LAPACK_FOUND )
    MESSAGE(FATAL_ERROR "Internal error: LAPACK_FOUND not set" )
ENDIF()


# Print some variables
MESSAGE( "LAPACK_FOUND: ${LAPACK_FOUND}" )
MESSAGE( "LAPACK_VENDOR: ${LAPACK_VENDOR}" )
MESSAGE( "BLAS_DIR: ${BLAS_DIR}" )
MESSAGE( "LAPACK_DIR: ${LAPACK_DIR}" )
MESSAGE( "BLAS_INCLUDE_DIRS: ${BLAS_INCLUDE_DIRS}" )
MESSAGE( "LAPACK_INCLUDE_DIRS: ${LAPACK_INCLUDE_DIRS}" )
MESSAGE( "BLAS_LIBS ${BLAS_LIBS}" )
MESSAGE( "LAPACK_LIBS: ${LAPACK_LIBS}" )
MESSAGE( "BLAS_LAPACK_LINK: ${BLAS_LAPACK_LINK}" )




# This will configure and build kokkos
# User can configure the source path by specifying MUMPS_SRC_DIR,
#    the download path by specifying MUMPS_URL, or the installed 
#    location by specifying MUMPS_INSTALL_DIR


# Intialize download/src/install vars
SET( MUMPS_BUILD_DIR "${CMAKE_BINARY_DIR}/MUMPS-prefix/src/MUMPS-build" )
IF ( MUMPS_URL ) 
    MESSAGE_TPL("   MUMPS_URL = ${MUMPS_URL}")
    SET( MUMPS_CMAKE_URL            "${MUMPS_URL}"       )
    SET( MUMPS_CMAKE_DOWNLOAD_DIR   "${MUMPS_BUILD_DIR}" )
    SET( MUMPS_CMAKE_SOURCE_DIR     "${MUMPS_BUILD_DIR}" )
    SET( MUMPS_CMAKE_INSTALL_DIR "${CMAKE_INSTALL_PREFIX}/mumps" )
    SET( CMAKE_BUILD_MUMPS TRUE )
ELSEIF ( MUMPS_SRC_DIR )
    VERIFY_PATH("${MUMPS_SRC_DIR}")
    MESSAGE_TPL("   MUMPS_SRC_DIR = ${MUMPS_SRC_DIR}")
    SET( MUMPS_CMAKE_URL            ""   )
    SET( MUMPS_CMAKE_DOWNLOAD_DIR   "" )
    SET( MUMPS_CMAKE_SOURCE_DIR     "${MUMPS_SRC_DIR}" )
    SET( MUMPS_CMAKE_INSTALL_DIR "${CMAKE_INSTALL_PREFIX}/mumps" )
    SET( CMAKE_BUILD_MUMPS TRUE )
ELSEIF ( MUMPS_INSTALL_DIR ) 
    SET( MUMPS_CMAKE_INSTALL_DIR "${MUMPS_INSTALL_DIR}" )
    SET( CMAKE_BUILD_MUMPS FALSE )
ELSE()
    MESSAGE(FATAL_ERROR "Please specify MUMPS_SRC_DIR, MUMPS_URL, or MUMPS_INSTALL_DIR")
ENDIF()
SET( MUMPS_INSTALL_DIR "${MUMPS_CMAKE_INSTALL_DIR}" )
MESSAGE_TPL( "   MUMPS_INSTALL_DIR = ${MUMPS_INSTALL_DIR}" )
FILE( APPEND "${CMAKE_INSTALL_PREFIX}/TPLs.cmake" "SET(MUMPS_INSTALL_DIR \"${MUMPS_INSTALL_DIR}\")\n" )


# Configure mumps
IF ( CMAKE_BUILD_MUMPS )
    # Set variables based on TPLs
    SET( MUMPS_PARALLEL OFF )
    SET( MUMPS_DEPENDENCIES LAPACK )
    IF ( MUMPS_PARALLEL )
        SET( MUMPS_DEPENDENCIES ${MUMPS_DEPENDENCIES} SCALAPACK )
    ENDIF()
    LIST(FIND TPL_LIST "METIS" index)
    IF (${index} GREATER -1)
    ENDIF()
    LIST(FIND TPL_LIST "SCOTCH" index)
    IF (${index} GREATER -1)
    ENDIF()
    # Generate Makefile.inc
    SET( MUMPS_Makefile "${CMAKE_BINARY_DIR}/MUMPS-prefix/src/Makefile.inc" )
    FILE( WRITE  "${MUMPS_Makefile}" "# This file is automatically generated by the TPL builder\n" )
    FILE( APPEND "${MUMPS_Makefile}" "LPORDDIR = $(topdir)/PORD/lib\n" )
    FILE( APPEND "${MUMPS_Makefile}" "IPORD    = -I$(topdir)/PORD/include\n" )
    FILE( APPEND "${MUMPS_Makefile}" "LPORD    = -L$(LPORDDIR) -lpord\n" )
    FILE( APPEND "${MUMPS_Makefile}" "ORDERINGSF  = -Dpord\n" )
    FILE( APPEND "${MUMPS_Makefile}" "ORDERINGSC  = $(ORDERINGSF)\n" )
    FILE( APPEND "${MUMPS_Makefile}" "LORDERINGS = $(LMETIS) $(LPORD) $(LSCOTCH)\n" )
    FILE( APPEND "${MUMPS_Makefile}" "IORDERINGSF = $(ISCOTCH)\n" )
    FILE( APPEND "${MUMPS_Makefile}" "IORDERINGSC = $(IMETIS) $(IPORD) $(ISCOTCH)\n" )
    FILE( APPEND "${MUMPS_Makefile}" "PLAT    =\n" )
    FILE( APPEND "${MUMPS_Makefile}" "LIBEXT  = .a\n" )
    FILE( APPEND "${MUMPS_Makefile}" "OUTC    = -o\n" )
    FILE( APPEND "${MUMPS_Makefile}" "OUTF    = -o\n" )
    FILE( APPEND "${MUMPS_Makefile}" "RM      = /bin/rm -f\n" )
    FILE( APPEND "${MUMPS_Makefile}" "CC      = ${CMAKE_C_COMPILER}\n" )
    FILE( APPEND "${MUMPS_Makefile}" "FC      = ${CMAKE_Fortran_COMPILER}\n" )
    FILE( APPEND "${MUMPS_Makefile}" "FL      = ${CMAKE_Fortran_COMPILER}\n" )
    FILE( APPEND "${MUMPS_Makefile}" "AR      = ar vr \n" )
    FILE( APPEND "${MUMPS_Makefile}" "RANLIB  = ranlib\n" )
    FILE( APPEND "${MUMPS_Makefile}" "INCPAR  = -I/usr/include\n" )
    FILE( APPEND "${MUMPS_Makefile}" "INCSEQ  = -I$(topdir)/libseq\n" )
    FILE( APPEND "${MUMPS_Makefile}" "LIBSEQ  = -L$(topdir)/libseq -lmpiseq\n" )
    FILE( APPEND "${MUMPS_Makefile}" "LIBBLAS = ${BLAS_LAPACK_LINK}\n" )
    FILE( APPEND "${MUMPS_Makefile}" "\n" )
    FILE( APPEND "${MUMPS_Makefile}" "LIBOTHERS = -lpthread\n" )
    FILE( APPEND "${MUMPS_Makefile}" "CDEFS = -DAdd_\n" )
    FILE( APPEND "${MUMPS_Makefile}" "OPTF    = ${CMAKE_Fortran_FLAGS}\n" )
    FILE( APPEND "${MUMPS_Makefile}" "OPTC    = ${CMAKE_C_FLAGS} -I.\n" )
    FILE( APPEND "${MUMPS_Makefile}" "OPTL    = -O\n" )
    IF ( MUMPS_PARALLEL )
        FILE( APPEND "${MUMPS_Makefile}" "SCALAP  = -lscalapack -lblacs\n" )
        FILE( APPEND "${MUMPS_Makefile}" "INCS = $(INCPAR)\n" )
        FILE( APPEND "${MUMPS_Makefile}" "LIBS = $(LIBPAR)\n" )
        FILE( APPEND "${MUMPS_Makefile}" "LIBSEQNEEDED = \n" )
        SET( MUMPS_COPY_LIBSEQ ${CMAKE_COMMAND} -E echo "" )
    ELSE()
        FILE( APPEND "${MUMPS_Makefile}" "INCS = $(INCSEQ)\n" )
        FILE( APPEND "${MUMPS_Makefile}" "LIBS = $(LIBSEQ)\n" )
        FILE( APPEND "${MUMPS_Makefile}" "LIBSEQNEEDED = libseqneeded\n" )
        SET( MUMPS_COPY_LIBSEQ ${CMAKE_COMMAND} -E copy "${MUMPS_BUILD_DIR}/libseq/libmpiseq.a" "${MUMPS_INSTALL_DIR}/lib/libmpiseq.a" )
    ENDIF()
ENDIF()


# Build kokkos
IF ( CMAKE_BUILD_MUMPS )
    FOREACH( TPL ${MUMPS_DEPENDENCIES} )
        LIST(FIND TPL_LIST "${TPL}" index)
        IF (${index} EQUAL -1)
            MESSAGE(FATAL_ERROR "MUMPS depends on ${TPL}, but it is not configured")
        ENDIF()
    ENDFOREACH()
    EXTERNALPROJECT_ADD( 
        MUMPS
        URL                 "${MUMPS_CMAKE_URL}"
        DOWNLOAD_DIR        "${MUMPS_CMAKE_DOWNLOAD_DIR}"
        SOURCE_DIR          "${MUMPS_CMAKE_SOURCE_DIR}"
        UPDATE_COMMAND      ""
        CONFIGURE_COMMAND   cp ${MUMPS_Makefile} ${MUMPS_BUILD_DIR}/Makefile.inc
        BUILD_COMMAND       make -j ${PROCS_INSTALL} VERBOSE=1
        BUILD_IN_SOURCE     0
        INSTALL_COMMAND     ""
        DEPENDS             ${MUMPS_DEPENDENCIES}
        LOG_DOWNLOAD 1   LOG_UPDATE 1   LOG_CONFIGURE 1   LOG_BUILD 1   LOG_TEST 1   LOG_INSTALL 1
    )
    EXTERNALPROJECT_ADD_STEP(
        MUMPS
        copy-install-files
        COMMENT             "Copy install files"
        COMMAND             ${CMAKE_COMMAND} -E copy_directory "${MUMPS_BUILD_DIR}/lib" "${MUMPS_INSTALL_DIR}/lib"
        COMMAND             ${CMAKE_COMMAND} -E copy_directory "${MUMPS_BUILD_DIR}/include" "${MUMPS_INSTALL_DIR}/include"
        COMMAND             ${MUMPS_COPY_LIBSEQ}
        COMMENT             ""
        DEPENDEES           build
        DEPENDERS           install
        WORKING_DIRECTORY   "${MUMPS_BUILD_DIR}"
        LOG                 1
    )
    ADD_TPL_SAVE_LOGS( MUMPS )
    ADD_TPL_CLEAN( MUMPS )
ELSE()
    ADD_TPL_EMPTY( MUMPS )
ENDIF()



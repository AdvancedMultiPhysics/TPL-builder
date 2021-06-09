# This will configure and build LMDB
# User can configure the source path by specifying LMDB_SRC_DIR,
#    the download path by specifying LMDB_URL, or the installed 
#    location by specifying LMDB_INSTALL_DIR


# Intialize download/src/install vars
SET( LMDB_BUILD_DIR "${CMAKE_BINARY_DIR}/LMDB-prefix/src/LMDB-build" )
IF ( LMDB_URL ) 
    MESSAGE("   LMDB_URL = ${LMDB_URL}")
    SET( LMDB_CMAKE_URL            "${LMDB_URL}"       )
    SET( LMDB_CMAKE_DOWNLOAD_DIR   "${LMDB_BUILD_DIR}" )
    SET( LMDB_CMAKE_SOURCE_DIR     "${LMDB_BUILD_DIR}" )
    SET( LMDB_CMAKE_INSTALL_DIR "${CMAKE_INSTALL_PREFIX}/lmdb" )
    SET( CMAKE_BUILD_LMDB TRUE )
ELSEIF ( LMDB_SRC_DIR )
    VERIFY_PATH("${LMDB_SRC_DIR}")
    MESSAGE("   LMDB_SRC_DIR = ${LMDB_SRC_DIR}")
    SET( LMDB_CMAKE_URL            "${LMDB_SRC_DIR}"   )
    SET( LMDB_CMAKE_DOWNLOAD_DIR   "${LMDB_BUILD_DIR}" )
    SET( LMDB_CMAKE_SOURCE_DIR     "${LMDB_BUILD_DIR}" )
    SET( LMDB_CMAKE_INSTALL_DIR "${CMAKE_INSTALL_PREFIX}/lmdb" )
    SET( CMAKE_BUILD_LMDB TRUE )
ELSEIF ( LMDB_INSTALL_DIR ) 
    SET( LMDB_CMAKE_INSTALL_DIR "${LMDB_INSTALL_DIR}" )
    SET( CMAKE_BUILD_LMDB FALSE )
ELSE()
    MESSAGE(FATAL_ERROR "Please specify LMDB_SRC_DIR, LMDB_URL, or LMDB_INSTALL_DIR")
ENDIF()
SET( LMDB_INSTALL_DIR "${LMDB_CMAKE_INSTALL_DIR}" )
MESSAGE( "   LMDB_INSTALL_DIR = ${LMDB_INSTALL_DIR}" )


# Configure lmdb
IF ( CMAKE_BUILD_LMDB )
    # Set variables based on TPLs
    # Generate Makefile
    SET( LMDB_Makefile "${CMAKE_BINARY_DIR}/LMDB-prefix/src/Makefile" )
    FILE( WRITE  "${LMDB_Makefile}" "# This file is automatically generated by the TPL builder\n" )

    FILE( APPEND "${LMDB_Makefile}" "CC	= ${CMAKE_C_COMPILER}\n" )
    FILE( APPEND "${LMDB_Makefile}" "AR	= ar\n" )
    FILE( APPEND "${LMDB_Makefile}" "W	= -W -Wall -Wno-unused-parameter -Wbad-function-cast -Wuninitialized\n" )
    FILE( APPEND "${LMDB_Makefile}" "THREADS = -pthread\n" )
    FILE( APPEND "${LMDB_Makefile}" "OPT = -O2 -g\n" )
    FILE( APPEND "${LMDB_Makefile}" "CFLAGS	= $(THREADS) $(OPT) $(W) $(XCFLAGS)\n" )
    FILE( APPEND "${LMDB_Makefile}" "LDLIBS	= # -lntdll # Windows needs ntdll\n" )
    FILE( APPEND "${LMDB_Makefile}" "SOLIBS	= # -lntdll\n" )
    FILE( APPEND "${LMDB_Makefile}" "prefix	= ${CMAKE_INSTALL_PREFIX}/lmdb\n" )
    FILE( APPEND "${LMDB_Makefile}" "exec_prefix = $(prefix)\n" )
    FILE( APPEND "${LMDB_Makefile}" "bindir = $(exec_prefix)/bin\n" )
    FILE( APPEND "${LMDB_Makefile}" "libdir = $(exec_prefix)/lib\n" )
    FILE( APPEND "${LMDB_Makefile}" "includedir = $(prefix)/include\n" )
    FILE( APPEND "${LMDB_Makefile}" "datarootdir = $(prefix)/share\n" )
    FILE( APPEND "${LMDB_Makefile}" "mandir = $(datarootdir)/man\n" )

########################################################################
    FILE( APPEND "${LMDB_Makefile}" "\n" )
    FILE( APPEND "${LMDB_Makefile}" "IHDRS	= lmdb.h\n" )
    FILE( APPEND "${LMDB_Makefile}" "ILIBS	= liblmdb.a liblmdb.so\n" )
    FILE( APPEND "${LMDB_Makefile}" "IPROGS	= mdb_stat mdb_copy mdb_dump mdb_load\n" )
    FILE( APPEND "${LMDB_Makefile}" "IDOCS	= mdb_stat.1 mdb_copy.1 mdb_dump.1 mdb_load.1\n" )
    FILE( APPEND "${LMDB_Makefile}" "PROGS	= $(IPROGS) mtest mtest2 mtest3 mtest4 mtest5\n" )
    FILE( APPEND "${LMDB_Makefile}" "all:	$(ILIBS) $(PROGS)\n" )
    FILE( APPEND "${LMDB_Makefile}" "\n" )
    FILE( APPEND "${LMDB_Makefile}" "install: $(ILIBS) $(IPROGS) $(IHDRS)\n" )
    FILE( APPEND "${LMDB_Makefile}" "	mkdir -p $(DESTDIR)$(bindir)\n" )
    FILE( APPEND "${LMDB_Makefile}" "	mkdir -p $(DESTDIR)$(libdir)\n" )
    FILE( APPEND "${LMDB_Makefile}" "	mkdir -p $(DESTDIR)$(includedir)\n" )
    FILE( APPEND "${LMDB_Makefile}" "	mkdir -p $(DESTDIR)$(mandir)/man1\n" )
    FILE( APPEND "${LMDB_Makefile}" "	for f in $(IPROGS); do cp $$f $(DESTDIR)$(bindir); done\n" )
    FILE( APPEND "${LMDB_Makefile}" "	for f in $(ILIBS); do cp $$f $(DESTDIR)$(libdir); done\n" )
    FILE( APPEND "${LMDB_Makefile}" "	for f in $(IHDRS); do cp $$f $(DESTDIR)$(includedir); done\n" )
    FILE( APPEND "${LMDB_Makefile}" "	for f in $(IDOCS); do cp $$f $(DESTDIR)$(mandir)/man1; done\n" )
    FILE( APPEND "${LMDB_Makefile}" "\n" )
    FILE( APPEND "${LMDB_Makefile}" "clean:\n" )
    FILE( APPEND "${LMDB_Makefile}" "	rm -rf $(PROGS) *.[ao] *.[ls]o *~ testdb\n" )
    FILE( APPEND "${LMDB_Makefile}" "\n" )
    FILE( APPEND "${LMDB_Makefile}" "test:	all\n" )
    FILE( APPEND "${LMDB_Makefile}" "	rm -rf testdb && mkdir testdb\n" )
    FILE( APPEND "${LMDB_Makefile}" "	./mtest && ./mdb_stat testdb\n" )
    FILE( APPEND "${LMDB_Makefile}" "\n" )
    FILE( APPEND "${LMDB_Makefile}" "liblmdb.a:	mdb.o midl.o\n" )
    FILE( APPEND "${LMDB_Makefile}" "	$(AR) rs $@ mdb.o midl.o\n" )
    FILE( APPEND "${LMDB_Makefile}" "\n" )
    FILE( APPEND "${LMDB_Makefile}" "liblmdb.so:	mdb.lo midl.lo\n" )
    FILE( APPEND "${LMDB_Makefile}" "	$(CC) $(LDFLAGS) -pthread -shared -o $@ mdb.lo midl.lo $(SOLIBS)\n" )
    FILE( APPEND "${LMDB_Makefile}" "\n" )
    FILE( APPEND "${LMDB_Makefile}" "mdb_stat: mdb_stat.o liblmdb.a\n" )
    FILE( APPEND "${LMDB_Makefile}" "mdb_copy: mdb_copy.o liblmdb.a\n" )
    FILE( APPEND "${LMDB_Makefile}" "mdb_dump: mdb_dump.o liblmdb.a\n" )
    FILE( APPEND "${LMDB_Makefile}" "mdb_load: mdb_load.o liblmdb.a\n" )
    FILE( APPEND "${LMDB_Makefile}" "mtest:    mtest.o    liblmdb.a\n" )
    FILE( APPEND "${LMDB_Makefile}" "mtest2:	mtest2.o liblmdb.a\n" )
    FILE( APPEND "${LMDB_Makefile}" "mtest3:	mtest3.o liblmdb.a\n" )
    FILE( APPEND "${LMDB_Makefile}" "mtest4:	mtest4.o liblmdb.a\n" )
    FILE( APPEND "${LMDB_Makefile}" "mtest5:	mtest5.o liblmdb.a\n" )
    FILE( APPEND "${LMDB_Makefile}" "mtest6:	mtest6.o liblmdb.a\n" )
    FILE( APPEND "${LMDB_Makefile}" "\n" )
    FILE( APPEND "${LMDB_Makefile}" "mdb.o: mdb.c lmdb.h midl.h\n" )
    FILE( APPEND "${LMDB_Makefile}" "	$(CC) $(CFLAGS) $(CPPFLAGS) -c mdb.c\n" )
    FILE( APPEND "${LMDB_Makefile}" "\n" )
    FILE( APPEND "${LMDB_Makefile}" "midl.o: midl.c midl.h\n" )
    FILE( APPEND "${LMDB_Makefile}" "	$(CC) $(CFLAGS) $(CPPFLAGS) -c midl.c\n" )
    FILE( APPEND "${LMDB_Makefile}" "\n" )
    FILE( APPEND "${LMDB_Makefile}" "mdb.lo: mdb.c lmdb.h midl.h\n" )
    FILE( APPEND "${LMDB_Makefile}" "	$(CC) $(CFLAGS) -fPIC $(CPPFLAGS) -c mdb.c -o $@\n" )
    FILE( APPEND "${LMDB_Makefile}" "\n" )
    FILE( APPEND "${LMDB_Makefile}" "midl.lo: midl.c midl.h\n" )
    FILE( APPEND "${LMDB_Makefile}" "	$(CC) $(CFLAGS) -fPIC $(CPPFLAGS) -c midl.c -o $@\n" )
    FILE( APPEND "${LMDB_Makefile}" "\n" )
    FILE( APPEND "${LMDB_Makefile}" "%:	%.o\n" )
    FILE( APPEND "${LMDB_Makefile}" "	$(CC) $(CFLAGS) $(LDFLAGS) $^ $(LDLIBS) -o $@\n" )
    FILE( APPEND "${LMDB_Makefile}" "\n" )
    FILE( APPEND "${LMDB_Makefile}" "%.o:	%.c lmdb.h\n" )
    FILE( APPEND "${LMDB_Makefile}" "	$(CC) $(CFLAGS) $(CPPFLAGS) -c $<\n" )
    FILE( APPEND "${LMDB_Makefile}" "\n" )
    FILE( APPEND "${LMDB_Makefile}" "COV_FLAGS=-fprofile-arcs -ftest-coverage\n" )
    FILE( APPEND "${LMDB_Makefile}" "COV_OBJS=xmdb.o xmidl.o\n" )
    FILE( APPEND "${LMDB_Makefile}" "\n" )
    FILE( APPEND "${LMDB_Makefile}" "coverage: xmtest\n" )
    FILE( APPEND "${LMDB_Makefile}" "	for i in mtest*.c [0-9]*.c; do j=`basename \$$i .c`; $(MAKE) $$j.o; \\n" )
    FILE( APPEND "${LMDB_Makefile}" "		gcc -o x$$j $$j.o $(COV_OBJS) -pthread $(COV_FLAGS); \\n" )
    FILE( APPEND "${LMDB_Makefile}" "		rm -rf testdb; mkdir testdb; ./x$$j; done\n" )
    FILE( APPEND "${LMDB_Makefile}" "	gcov xmdb.c\n" )
    FILE( APPEND "${LMDB_Makefile}" "	gcov xmidl.c\n" )
    FILE( APPEND "${LMDB_Makefile}" "\n" )
    FILE( APPEND "${LMDB_Makefile}" "xmtest:	mtest.o xmdb.o xmidl.o\n" )
    FILE( APPEND "${LMDB_Makefile}" "	gcc -o xmtest mtest.o xmdb.o xmidl.o -pthread $(COV_FLAGS)\n" )
    FILE( APPEND "${LMDB_Makefile}" "\n" )
    FILE( APPEND "${LMDB_Makefile}" "xmdb.o: mdb.c lmdb.h midl.h\n" )
    FILE( APPEND "${LMDB_Makefile}" "	$(CC) $(CFLAGS) -fPIC $(CPPFLAGS) -O0 $(COV_FLAGS) -c mdb.c -o $@\n" )
    FILE( APPEND "${LMDB_Makefile}" "\n" )

    FILE( APPEND "${LMDB_Makefile}" "xmidl.o: midl.c midl.h\n" )
    FILE( APPEND "${LMDB_Makefile}" "	$(CC) $(CFLAGS) -fPIC $(CPPFLAGS) -O0 $(COV_FLAGS) -c midl.c -o $@\n" )

    FILE( APPEND "${LMDB_Makefile}" "\n" )
ENDIF()


# Build LMDB
ADD_TPL( 
    LMDB
    URL                 "${LMDB_CMAKE_URL}"
    DOWNLOAD_DIR        "${LMDB_CMAKE_DOWNLOAD_DIR}"
    SOURCE_DIR          "${LMDB_CMAKE_SOURCE_DIR}"
    UPDATE_COMMAND      ""
    CONFIGURE_COMMAND   cp ${LMDB_Makefile} ${LMDB_BUILD_DIR}/Makefile
    BUILD_COMMAND       make VERBOSE=1
    BUILD_IN_SOURCE     0
    INSTALL_COMMAND     make install
    DEPENDS             ${LMDB_DEPENDENCIES}
    LOG_DOWNLOAD 1   LOG_UPDATE 1   LOG_CONFIGURE 1   LOG_BUILD 1   LOG_TEST 1   LOG_INSTALL 1
)



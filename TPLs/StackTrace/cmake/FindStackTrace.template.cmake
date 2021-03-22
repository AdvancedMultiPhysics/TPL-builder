# FindStackTrace
# ---------
#
# Find the FindStackTrace package
#
# Use this module by invoking find_package with the form:
#
#   find_package( StackTrace
#     [version] [EXACT]         # Minimum or EXACT version e.g. 1.36.0
#     [REQUIRED]                # Fail with error if the TPLs are not found
#     [COMPONENTS <libs>...]    # List of TPLs to include
#   )
#
# This module finds headers and requested component libraries for the StackTrace library
#
#   StackTrace_FOUND           - True if headers and requested libraries were found
#   StackTrace_LIBRARIES       - Libraries (and dependencies)
#   StackTrace_INCLUDE_DIRS    - Include paths


# Add the libraries for the stack trace
SET( StackTrace_FOUND TRUE )
SET( CMAKE_INSTALL_RPATH "@STACKTRACE_INSTALL_DIR@/lib" @CMAKE_INSTALL_RPATH@ ${CMAKE_INSTALL_RPATH} )
FIND_LIBRARY( StackTrace_LIB  NAMES stacktrace  PATHS "@STACKTRACE_INSTALL_DIR@/lib" NO_DEFAULT_PATH )
SET( StackTrace_LIBRARIES ${StackTrace_LIB} )
IF ( NOT TIMER_FOUND )
    # Do not include Timer libraries if they have already been found
    SET( StackTrace_LIBRARIES ${StackTrace_LIBRARIES} @TIMER_LIB@ )
ENDIF()
SET( StackTrace_LIBRARIES ${StackTrace_LIBRARIES} @SYSTEM_LIBS@ )
SET( StackTrace_INCLUDE_DIRS "@STACKTRACE_INSTALL_DIR@/include" )


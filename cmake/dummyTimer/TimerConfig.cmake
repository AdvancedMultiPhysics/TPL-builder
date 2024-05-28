SET( TIMER_VERSION 0.0.331 )


####### Expanded from @PACKAGE_INIT@ by configure_package_config_file() #######
####### Any changes to this file will be overwritten by the next CMake run ####
####### The input file was DummyTimer.cmake.in                            ########

get_filename_component(PACKAGE_PREFIX_DIR "${CMAKE_CURRENT_LIST_DIR}/../../../../../../../../usr/local" ABSOLUTE)

macro(set_and_check _var _file)
  set(${_var} "${_file}")
  if(NOT EXISTS "${_file}")
    message(FATAL_ERROR "File or directory ${_file} referenced by variable ${_var} does not exist !")
  endif()
endmacro()

macro(check_required_components _NAME)
  foreach(comp ${${_NAME}_FIND_COMPONENTS})
    if(NOT ${_NAME}_${comp}_FOUND)
      if(${_NAME}_FIND_REQUIRED_${comp})
        set(${_NAME}_FOUND FALSE)
      endif()
    endif()
  endforeach()
endmacro()

####################################################################################


# Configure a dummy Profiler App for the current project
IF ( "${NULL_TIMER_DIR}" STREQUAL "" )
    SET( NULL_TIMER_DIR "${CMAKE_CURRENT_BINARY_DIR}/null_timer" )
ENDIF()
IF ( NOT QUIET )
    MESSAGE( STATUS "Disabling timer utility" )
ENDIF()

# Write ProfilerApp.h
FILE(WRITE  "${NULL_TIMER_DIR}/ProfilerApp.h" "#define PROFILE(...)             do {} while(0)\n" )
FILE(APPEND "${NULL_TIMER_DIR}/ProfilerApp.h" "#define PROFILE2(...)            do {} while(0)\n" )
FILE(APPEND "${NULL_TIMER_DIR}/ProfilerApp.h" "#define PROFILE_START(...)       do {} while(0)\n" )
FILE(APPEND "${NULL_TIMER_DIR}/ProfilerApp.h" "#define PROFILE_STOP(...)        do {} while(0)\n" )
FILE(APPEND "${NULL_TIMER_DIR}/ProfilerApp.h" "#define PROFILE_START2(...)      do {} while(0)\n" )
FILE(APPEND "${NULL_TIMER_DIR}/ProfilerApp.h" "#define PROFILE_STOP2(...)       do {} while(0)\n" )
FILE(APPEND "${NULL_TIMER_DIR}/ProfilerApp.h" "#define PROFILE_SCOPED(...)      do {} while(0)\n" )
FILE(APPEND "${NULL_TIMER_DIR}/ProfilerApp.h" "#define PROFILE_SYNCHRONIZE()    do {} while(0)\n" )
FILE(APPEND "${NULL_TIMER_DIR}/ProfilerApp.h" "#define PROFILE_SAVE(...)        do {} while(0)\n" )
FILE(APPEND "${NULL_TIMER_DIR}/ProfilerApp.h" "#define PROFILE_STORE_TRACE(X)   do {} while(0)\n" )
FILE(APPEND "${NULL_TIMER_DIR}/ProfilerApp.h" "#define PROFILE_ENABLE(...)      do {} while(0)\n" )
FILE(APPEND "${NULL_TIMER_DIR}/ProfilerApp.h" "#define PROFILE_DISABLE()        do {} while(0)\n" )
FILE(APPEND "${NULL_TIMER_DIR}/ProfilerApp.h" "#define PROFILE_ENABLE_TRACE()   do {} while(0)\n" )
FILE(APPEND "${NULL_TIMER_DIR}/ProfilerApp.h" "#define PROFILE_DISABLE_TRACE()  do {} while(0)\n" )
FILE(APPEND "${NULL_TIMER_DIR}/ProfilerApp.h" "#define PROFILE_ENABLE_MEMORY()  do {} while(0)\n" )
FILE(APPEND "${NULL_TIMER_DIR}/ProfilerApp.h" "#define PROFILE_DISABLE_MEMORY() do {} while(0)\n" )

# Write MemoryApp.h
FILE(WRITE  "${NULL_TIMER_DIR}/MemoryApp.h" "#include <cstring>\n" )
FILE(APPEND "${NULL_TIMER_DIR}/MemoryApp.h" "class MemoryApp final {\n" )
FILE(APPEND "${NULL_TIMER_DIR}/MemoryApp.h" "public:\n" )
FILE(APPEND "${NULL_TIMER_DIR}/MemoryApp.h" "   struct MemoryStats {\n" )
FILE(APPEND "${NULL_TIMER_DIR}/MemoryApp.h" "       size_t bytes_new, bytes_delete, N_new, N_delete, tot_bytes_used, system_memory, stack_used, stack_size;\n" )
FILE(APPEND "${NULL_TIMER_DIR}/MemoryApp.h" "       MemoryStats() { memset(this,0,sizeof(MemoryStats)); }\n" )
FILE(APPEND "${NULL_TIMER_DIR}/MemoryApp.h" "   };\n" )
FILE(APPEND "${NULL_TIMER_DIR}/MemoryApp.h" "   static inline void print( std::ostream& ) {}\n" )
FILE(APPEND "${NULL_TIMER_DIR}/MemoryApp.h" "   static inline size_t getMemoryUsage() { return 0; }\n" )
FILE(APPEND "${NULL_TIMER_DIR}/MemoryApp.h" "   static inline size_t getTotalMemoryUsage() { return 0; }\n" )
FILE(APPEND "${NULL_TIMER_DIR}/MemoryApp.h" "   static inline size_t getSystemMemory() { return 0; }\n" )
FILE(APPEND "${NULL_TIMER_DIR}/MemoryApp.h" "   static inline MemoryStats getMemoryStats() { return MemoryStats(); }\n" )
FILE(APPEND "${NULL_TIMER_DIR}/MemoryApp.h" "};\n" )

SET( TIMER_INCLUDE  "${NULL_TIMER_DIR}" )
INCLUDE_DIRECTORIES( "${TIMER_INCLUDE}" )


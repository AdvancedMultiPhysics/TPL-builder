# This will configure and build DTK
# User can configure the source path by speficfying DTK_SRC_DIR,

IF(DTK_URL OR DTK_INSTALL_DIR) 
    MESSAGE(FATAL_ERROR "Please specify DTK_SRC_DIR rather than DTK_URL or DTK_INSTALL_DIR")
ELSEIF(DTK_SRC_DIR)
    VERIFY_PATH("${DTK_SRC_DIR}")
    MESSAGE_TPL("   DTK_SRC_DIR = ${DTK_SRC_DIR}")
    LIST(APPEND TRILINOS_EXTRA_REPOSITORIES DataTransferKit)
    LIST(APPEND TRILINOS_EXTRA_PACKAGES     CXX11)
    LIST(APPEND TRILINOS_EXTRA_PACKAGES     DataTransferKit)
    LIST(APPEND TRILINOS_EXTRA_PACKAGES     DataTransferKitPointCloud)
    LIST(APPEND TRILINOS_EXTRA_PACKAGES     DataTransferKitIntrepidAdapters)
    LIST(APPEND TRILINOS_EXTRA_FLAGS        "-D DataTransferKit_ENABLE_TESTS:BOOL=ON")
    LIST(APPEND TRILINOS_EXTRA_FLAGS        "-D DataTransferKit_ENABLE_MPI:BOOL=ON")
    MESSAGE("TRILINOS_EXTRA_REPOSITORIES = ${TRILINOS_EXTRA_REPOSITORIES}")
    MESSAGE("TRILINOS_EXTRA_PACKAGES     = ${TRILINOS_EXTRA_PACKAGES}")
    MESSAGE("TRILINOS_EXTRA_FLAGS        = ${TRILINOS_EXTRA_FLAGS}")
    SET(CMAKE_BUILD_DTK TRUE)
ELSE()
    MESSAGE(FATAL_ERROR "Please specify DTK_SRC_DIR")
ENDIF()
FILE(APPEND "${CMAKE_INSTALL_PREFIX}/TPLs.cmake" "SET(USE_EXT_DTK 1)\n" )

IF(CMAKE_BUILD_DTK)
    EXTERNALPROJECT_ADD(
        DTK
        DEPENDS             
        GIT_REPOSITORY      https://github.com/ORNL-CEES/DataTransferKit.git
        GIT_TAG             master
        DOWNLOAD_DIR        ${DTK_SRC_DIR}
        SOURCE_DIR        ${DTK_SRC_DIR}
        CONFIGURE_COMMAND   ""
        BUILD_COMMAND       ""
        BUILD_IN_SOURCE     0
        INSTALL_COMMAND     ""
        LOG_DOWNLOAD 1   LOG_UPDATE 1   LOG_CONFIGURE 1   LOG_BUILD 1   LOG_TEST 1   LOG_INSTALL 1
    )
    ADD_TPL_SAVE_LOGS(DTK)
    ADD_TPL_CLEAN(DTK)
ELSE()
    ADD_TPL_EMPTY(DTK)
ENDIF()


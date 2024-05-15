# MACRO to add steps to install nvcc
MACRO( INSTALL_NVCC PACKAGE )
    IF ( KOKKOS_SRC_DIR )
        SET( NVCC_SRC_DIR "${KOKKOS_SRC_DIR}" )
    ELSEIF ( TRILINOS_KOKKOS )
        SET( NVCC_SRC_DIR "${TRILINOS_CMAKE_SOURCE_DIR}/packages/kokkos" )
    ELSE()
        MESSAGE( FATAL_ERROR "Kokkos src directory not found" )
    ENDIF()
    SET( NVCC_BUILD_DIR "${CMAKE_BINARY_DIR}/NVCC-build" )
    FILE( MAKE_DIRECTORY "${NVCC_BUILD_DIR}" )
    CONFIGURE_FILE( "${CMAKE_CURRENT_LIST_DIR}/KOKKOS-nvcc.cmake" "${CMAKE_BINARY_DIR}/KOKKOS-prefix/src/KOKKOS-nvcc.cmake" @ONLY )
    EXTERNALPROJECT_ADD_STEP(
        ${PACKAGE}
        create-nvcc_wrapper
        COMMENT             "Creating nvcc_wrapper"
        COMMAND             ${CMAKE_COMMAND} -P "${CMAKE_BINARY_DIR}/KOKKOS-prefix/src/KOKKOS-nvcc.cmake"
        COMMAND             ${CMAKE_COMMAND} -E copy_if_different "${NVCC_BUILD_DIR}/nvcc_wrapper" "${KOKKOS_INSTALL_DIR}/bin/nvcc_wrapper"
        COMMENT             ""
        DEPENDEES           download
        DEPENDERS           build
        WORKING_DIRECTORY   "${NVCC_BUILD_DIR}"
        LOG                 1
    )
ENDMACRO()




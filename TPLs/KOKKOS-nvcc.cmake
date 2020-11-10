# Set some variables
SET( KOKKOS_SRC_DIR @KOKKOS_SRC_DIR@ )
SET( KOKKOS_BUILD_DIR @KOKKOS_BUILD_DIR@ )
SET( KOKKOS_INSTALL_DIR @KOKKOS_INSTALL_DIR@ )
SET( KOKKOS_CUDA_ARCH @KOKKOS_CUDA_ARCH@ )
SET( KOKKOS_HOST_COMPILER @KOKKOS_HOST_COMPILER@ )

# Copy and modify nvcc_wrapper
SET( NVCC_WRAPPER_IN "${KOKKOS_SRC_DIR}/bin/nvcc_wrapper" )
FILE( READ "${NVCC_WRAPPER_IN}" NVCC_WRAPPER_CONTENTS )
STRING( REGEX REPLACE "default_arch=[^\n]*" "default_arch=\"${KOKKOS_CUDA_ARCH}\"" NVCC_WRAPPER_CONTENTS "${NVCC_WRAPPER_CONTENTS}")
STRING( REPLACE "\${NVCC_WRAPPER_DEFAULT_COMPILER:-\"g++\"}" "\${NVCC_WRAPPER_DEFAULT_COMPILER:-\"${KOKKOS_HOST_COMPILER}\"}" NVCC_WRAPPER_CONTENTS "${NVCC_WRAPPER_CONTENTS}")
STRING( REGEX REPLACE "#default_arch=[^\n]*" "" NVCC_WRAPPER_CONTENTS "${NVCC_WRAPPER_CONTENTS}" )
STRING( REGEX REPLACE "#host_compiler=[^\n]*" "" NVCC_WRAPPER_CONTENTS "${NVCC_WRAPPER_CONTENTS}" )
STRING( REGEX REPLACE "#default_compiler=[^\n]*" "" NVCC_WRAPPER_CONTENTS "${NVCC_WRAPPER_CONTENTS}" )
FILE( WRITE "${KOKKOS_BUILD_DIR}/tmp/nvcc_wrapper" "${NVCC_WRAPPER_CONTENTS}")

# Instal nvcc_wrapper
FILE(COPY "${KOKKOS_BUILD_DIR}/tmp/nvcc_wrapper" DESTINATION "${KOKKOS_BUILD_DIR}"
    FILE_PERMISSIONS OWNER_READ OWNER_WRITE OWNER_EXECUTE GROUP_READ GROUP_EXECUTE WORLD_READ WORLD_EXECUTE )
FILE( COPY "${KOKKOS_BUILD_DIR}/nvcc_wrapper" DESTINATION "${KOKKOS_INSTALL_DIR}" )

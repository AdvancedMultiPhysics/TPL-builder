# Set some variables
SET( NVCC_SRC_DIR @NVCC_SRC_DIR@ )
SET( NVCC_BUILD_DIR @NVCC_BUILD_DIR@ )
SET( KOKKOS_CUDA_ARCH @KOKKOS_CUDA_ARCH@ )
SET( KOKKOS_CUDA_CXX_FLAGS "@KOKKOS_CUDA_CXX_FLAGS@" )
SET( KOKKOS_HOST_COMPILER @KOKKOS_HOST_COMPILER@ )
SET( KOKKOS_CUDA_COMPILER @KOKKOS_CUDA_COMPILER@ )

# Copy and modify nvcc_wrapper
SET( NVCC_WRAPPER_IN "${NVCC_SRC_DIR}/bin/nvcc_wrapper" )
FILE( READ "${NVCC_WRAPPER_IN}" NVCC_WRAPPER_CONTENTS )
STRING( REGEX REPLACE "default_arch=[^\n]*" "default_arch=\"${KOKKOS_CUDA_ARCH}\"" NVCC_WRAPPER_CONTENTS "${NVCC_WRAPPER_CONTENTS}")
STRING( REPLACE "\${NVCC_WRAPPER_DEFAULT_COMPILER:-\"g++\"}" "\${NVCC_WRAPPER_DEFAULT_COMPILER:-\"${KOKKOS_HOST_COMPILER}\"}" NVCC_WRAPPER_CONTENTS "${NVCC_WRAPPER_CONTENTS}")
#STRING( REPLACE "nvcc_compiler=nvcc" "nvcc_compiler=${KOKKOS_CUDA_COMPILER}" NVCC_WRAPPER_CONTENTS "${NVCC_WRAPPER_CONTENTS}" )
STRING( REGEX REPLACE "#default_arch=[^\n]*" "" NVCC_WRAPPER_CONTENTS "${NVCC_WRAPPER_CONTENTS}" )
STRING( REGEX REPLACE "#host_compiler=[^\n]*" "" NVCC_WRAPPER_CONTENTS "${NVCC_WRAPPER_CONTENTS}" )
STRING( REGEX REPLACE "#default_compiler=[^\n]*" "" NVCC_WRAPPER_CONTENTS "${NVCC_WRAPPER_CONTENTS}" )
STRING( REGEX REPLACE "cuda_args=[^\n]*" "cuda_args=\"${KOKKOS_CUDA_CXX_FLAGS} -arch=$default_arch\"" NVCC_WRAPPER_CONTENTS "${NVCC_WRAPPER_CONTENTS}")
STRING( REGEX REPLACE "#Handle unsupported standard flags" "#Handle c++1z\n  -std=c++1z)\n    std_flag=-std=c++17\n    shared_args=\"$shared_args $std_flag\"\n    ;;\n  #Handle unsupported standard flags" NVCC_WRAPPER_CONTENTS "${NVCC_WRAPPER_CONTENTS}" )
FILE( WRITE "${NVCC_BUILD_DIR}/tmp/nvcc_wrapper" "${NVCC_WRAPPER_CONTENTS}")

# Install nvcc_wrapper
FILE(COPY "${NVCC_BUILD_DIR}/tmp/nvcc_wrapper" DESTINATION "${NVCC_BUILD_DIR}"
    FILE_PERMISSIONS OWNER_READ OWNER_WRITE OWNER_EXECUTE GROUP_READ GROUP_EXECUTE WORLD_READ WORLD_EXECUTE )




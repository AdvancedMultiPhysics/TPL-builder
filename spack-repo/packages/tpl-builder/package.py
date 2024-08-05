# Copyright 2013-2023 Lawrence Livermore National Security, LLC and other
# Spack Project Developers. See the top-level COPYRIGHT file for details.
#
# SPDX-License-Identifier: (Apache-2.0 OR MIT)
from spack.package import *


class TplBuilder(CMakePackage, CudaPackage, ROCmPackage):

    homepage = "https://re-git.lanl.gov/xcap/oss/solvers/tpl-builder"
    git = "ssh://git@re-git.lanl.gov:10022/xcap/oss/solvers/tpl-builder.git"

    version("master", branch="master")

    variant("stacktrace", default=False, description="Build with support for Stacktrace")
    variant("lapackwrappers", default=False, description="Build with support for lapackwrappers")
    variant("lapack", default=False, description="Build with support for lapack")
    variant("boost", default=False, description="Build with support for Boost")
    variant("hdf5", default=False, description="Build with support for HDF5")
    variant("hypre", default=False, description="Build with support for hypre")
    variant("kokkos", default=False, description="Build with support for Kokkos")
    variant("libmesh", default=False, description="Build with libmesh support")
    variant("mpi", default=False, description="Build with MPI support")
    variant("netcdf", default=False, description="Build with NetCDF support")
    variant("petsc", default=False, description="Build with Petsc support")
    variant("shared", default=False, description="Build shared libraries")
    variant("silo", default=False, description="Build with support for Silo")
    variant("sundials", default=False, description="Build with support for Sundials")
    variant("trilinos", default=False, description="Build with support for Trilinos")
    variant("umpire", default=False, description="Build with support for UMPIRE")
    variant("zlib", default=False, description="Build with support for zlib")
    variant("openmp", default=False, description="Build with OpenMP support")

    depends_on("git", type="build")

    depends_on("stacktrace", when="+stacktrace")
    depends_on("stacktrace+mpi", when="+stacktrace+mpi")
    depends_on("lapackwrappers", when="+lapackwrappers")

    depends_on("boost", when="+boost")
    depends_on("hdf5+cxx+fortran", when="+hdf5")
    depends_on("hypre", when="+hypre")
    depends_on("kokkos", when="+kokkos")
    depends_on("libmesh+exodusii+netcdf", when="+libmesh")
    depends_on("netcdf-c", when="+netcdf")
    depends_on("petsc~hypre", when="+petsc", patches=[patch("petsc.snes.patch.v3.19.0", when="@3.19.0:")])
    depends_on("silo", when="+silo")
    depends_on("sundials@2.6.2", when="+sundials")
    depends_on(
        "trilinos@13.4.1: +epetra+epetraext+thyra+tpetra+ml+amesos+ifpack+ifpack2+belos+nox+stratimikos cxxstd=17 gotype=int",
        when="+trilinos",
    )
    depends_on("umpire", when="+umpire")
    depends_on("zlib", when="+zlib")

    depends_on("trilinos +kokkos", when="+trilinos+kokkos")
    depends_on("trilinos +mpi", when="+trilinos+mpi")

    depends_on("kokkos+cuda+cuda_constexpr", when="+kokkos+cuda")
    depends_on("kokkos+rocm", when="+kokkos+rocm")
    depends_on("hypre+cuda+unified-memory", when="+hypre+cuda")
    depends_on("hypre+rocm", when="+hypre+rocm")
    depends_on("umpire+cuda", when="+umpire+cuda")
    depends_on("umpire+rocm", when="+umpire+rocm")

    depends_on("libmesh~shared", when="~shared+libmesh")
    depends_on("libmesh+shared", when="+shared+libmesh")
    depends_on("hypre~shared", when="~shared+hypre")
    depends_on("hypre+shared", when="+shared+hypre")
    depends_on("petsc~shared", when="~shared+petsc")
    depends_on("petsc+shared", when="+shared+petsc")
    depends_on("lapackwrappers~shared", when="~shared+lapackwrappers")
    depends_on("lapackwrappers+shared", when="+shared+lapackwrappers")
    depends_on("blas", when="+lapack")
    depends_on("lapack", when="+lapack")

    requires("+lapack", when="+petsc")

    for _flag in list(CudaPackage.cuda_arch_values):
        depends_on("hypre cuda_arch=" + _flag, when="+hypre+cuda cuda_arch=" + _flag)
        depends_on("umpire cuda_arch=" + _flag, when="+umpire+cuda cuda_arch=" + _flag)
        depends_on("kokkos cuda_arch=" + _flag, when="+kokkos+cuda cuda_arch=" + _flag)

    for _flag in ROCmPackage.amdgpu_targets:
        depends_on("hypre amdgpu_target=" + _flag, when="+hypre+rocm amdgpu_target=" + _flag)
        depends_on("umpire amdgpu_target=" + _flag, when="+umpire+rocm amdgpu_target=" + _flag)
        depends_on("kokkos amdgpu_target=" + _flag, when="+kokkos+rocm amdgpu_target=" + _flag)

    # MPI related dependencies
    depends_on("mpi", when="+mpi")

    def setup_build_environment(self, env):
        if "^kokkos-nvcc-wrapper" in self.spec:
            # undo nvcc wrapper changes
            env.set("MPICH_CXX", spack_cxx)
            env.set("OMPI_CXX", spack_cxx)
            env.set("MPICXX_CXX", spack_cxx)

    phases = ["cmake", "build"]

    def cmake_args(self):
        spec = self.spec

        options = [
            self.define("INSTALL_DIR", self.spec.prefix),
            self.define("DISABLE_ALL_TESTS", True),
            self.define("CXX_STD", "17"),
            self.define_from_variant("BUILD_SHARED_LIBS", "shared"),
            self.define_from_variant("ENABLE_SHARED", "shared"),
            self.define("ENABLE_STATIC", not spec.variants["shared"].value),
            self.define_from_variant("USE_MPI", "mpi"),
            self.define("MPI_SKIP_SEARCH", False),
            self.define_from_variant("USE_OPENMP", "openmp"),
        ]

        if "+cuda" in spec:
            cuda_arch = self.spec.variants["cuda_arch"].value
            if cuda_arch[0] != "none":
                options.extend(
                    [
                        self.define("USE_CUDA", True),
                        self.define(
                            "CMAKE_CUDA_COMPILER", join_path(spec["cuda"].prefix.bin, "nvcc")
                        ),
                        self.define("CMAKE_CUDA_ARCHITECTURES", cuda_arch),
                        self.define(
                            "CMAKE_CUDA_FLAGS", "-extended-lambda --expt-relaxed-constexpr"
                        ),
                    ]
                )

        if "+rocm" in spec:
            amdgpu_target = self.spec.variants["amdgpu_target"].value
            if amdgpu_target[0] != "none":
                options.extend(
                    [
                        self.define("USE_HIP", True),
                        self.define(
                            "CMAKE_HIP_COMPILER", join_path(spec["llvm-amdgpu"].prefix.bin, "amdclang++")
                        ),
                        self.define("CMAKE_HIP_ARCHITECTURES", amdgpu_target),
                        self.define(
                            "CMAKE_HIP_FLAGS", ""
                        ),
                    ]
                )

        tpl_list = []

        if "+zlib" in spec:
            tpl_list.append("ZLIB")
            options.append(self.define("ZLIB_INSTALL_DIR", spec["zlib"].prefix))

        if "+lapackwrappers" in spec:
            tpl_list.append("LAPACK_WRAPPERS")
            options.append(self.define("LAPACK_WRAPPERS_INSTALL_DIR", spec["lapackwrappers"].prefix))

        if "+lapack" in spec:
            tpl_list.append("LAPACK")
            if "^intel-mkl" in self.spec:
                options.append(self.define("LAPACK_INSTALL_DIR", self.spec["lapack"].prefix.mkl))
            elif "^intel-oneapi-mkl" in self.spec:
                options.append(self.define("LAPACK_INSTALL_DIR", self.spec["intel-oneapi-mkl"].package.component_prefix))
            else:
                options.append(self.define("LAPACK_INSTALL_DIR", self.spec["lapack"].prefix))

            blas, lapack = self.spec["blas"].libs, self.spec["lapack"].libs
            options.extend(
                [
                    self.define("BLAS_LIBRARY_NAMES", ";".join(blas.names)),
                    self.define("BLAS_LIBRARY_DIRS", ";".join(blas.directories)),
                    self.define("LAPACK_LIBRARY_NAMES", ";".join(lapack.names)),
                    self.define("LAPACK_LIBRARY_DIRS", ";".join(lapack.directories)),
                ]
            )

        for vname in (
            "stacktrace",
            "boost",
            "hdf5",
            "hypre",
            "kokkos",
            "libmesh",
            "petsc",
            "silo",
            "sundials",
            "trilinos",
            "umpire",
        ):
            if "+" + vname in spec:
                tpl_list.append(vname.upper())
                options.append(self.define(f"{vname.upper()}_INSTALL_DIR", spec[vname].prefix))

        if "+netcdf" in spec:
            tpl_list.append("NETCDF")
            options.append(self.define("NETCDF_INSTALL_DIR", spec["netcdf-c"].prefix))

        options.append(self.define("TPL_LIST", ";".join(tpl_list)))
        return options
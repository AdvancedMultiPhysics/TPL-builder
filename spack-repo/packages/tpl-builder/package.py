from spack.package import *


class TplBuilder(CMakePackage):

    homepage = "https://re-git.lanl.gov/xcap/oss/solvers/tpl-builder"
    git = "ssh://git@re-git.lanl.gov:10022/xcap/oss/solvers/tpl-builder.git"

    version("master", branch="master")
    
    variant("mpi", default=True, description="build with mpi")
    variant("stacktrace", default=False)
    variant("hypre", default=False)
    variant("cuda", default=False)
    variant("cuda_arch", default="none", values = ("none", "10", "11", "12", "13", "20", "21", "30", "32", "35", "37", "50", "52", "53", "60", "61", "62", "70", "72", "75", "80", "86", "87", "89", "90"), multi=False)
    variant("rocm", default=False)
    variant("amdgpu_target", default="none",
            values = ("none", "gfx1010", "gfx1011", "gfx1012", "gfx1013", "gfx1030", "gfx1031", "gfx1032", "gfx1033", "gfx1034", "gfx1035", "gfx1036", "gfx1100", "gfx1101", "gfx1102", "gfx1103", "gfx701", "gfx801", "gfx802", "gfx803", "gfx900", "gfx900:xnack-", "gfx902", "gfx904", "gfx906", "gfx906:xnack-", "gfx908", "gfx908:xnack-", "gfx909", "gfx90a", "gfx90a:xnack+", "gfx90a:xnack-", "gfx90c", "gfx940", "gfx941", "gfx942" ),
            multi=False)    

    depends_on("cmake@3.26.0:", type="build")
    depends_on("mpi", when="+mpi")
    depends_on("stacktrace@master", when="+stacktrace")

    for sm_ in CudaPackage.cuda_arch_values:
        depends_on(
            "hypre+cuda cuda_arch={0}".format(sm_),
            when="+hypre+cuda cuda_arch={0}".format(sm_),
        )

    for gfx in ROCmPackage.amdgpu_targets:
        depends_on(
            "hypre+rocm amdgpu_target={0}".format(gfx),
            when="+hypre+rocm amdgpu_target={0}".format(gfx),
        )


    depends_on("hypre~cuda", when="+hypre~cuda")
    depends_on("hypre~rocm", when="+hypre~rocm")

    conflicts("+rocm +cuda")

    phases=["cmake", "build"]
    def cmake_args(self):

        args = [
            "-DINSTALL_DIR:PATH="+self.spec.prefix,
            "-DCXX_STD=17",
            "-DDISABLE_ALL_TESTS=ON"
        ]

        all_tpls = ["hypre","stacktrace"] #we can probably use the spec string to get this, or to get the variants that are turned on - maybe "self.spec" or str(spec)?
        install_dirs = []
        tpl_list = []
        for tpl in all_tpls:
            if self.spec.satisfies("+"+tpl):
                tpl_list.append(tpl.upper())
                args.append("-D" + tpl.upper() + "_INSTALL_DIR=" + self.spec[tpl].prefix)

        #TODO add to this list instead of overwriding it
        args.append("-DTPL_LIST:STRING=" + ';'.join(tpl_list))
        if self.spec.satisfies("+mpi"):
            args.append("-DCMAKE_CXX_COMPILER=mpicxx")

        if self.spec.satisfies("+cuda"):
            args.append("-DUSE_CUDA=TRUE")
            args.append("-DCMAKE_CUDA_COMPILER=" + self.spec["cuda"].prefix + "/bin/nvcc")
            args.append("-DCMAKE_CUDA_STANDARD=17")
            args.append("-DCMAKE_CUDA_ARCHITECTURES=" + self.spec.variants["cuda_arch"].value)

        return args


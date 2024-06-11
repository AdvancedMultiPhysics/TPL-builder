from spack.package import *


class TplBuilder(CMakePackage):

    homepage = "https://re-git.lanl.gov/xcap/oss/solvers/tpl-builder"
    git = "ssh://git@re-git.lanl.gov:10022/xcap/oss/solvers/tpl-builder.git"

    version("master", branch="master")
    version("cmake-update", branch="cmake-update")
    version("2.0.0", tag="2.0.0")
    
    variant("mpi", default=True, description="build with mpi")
    variant("stacktrace", default=False)
    variant("hypre", default=False)
    variant("cuda", default=False)
    variant("cuda_arch", default="none", values = ("none", "10", "11", "12", "13", "20", "21", "30", "32", "35", "37", "50", "52", "53", "60", "61", "62", "70", "72", "75", "80", "86", "87", "89", "90"), multi=False)
    variant("rocm", default=False)
    

    depends_on("cmake@3.26.0:", type="build")
    depends_on("mpi", when="+mpi")
    depends_on("stacktrace@master", when="+stacktrace")



    #shamelessly stollen from the hypre spack package
    for sm_ in CudaPackage.cuda_arch_values:
        depends_on(
            "hypre@2.31.0+cuda cuda_arch={0}".format(sm_),
            when="+hypre+cuda cuda_arch={0}".format(sm_),
        )



    #TODO im sure i can do all this with if statements
    #TODO make cuda_arch an option and able to use different platforms
    depends_on("hypre@2.31.0~cuda", when="+hypre~cuda")
    depends_on("hypre@2.31.0+rocm amdgpu_target=gfx90a", when="+hypre+rocm")
    depends_on("hypre@2.31.0~rocm", when="+hypre~rocm")

    conflicts("+rocm +cuda")

    phases=["cmake", "build"]
    def cmake_args(self):

        args = [
            "-DINSTALL_DIR:PATH="+self.spec.prefix,
            "-DCXX_STD=17",
            "-DDISABLE_ALL_TESTS=ON"
        ]

        #TODO include all TPLs in cmake args using the path to their spack installed binaries I think this can be done with "<TPL>_INSTALL_DIR"?
        archive_dir="/usr/projects/xcap/oss/projects/solvers/archives/"
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
        return args

        if self.spec.satidfies("+cuda"):
            args.append("-D USE_CUDA = True")
            args.append("-D CMAKE_CUDA_COMPILER=" + self.spec["cuda"].prefix + "bin/nvcc")
            args.append("-D CMAKE_CUDA_ARCHITECTURES=" + self.spec.variants["cuda_arch"].value)



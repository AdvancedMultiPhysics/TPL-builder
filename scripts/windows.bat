set TPL_ROOT="C:/Users/Mark Berrill/Desktop/TPLs"

cmake                                   ^
    -G "NMake Makefiles"                ^
    -D CMAKE_BUILD_TYPE=Debug           ^
    -D ENABLE_STATIC:BOOL=ON            ^
    -D ENABLE_SHARED:BOOL=OFF           ^
    -D LANGUAGES:STRING="C,CXX"         ^
    -D INSTALL_DIR="C:/Users/Mark Berrill/Desktop/TPLs/install/debug" ^
    -D TPL_LIST:STRING="LAPACK,TRILINOS"  ^
    -D LAPACK_INSTALL_DIR="C:/Program Files (x86)/Intel/Composer XE 2013 SP1/mkl" ^
    -D TRILINOS_SRC_DIR="C:/Users/Mark Berrill/Desktop/TPLs/publicTrilinos" ^
        -D TRILINOS_PACKAGES:STRING="Tpetra;Kokos" ^
        -D TRILINOS_EXTRA_FLAGS:STRING="-DTrilinos_ASSERT_MISSING_PACKAGES:BOOL=OFF;-DTrilinos_ENABLE_Fortran:BOOL=OFF;-DTrilinos_ENABLE_ALL_PACKAGES:BOOL=OFF;-DTrilinos_ENABLE_ALL_OPTIONAL_PACKAGES:BOOL=OFF;-DTrilinos_ENABLE_ALL_FORWARD_DEP_PACKAGES:BOOL=OFF" ^
    "C:/Users/Mark Berrill/Desktop/TPLs/tpl-builder"


:: "Visual Studio 10 Win64"
:: "NMake Makefiles"

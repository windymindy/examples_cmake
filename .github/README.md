These is a memo on how

* to [package][package_external] an external library as if it was built with cmake;
* to find and to use [transitive][find_dependency] package dependencies;
* to [fix debug symbols][fix_debug_symbols] output location on Windows and install them along with targets.

**project_0** is to kick off and simulate non cmake artifacts provided by a third party.
It produces a static library and a shared library. No cmake package.

```bash

cd examples_cmake

cmake -S project_0 -B build_0 -G "Ninja Multi-Config";
cmake --build build_0 --config Debug;
cmake --build build_0 --config Release;
cmake --install build_0 --config Debug --prefix installed/project_0;
cmake --install build_0 --config Release --prefix installed/project_0;

# for single, non multiple configuration generators
cmake -S project_0 -B build_0_release -G Ninja -DCMAKE_BUILD_TYPE=Release;
cmake --build build_0_release;
cmake --install build_0_release --prefix installed/project_0;

```

Package the artifacts with **project_1**.

```bash

# use -Dproject_0_location="" to point cmake to the files
cmake -B build_1 -S project_1 -G "Ninja Multi-Config";
cmake --install build_1 --config Debug --prefix installed/project_1;
cmake --install build_1 --config Release --prefix installed/project_1;


```

**project_2** uses **library_1** and **library_2** from the package and produces a static library **library_3**.

```bash

# export project_1_DIR="installed/project_1/package";
# $env:project_1_DIR="installed\project_1\package";
cmake -B build_2 -S project_2 -G "Ninja Multi-Config";
cmake --build build_2 --config Debug;
cmake --build build_2 --config Release;
cmake --install build_2 --config Debug --prefix installed/project_2;
cmake --install build_2 --config Release --prefix installed/project_2;

./build_2/Debug/test_1;
./build_2/Release/test_1;

```

**project_3** creates an executable **executable_1** that uses static **library_3** and
therefore requires linking with the libraries from the **project_1** package.
This dependency is defined by the [**project_2** package][find_dependency].

```bash

# export CMAKE_PREFIX_PATH="installed/project_2/package";
# $env:CMAKE_PREFIX_PATH="installed\project_2\package";
cmake -B build_3 -S project_3 -G "Ninja Multi-Config";
cmake --build build_3 --config Debug;
cmake --install build_3 --config Debug --prefix installed/project_3;

# export LD_LIBRARY_PATH="${PWD}/installed/project_3/executables"
./installed/project_3/executables/executable_1;

cmake --build build_3 --config Release;
cmake --install build_3 --config Release --prefix installed/project_3;

./installed/project_3/executables/executable_1;

```

[package_external]: ../project_1/CMakeLists.txt#L108
[find_dependency]: ../project_2/CMakeLists.txt#L52
[fix_debug_symbols]: ../cmake/fix_debug_symbols.cmake

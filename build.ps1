#!/usr/bin/env pwsh

mkdir build
cd build
#cmake -G "Visual Studio 15 2017 Win64" ..
cmake -G "Ninja" "-DCMAKE_BUILD_TYPE=Release" "-DCMAKE_TOOLCHAIN_FILE=$env:VCPKG_ROOT\scripts\buildsystems\vcpkg.cmake" "-DVCPKG_TARGET_TRIPLET=x64-windows" ..
cmake --build . --target install #--config Release
cd ..

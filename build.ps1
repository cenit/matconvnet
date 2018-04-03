#!/usr/bin/env pwsh

New-Item -Path .\build -ItemType directory -Force
Set-Location build
cmake -G "Visual Studio 15 2017 Win64" "-DCMAKE_TOOLCHAIN_FILE=$env:VCPKG_ROOT\scripts\buildsystems\vcpkg.cmake" "-DVCPKG_TARGET_TRIPLET=x64-windows" -T host=x64 ..
cmake --build . --config Release
#cmake -G "Ninja" "-DCMAKE_BUILD_TYPE=Release" "-DCMAKE_TOOLCHAIN_FILE=$env:VCPKG_ROOT\scripts\buildsystems\vcpkg.cmake" "-DVCPKG_TARGET_TRIPLET=x64-windows" ..
#cmake --build .
Set-Location ..

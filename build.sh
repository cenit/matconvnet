#!/bin/bash

#if [[ "$OSTYPE" == "darwin"* && "$1" == "gcc" ]]; then
if [[ "$OSTYPE" == "darwin"* ]]; then
 export CC="/usr/local/bin/gcc-7"
 export CXX="/usr/local/bin/g++-7"
 export BLAS_DIR="/usr/local/Cellar/openblas/0.2.20_1"
fi

mkdir -p build
cd build
cmake ..
cmake --build .
#make VERBOSE=1
cd ..

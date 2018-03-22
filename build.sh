#!/bin/bash

#if [[ "$OSTYPE" == "darwin"* && "$1" == "gcc" ]]; then
if [[ "$OSTYPE" == "darwin"* ]]; then
 export CC="/usr/local/bin/gcc-7"
 export CXX="/usr/local/bin/g++-7"
fi

mkdir -p build
cd build
cmake .. -DMATLAB_BLAS_LIBRARY=/Applications/MATLAB_R2017b.app/bin/maci64/libmwblas.dylib
cmake --build . --target install
#make VERBOSE=1
cd ..

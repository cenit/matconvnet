cmake_minimum_required (VERSION 3.5)
project (matconvnet)
set(CMAKE_CXX_STANDARD 11)

set(default_build_type "Release")
if(NOT CMAKE_BUILD_TYPE AND NOT CMAKE_CONFIGURATION_TYPES)
  message(STATUS "Setting build type to '${default_build_type}' as none was specified.")
  set(CMAKE_BUILD_TYPE "${default_build_type}" CACHE
      STRING "Choose the type of build." FORCE)
  set_property(CACHE CMAKE_BUILD_TYPE PROPERTY STRINGS
    "Debug" "Release" "MinSizeRel" "RelWithDebInfo")
endif()

### Set output directories on a per-configuration base
# Single configuration
#set( CMAKE_RUNTIME_OUTPUT_DIRECTORY ${CMAKE_SOURCE_DIR}/matlab )
set( CMAKE_LIBRARY_OUTPUT_DIRECTORY ${CMAKE_SOURCE_DIR}/matlab ) # mex on linux/mac are output as library
# Multi configuration
foreach( OUTPUTCONFIG ${CMAKE_CONFIGURATION_TYPES} )
  string( TOUPPER ${OUTPUTCONFIG} OUTPUTCONFIG )
  set( CMAKE_RUNTIME_OUTPUT_DIRECTORY_${OUTPUTCONFIG} ${CMAKE_SOURCE_DIR}/matlab ) # mex on windows are output as runtime
endforeach( OUTPUTCONFIG CMAKE_CONFIGURATION_TYPES )

find_package(Matlab COMPONENTS MX_LIBRARY REQUIRED)
find_package(JPEG REQUIRED)
find_package(OpenMP REQUIRED)
if(OPENMP_FOUND)
  set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} ${OpenMP_CXX_FLAGS}")
endif()

add_definitions(-DENABLE_DOUBLE)
include_directories(${JPEG_INCLUDE_DIR} ${Matlab_INCLUDE_DIRS})
include_directories(${Matlab_ROOT_DIR}/toolbox/distcomp/gpu/extern/include)

if(MSVC)
  set(CMAKE_WINDOWS_EXPORT_ALL_SYMBOLS TRUE)
  add_definitions(-D_CRT_SECURE_NO_DEPRECATE)
  if(CMAKE_CXX_FLAGS MATCHES "/W[0-4]")
    string(REGEX REPLACE "/W[0-4]" "/W1" CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS}")
  endif()
  set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} /wd4068")
endif()

# Snippet to locate the matlab-blas library to link
if(NOT Matlab_BLAS_LIBRARY)
  include(${CMAKE_ROOT}/Modules/SelectLibraryConfigurations.cmake)
  find_library(Matlab_BLAS_LIBRARY_RELEASE NAMES mwblas  libmwblas  PATHS ${Matlab_ROOT_DIR} PATH_SUFFIXES extern/lib/win64/microsoft bin/maci64 bin/glnxa64)
  find_library(Matlab_BLAS_LIBRARY_DEBUG   NAMES mwblasd libmwblasd PATHS ${Matlab_ROOT_DIR} PATH_SUFFIXES extern/lib/win64/microsoft bin/maci64 bin/glnxa64)
  select_library_configurations(Matlab_BLAS)
endif()

add_library(matconvnet SHARED
 matlab/src/bits/data.cpp
 matlab/src/bits/datamex.cpp
 matlab/src/bits/nnconv.cpp
 matlab/src/bits/nnbias.cpp
 matlab/src/bits/nnfullyconnected.cpp
 matlab/src/bits/nnsubsample.cpp
 matlab/src/bits/nnpooling.cpp
 matlab/src/bits/nnnormalize.cpp
 matlab/src/bits/nnnormalizelp.cpp
 matlab/src/bits/nnbnorm.cpp
 matlab/src/bits/nnbilinearsampler.cpp
 matlab/src/bits/nnroipooling.cpp
 matlab/src/bits/impl/im2row_cpu.cpp
 matlab/src/bits/impl/copy_cpu.cpp
 matlab/src/bits/impl/tinythread.cpp
 matlab/src/bits/impl/imread_libjpeg.cpp
 matlab/src/bits/imread.cpp
)
set_property(TARGET matconvnet PROPERTY POSITION_INDEPENDENT_CODE ON)
target_link_libraries(matconvnet ${Matlab_BLAS_LIBRARY} ${JPEG_LIBRARY} ${Matlab_MEX_LIBRARY} ${Matlab_MX_LIBRARY})

set(CUDA_BIN_PATH         "C:/Program Files/NVIDIA GPU Computing Toolkit/CUDA/v6.5/bin")
set(CUDA_TOOLKIT_ROOT_DIR "C:/Program Files/NVIDIA GPU Computing Toolkit/CUDA/v6.5")
find_package(CUDA)

if(NOT MSVC)
  set(VL_TMOVE    "matlab/src/vl_tmove.cpp")
  set(VL_TMOVE_CU "matlab/src/vl_tmove.cu")
endif()

list(APPEND cuda_files
  matlab/src/vl_cudatool.cu
  matlab/src/vl_imreadjpeg.cu
  matlab/src/vl_imreadjpeg_old.cu
  matlab/src/vl_nnbilinearsampler.cu
  matlab/src/vl_nnbnorm.cu
  matlab/src/vl_nnconv.cu
  matlab/src/vl_nnconvt.cu
  matlab/src/vl_nnnormalize.cu
  matlab/src/vl_nnnormalizelp.cu
  matlab/src/vl_nnpool.cu
  matlab/src/vl_nnroipool.cu
  matlab/src/vl_taccummex.cu
  ${VL_TMOVE_CU}
)

list(APPEND vl_files
  matlab/src/vl_imreadjpeg.cpp
  matlab/src/vl_imreadjpeg_old.cpp
  matlab/src/vl_nnbilinearsampler.cpp
  matlab/src/vl_nnbnorm.cpp
  matlab/src/vl_nnconv.cpp
  matlab/src/vl_nnconvt.cpp
  matlab/src/vl_nnnormalize.cpp
  matlab/src/vl_nnnormalizelp.cpp
  matlab/src/vl_nnpool.cpp
  matlab/src/vl_nnroipool.cpp
  matlab/src/vl_taccummex.cpp
  ${VL_TMOVE}
)

foreach(src ${vl_files})
  get_filename_component(mex ${src} NAME_WE)
  matlab_add_mex(NAME ${mex} SRC ${src} LINK_TO ${JPEG_LIBRARY} matconvnet ${Matlab})
endforeach()

if(CUDA_FOUND)
  add_custom_target(cudaall)
  foreach(cusrc ${cuda_files})
    #set(CUDA_NVCC_FLAGS -Xcompiler -fPIC -use_fast_math -gencode=arch=compute_20,code="sm_20,compute_20" --ptxas-options=-v -DMATLAB_MEX_FILE -G -g -O0)
    set(CUDA_NVCC_FLAGS -Xcompiler -fPIC -use_fast_math -gencode=arch=compute_11,code="sm_11,compute_11" --ptxas-options=-v -DMATLAB_MEX_FILE -G -g -O0)
    get_filename_component(tgt ${cusrc} NAME_WE)
    cuda_compile(${tgt}_cu ${cusrc} SHARED)
    add_library(${tgt}_cu SHARED ${cusrc})
    target_link_libraries(${tgt}_cu ${MATLAB_LIBRARIES} ${CUDA_LIBRARIES})
    set_target_properties(${tgt}_cu PROPERTIES PREFIX "" LINKER_LANGUAGE CXX LINK_FLAGS /export:mexFunction)

    if(WIN32)
      if(CMAKE_CL_64)
        set_target_properties(${tgt}_cu PROPERTIES SUFFIX .mexw64)
      else()
        set_target_properties(${tgt}_cu PROPERTIES SUFFIX .mexw32)
      endif()
    else()
      if(CMAKE_SIZEOF_VOID_P MATCHES "8")
        set_target_properties(${tgt}_cu PROPERTIES SUFFIX .mexa64 PREFIX "")
      else()
        set_target_properties(${tgt}_cu PROPERTIES SUFFIX .mexglx PREFIX "")
      endif()
    endif()
    add_dependencies(cudaall ${tgt}_cu)
  endforeach()
endif()
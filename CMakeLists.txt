cmake_minimum_required (VERSION 3.5)
set(CMAKE_CXX_STANDARD 11)
project (matconvnet)

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
set( CMAKE_RUNTIME_OUTPUT_DIRECTORY ${CMAKE_SOURCE_DIR}/matlab )
# Multi configuration
foreach( OUTPUTCONFIG ${CMAKE_CONFIGURATION_TYPES} )
    string( TOUPPER ${OUTPUTCONFIG} OUTPUTCONFIG )
    set( CMAKE_RUNTIME_OUTPUT_DIRECTORY_${OUTPUTCONFIG} ${CMAKE_SOURCE_DIR}/matlab )
endforeach( OUTPUTCONFIG CMAKE_CONFIGURATION_TYPES )

find_package(JPEG REQUIRED)
if (NOT APPLE)
  find_package(BLAS REQUIRED)
else()
  find_path(BLAS_INCLUDE_DIR cblas.h
    /usr/include
    /usr/local/include
  )
  find_library(BLAS_LIBRARIES libblas.dylib
    /usr/lib
    /usr/local/lib
  )
  if (BLAS_INCLUDE_DIR AND BLAS_LIBRARIES)
    message(STATUS "OpenBLAS found: ${BLAS_INCLUDE_DIR}")
  else()
    message(ERROR "OpenBLAS not found")
  endif()
endif()
find_package(OpenMP REQUIRED)
if (OPENMP_FOUND)
  set (CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} ${OpenMP_CXX_FLAGS}")
endif()

add_definitions(-DENABLE_DOUBLE)
include_directories(${JPEG_INCLUDE_DIR})
include_directories(${BLAS_INCLUDE_DIR})  # not defined by FindBLAS...!!! fix!

if(MSVC)
  set(CMAKE_WINDOWS_EXPORT_ALL_SYMBOLS TRUE)
  add_definitions(-D_CRT_SECURE_NO_DEPRECATE)
  if(CMAKE_CXX_FLAGS MATCHES "/W[0-4]")
    string(REGEX REPLACE "/W[0-4]" "/W1" CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS}")
  endif()
  set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} /wd4068")
endif()

add_library(matconvnet SHARED
 matlab/src/bits/data.cpp
# matlab/src/bits/datamex.cpp
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
target_link_libraries(matconvnet ${JPEG_LIBRARY} ${BLAS_LIBRARIES})

if(NOT MSVC)
  set(VL_TMOVE "vl_tmove" "matlab/src/vl_tmove.cpp")
endif()

list(APPEND vl_files
vl_imreadjpeg        matlab/src/vl_imreadjpeg.cpp
vl_imreadjpeg_old    matlab/src/vl_imreadjpeg_old.cpp
vl_nnbilinearsampler matlab/src/vl_nnbilinearsampler.cpp
vl_nnbnorm           matlab/src/vl_nnbnorm.cpp
vl_nnconv            matlab/src/vl_nnconv.cpp
vl_nnconvt           matlab/src/vl_nnconvt.cpp
vl_nnnormalize       matlab/src/vl_nnnormalize.cpp
vl_nnnormalizelp     matlab/src/vl_nnnormalizelp.cpp
vl_nnpool            matlab/src/vl_nnpool.cpp
vl_nnroipool         matlab/src/vl_nnroipool.cpp
vl_taccummex         matlab/src/vl_taccummex.cpp
${VL_TMOVE}
)

list(LENGTH vl_files size)
math(EXPR size "${size} - 1")
foreach(val RANGE 0 ${size} 2)
  math(EXPR nextval "${val} + 1")
  list(GET vl_files ${val} mex)
  list(GET vl_files ${nextval} src)
  add_library(${mex} ${src})
  set_property(TARGET ${mex} PROPERTY POSITION_INDEPENDENT_CODE ON)
  target_link_libraries(${mex} ${JPEG_LIBRARY} matconvnet)
endforeach()

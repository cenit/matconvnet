cmake_minimum_required (VERSION 3.10)
project (matconvnet)

set(default_build_type "Release")
if(NOT CMAKE_BUILD_TYPE AND NOT CMAKE_CONFIGURATION_TYPES)
  message(STATUS "Setting build type to '${default_build_type}' as none was specified.")
  set(CMAKE_BUILD_TYPE "${default_build_type}" CACHE
      STRING "Choose the type of build." FORCE)
  set_property(CACHE CMAKE_BUILD_TYPE PROPERTY STRINGS
    "Debug" "Release" "MinSizeRel" "RelWithDebInfo")
endif()

find_package(Matlab COMPONENTS MX_LIBRARY REQUIRED)
find_package(JPEG REQUIRED)
find_package(OpenMP REQUIRED)
if (OPENMP_FOUND)
  set (CMAKE_C_FLAGS "${CMAKE_C_FLAGS} ${OpenMP_C_FLAGS}")
endif()

include_directories(${JPEG_INCLUDE_DIR})

if(MSVC)
  add_definitions(-D_CRT_SECURE_NO_DEPRECATE)
  if(CMAKE_C_FLAGS MATCHES "/W[0-4]")
    string(REGEX REPLACE "/W[0-4]" "/W1" CMAKE_C_FLAGS "${CMAKE_C_FLAGS}")
  endif()
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



list(APPEND vl_files
vl_nnconv            matlab/src/vl_nnconv.cpp
vl_nnconvt           matlab/src/vl_nnconvt.cpp
vl_nnpool            matlab/src/vl_nnpool.cpp
vl_nnnormalize       matlab/src/vl_nnnormalize.cpp
vl_nnnormalizelp     matlab/src/vl_nnnormalizelp.cpp
vl_nnbnorm           matlab/src/vl_nnbnorm.cpp
vl_nnbilinearsampler matlab/src/vl_nnbilinearsampler.cpp
vl_nnroipool         matlab/src/vl_nnroipool.cpp
vl_taccummex         matlab/src/vl_taccummex.cpp
vl_tmove             matlab/src/vl_tmove.cpp
vl_imreadjpeg        matlab/src/vl_imreadjpeg.cpp
vl_imreadjpeg_old    matlab/src/vl_imreadjpeg_old.cpp
)

list(LENGTH vl_files size)
math(EXPR size "${size} - 1")
foreach(val RANGE 0 ${size} 2)
  math(EXPR nextval "${val} + 1")
  list(GET vl_files ${val} mex)
  list(GET vl_files ${nextval} src)
  matlab_add_mex(NAME ${mex} SRC ${src} LINK_TO matconvnet ${JPEG_LIBRARY})
  install(TARGETS ${mex} DESTINATION ${CMAKE_SOURCE_DIR}/matlab/mex/${Matlab_MEX_EXTENSION}/)
endforeach()

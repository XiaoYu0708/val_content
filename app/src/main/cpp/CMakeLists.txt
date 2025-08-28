cmake_minimum_required(VERSION 3.22.1)

project("val_content")

# 添加編譯器標誌以支援 16KB 記憶體分頁
set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -fno-omit-frame-pointer")
set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -fno-omit-frame-pointer")

# 針對 ARM64 平台添加特定標誌
if(ANDROID_ABI STREQUAL "arm64-v8a")
    set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -mcpu=generic")
    set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -mcpu=generic")
endif()

add_library(
    val_content
    SHARED
    memory_utils.h
    native-lib.cpp
)

target_link_libraries(
    val_content
    android
    log
)

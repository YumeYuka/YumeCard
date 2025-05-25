cmake_minimum_required(VERSION 3.31)
project(YumeCard)

set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED True)

if (MSVC)
    set(CMAKE_MSVC_RUNTIME_LIBRARY "MultiThreaded$<$<CONFIG:Debug>:Debug>")
endif ()

add_executable(YumeCard core/main.cpp)

if (WIN32 AND MSVC) # 只针对 MSVC on Windows
    target_link_libraries(YumeCard PRIVATE
    )
endif ()

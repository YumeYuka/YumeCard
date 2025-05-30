cmake_minimum_required(VERSION 3.16)

# 设置vcpkg triplet和工具链文件
set(VCPKG_TARGET_TRIPLET "x64-mingw-dynamic" CACHE STRING "Vcpkg target triplet")
set(CMAKE_TOOLCHAIN_FILE "C:/tool/vcpkg/scripts/buildsystems/vcpkg.cmake"
        CACHE STRING "Vcpkg toolchain file")

# 禁用vcpkg的manifest模式
set(VCPKG_MANIFEST_MODE OFF CACHE BOOL "")

# 设置项目名称和版本
project(YumeCard VERSION 1.0.0 LANGUAGES CXX)

# 设置依赖库路径
set(CURL_DIR "C:/tool/vcpkg/installed/x64-mingw-dynamic/share/curl")
set(nlohmann_json_DIR "C:/tool/vcpkg/installed/x64-mingw-dynamic/share/nlohmann_json")

# 查找依赖库
find_package(ZLIB REQUIRED)
find_package(CURL CONFIG REQUIRED)
find_package(nlohmann_json CONFIG REQUIRED)

# 配置版本文件
configure_file(
        "${CMAKE_SOURCE_DIR}/include/version.hpp.in"
        "${CMAKE_BINARY_DIR}/include/version.hpp"
)

# 编译器设置
if(CMAKE_CXX_COMPILER_ID MATCHES "GNU|Clang")
        add_compile_options(-Wall -Wextra -pedantic)
        if(CMAKE_BUILD_TYPE STREQUAL "Release")
                add_compile_options(-O3)
        endif()
else()
        message(FATAL_ERROR "不支持的编译器: ${CMAKE_CXX_COMPILER_ID}。请使用GCC或Clang。")
endif()

# 源文件
set(SOURCES
        src/main.cpp
        src/version.cpp # Added version.cpp
)

# 头文件
set(HEADERS
        include/head.hpp
        include/github_api.hpp
        include/read_config.hpp
        include/set_config.hpp
        include/github_subscriber.hpp
        include/screenshot.hpp
        include/platform_utils.hpp
        include/system_info.hpp # Added system_info.hpp
)

# 创建可执行文件 (moved before target_compile_definitions)
add_executable(YumeCard ${SOURCES} ${HEADERS})

# 配置版本相关的 CMake 变量
string(TIMESTAMP BUILD_DATE_STR "%Y-%m-%d %H:%M:%S")
set(GIT_COMMIT_STR "N/A") # Placeholder for Git commit; manual update or simple git command if allowed

# Attempt to get Git commit (optional, might fail if not in a git repo or git not found)
find_package(Git QUIET)
if(GIT_FOUND)
        execute_process(
                COMMAND ${GIT_EXECUTABLE} rev-parse --short HEAD
                WORKING_DIRECTORY ${CMAKE_SOURCE_DIR}
                OUTPUT_VARIABLE GIT_COMMIT_STR_TEMP
                OUTPUT_STRIP_TRAILING_WHITESPACE
                ERROR_QUIET
        )
        if(GIT_COMMIT_STR_TEMP)
                set(GIT_COMMIT_STR "${GIT_COMMIT_STR_TEMP}")
        endif()
endif()

# These definitions will be used by version.cpp
target_compile_definitions(YumeCard PRIVATE
        PROJECT_NAME_STR="${PROJECT_NAME}"
        PROJECT_VERSION_STR="${PROJECT_VERSION}"
        PROJECT_VERSION_MAJOR_STR="${PROJECT_VERSION_MAJOR}"
        PROJECT_VERSION_MINOR_STR="${PROJECT_VERSION_MINOR}"
        PROJECT_VERSION_PATCH_STR="${PROJECT_VERSION_PATCH}"
        CONFIG_BUILD_DATE="${BUILD_DATE_STR}"
        CONFIG_GIT_COMMIT="${GIT_COMMIT_STR}"
        CONFIG_TARGET_PLATFORM="${CMAKE_SYSTEM_NAME}"
        CONFIG_TARGET_ARCH="${CMAKE_SYSTEM_PROCESSOR}"
        CONFIG_COMPILER_ID="${CMAKE_CXX_COMPILER_ID}"
        CONFIG_COMPILER_VERSION="${CMAKE_CXX_COMPILER_VERSION}"
)

# 包含目录
target_include_directories(YumeCard PRIVATE
        ${CMAKE_SOURCE_DIR}/include
        ${CMAKE_BINARY_DIR}/include
)

# 链接库
target_link_libraries(YumeCard PRIVATE CURL::libcurl)
target_link_libraries(YumeCard PRIVATE nlohmann_json::nlohmann_json)
target_link_libraries(YumeCard PRIVATE ZLIB::ZLIB)

# 输出构建信息
message(STATUS "=== YumeCard 构建配置 ===")
message(STATUS "项目版本: ${PROJECT_VERSION}")
message(STATUS "编译器: ${CMAKE_CXX_COMPILER_ID} ${CMAKE_CXX_COMPILER_VERSION}")
message(STATUS "构建类型: ${CMAKE_BUILD_TYPE}")
message(STATUS "目标平台: ${CMAKE_SYSTEM_NAME}")
message(STATUS "目标架构: ${CMAKE_SYSTEM_PROCESSOR}")
if(CMAKE_TOOLCHAIN_FILE)
        message(STATUS "vcpkg工具链: ${CMAKE_TOOLCHAIN_FILE}")
else()
        message(STATUS "vcpkg工具链: 未使用")
endif()
message(STATUS "========================")

cmake_minimum_required(VERSION 3.16)

# Project setup
project(YumeCard VERSION 1.0.0 LANGUAGES CXX)

# C++ standard
set(CMAKE_CXX_STANDARD 23)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS OFF)

# Static linking configuration
set(CMAKE_MSVC_RUNTIME_LIBRARY "MultiThreaded$<$<CONFIG:Debug>:Debug>")
set(CMAKE_FIND_LIBRARY_SUFFIXES .a .lib ${CMAKE_FIND_LIBRARY_SUFFIXES})

if (CMAKE_CXX_COMPILER_ID MATCHES "GNU")
    set(CMAKE_EXE_LINKER_FLAGS "${CMAKE_EXE_LINKER_FLAGS} -static-libgcc -static-libstdc++")
elseif (UNIX AND NOT APPLE)
    set(CMAKE_POSITION_INDEPENDENT_CODE OFF)
endif ()

# Compiler flags
if (CMAKE_CXX_COMPILER_ID MATCHES "GNU|Clang")
    add_compile_options(-Wall -Wextra -Wpedantic)
    if (CMAKE_BUILD_TYPE STREQUAL "Release")
        add_compile_options(-O3)
    endif ()
else ()
    message(FATAL_ERROR "Unsupported compiler: ${CMAKE_CXX_COMPILER_ID}. Use GCC or Clang.")
endif ()

# Find dependencies
find_package(ZLIB REQUIRED)
find_package(CURL REQUIRED)
find_package(nlohmann_json CONFIG REQUIRED)

# Version configuration
configure_file(
        "${CMAKE_SOURCE_DIR}/include/version.hpp.in"
        "${CMAKE_BINARY_DIR}/include/version.hpp"
)

# Source and header files
set(SOURCES
        src/main.cpp
        src/version.cpp
)

set(HEADERS
        include/head.hpp
        include/github_api.hpp
        include/read_config.hpp
        include/set_config.hpp
        include/github_subscriber.hpp
        include/screenshot.hpp
        include/platform_utils.hpp
        include/system_info.hpp
)

# Executable
add_executable(${PROJECT_NAME} ${SOURCES} ${HEADERS})

# Git commit information
find_package(Git QUIET)
set(GIT_COMMIT_STR "N/A")
if (GIT_FOUND)
    execute_process(
            COMMAND ${GIT_EXECUTABLE} rev-parse --short HEAD
            WORKING_DIRECTORY ${CMAKE_SOURCE_DIR}
            OUTPUT_VARIABLE GIT_COMMIT_STR_TEMP
            OUTPUT_STRIP_TRAILING_WHITESPACE
            ERROR_QUIET
    )
    if (GIT_COMMIT_STR_TEMP)
        set(GIT_COMMIT_STR "${GIT_COMMIT_STR_TEMP}")
    endif ()
endif ()

# Compile definitions
string(TIMESTAMP BUILD_DATE_STR "%Y-%m-%d %H:%M:%S")
target_compile_definitions(${PROJECT_NAME} PRIVATE
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

# Include directories
target_include_directories(${PROJECT_NAME} PRIVATE
        ${CMAKE_SOURCE_DIR}/include
        ${CMAKE_BINARY_DIR}/include
)

# Link libraries
target_link_libraries(${PROJECT_NAME} PRIVATE
        CURL::libcurl
        nlohmann_json::nlohmann_json
        ZLIB::ZLIB
)

if (WIN32)
    target_link_libraries(${PROJECT_NAME} PRIVATE ws2_32 wldap32 crypt32 normaliz winmm)
elseif (UNIX AND NOT APPLE)
    target_link_libraries(${PROJECT_NAME} PRIVATE pthread dl)
endif ()

# Build information
message(STATUS "=== ${PROJECT_NAME} Build Configuration ===")
message(STATUS "Version: ${PROJECT_VERSION}")
message(STATUS "Compiler: ${CMAKE_CXX_COMPILER_ID} ${CMAKE_CXX_COMPILER_VERSION}")
message(STATUS "Build Type: ${CMAKE_BUILD_TYPE}")
message(STATUS "Platform: ${CMAKE_SYSTEM_NAME}")
message(STATUS "Architecture: ${CMAKE_SYSTEM_PROCESSOR}")
message(STATUS "Toolchain: ${CMAKE_TOOLCHAIN_FILE}")
message(STATUS "==========================")
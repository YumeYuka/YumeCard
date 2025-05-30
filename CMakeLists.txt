cmake_minimum_required(VERSION 3.16)

# 版本信息设置
if (DEFINED YUMECARD_VERSION)
        set(PROJECT_VERSION ${YUMECARD_VERSION})
else ()
        set(PROJECT_VERSION "0.1.0")
endif ()

project(YumeCard VERSION ${PROJECT_VERSION} LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED True)

# 生成版本头文件
# 获取Git commit信息
find_package(Git QUIET)
if (GIT_FOUND)
        execute_process(
                COMMAND ${GIT_EXECUTABLE} rev-parse --short HEAD
                WORKING_DIRECTORY ${CMAKE_SOURCE_DIR}
                OUTPUT_VARIABLE GIT_COMMIT
                ERROR_QUIET
                OUTPUT_STRIP_TRAILING_WHITESPACE
        )
        if (NOT GIT_COMMIT)
                set(GIT_COMMIT "unknown")
        endif ()
else ()
        set(GIT_COMMIT "unknown")
endif ()

# 获取构建日期
string(TIMESTAMP BUILD_DATE "%Y-%m-%d %H:%M:%S UTC" UTC)

configure_file(
        "${CMAKE_SOURCE_DIR}/include/version.hpp.in"
        "${CMAKE_BINARY_DIR}/include/version.hpp"
        @ONLY
)

# 平台和架构检测
message(STATUS "Building for ${CMAKE_SYSTEM_NAME} on ${CMAKE_SYSTEM_PROCESSOR}")

# 详细的平台信息输出
if (CMAKE_SIZEOF_VOID_P EQUAL 8)
        message(STATUS "Target architecture: 64-bit")
        set(ARCH_BITS "64")
else ()
        message(STATUS "Target architecture: 32-bit")
        set(ARCH_BITS "32")
endif ()

# 编译器信息
message(STATUS "Compiler: ${CMAKE_CXX_COMPILER_ID} ${CMAKE_CXX_COMPILER_VERSION}")
if (CMAKE_BUILD_TYPE)
        message(STATUS "Build type: ${CMAKE_BUILD_TYPE}")
endif ()

# 交叉编译检测
if (CMAKE_CROSSCOMPILING)
        message(STATUS "Cross-compiling for ${CMAKE_SYSTEM_NAME}/${CMAKE_SYSTEM_PROCESSOR}")
endif ()

# 设置输出目录结构
set(CMAKE_RUNTIME_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/bin)
set(CMAKE_LIBRARY_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/lib)
set(CMAKE_ARCHIVE_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/lib)

# 多配置下的输出目录
foreach (OUTPUTCONFIG ${CMAKE_CONFIGURATION_TYPES})
        string(TOUPPER ${OUTPUTCONFIG} OUTPUTCONFIG)
        set(CMAKE_RUNTIME_OUTPUT_DIRECTORY_${OUTPUTCONFIG} ${CMAKE_BINARY_DIR}/bin)
        set(CMAKE_LIBRARY_OUTPUT_DIRECTORY_${OUTPUTCONFIG} ${CMAKE_BINARY_DIR}/lib)
        set(CMAKE_ARCHIVE_OUTPUT_DIRECTORY_${OUTPUTCONFIG} ${CMAKE_BINARY_DIR}/lib)
endforeach ()

# vcpkg 工具链文件路径设置（支持跨平台）
if (NOT DEFINED CMAKE_TOOLCHAIN_FILE)
        if (WIN32)
                # Windows平台的vcpkg路径
                if (EXISTS "C:/tool/vcpkg/scripts/buildsystems/vcpkg.cmake")
                        set(CMAKE_TOOLCHAIN_FILE "C:/tool/vcpkg/scripts/buildsystems/vcpkg.cmake" CACHE STRING "Vcpkg toolchain file")
                elseif (EXISTS "C:/vcpkg/scripts/buildsystems/vcpkg.cmake")
                        set(CMAKE_TOOLCHAIN_FILE "C:/vcpkg/scripts/buildsystems/vcpkg.cmake" CACHE STRING "Vcpkg toolchain file")
                elseif (DEFINED ENV{VCPKG_ROOT})
                        set(CMAKE_TOOLCHAIN_FILE "$ENV{VCPKG_ROOT}/scripts/buildsystems/vcpkg.cmake" CACHE STRING "Vcpkg toolchain file")
                endif ()
        elseif (UNIX)
                # Linux/macOS平台的vcpkg路径
                if (EXISTS "/usr/local/share/vcpkg/scripts/buildsystems/vcpkg.cmake")
                        set(CMAKE_TOOLCHAIN_FILE "/usr/local/share/vcpkg/scripts/buildsystems/vcpkg.cmake" CACHE STRING "Vcpkg toolchain file")
                elseif (EXISTS "$ENV{HOME}/vcpkg/scripts/buildsystems/vcpkg.cmake")
                        set(CMAKE_TOOLCHAIN_FILE "$ENV{HOME}/vcpkg/scripts/buildsystems/vcpkg.cmake" CACHE STRING "Vcpkg toolchain file")
                elseif (DEFINED ENV{VCPKG_ROOT})
                        set(CMAKE_TOOLCHAIN_FILE "$ENV{VCPKG_ROOT}/scripts/buildsystems/vcpkg.cmake" CACHE STRING "Vcpkg toolchain file")
                endif ()
        endif ()
endif ()

# 依赖库查找
message(STATUS "Finding required dependencies...")

# 查找CURL库
find_package(CURL REQUIRED)
if (CURL_FOUND)
        message(STATUS "Found CURL: ${CURL_VERSION_STRING}")
        message(STATUS "  CURL_LIBRARIES: ${CURL_LIBRARIES}")
        message(STATUS "  CURL_INCLUDE_DIRS: ${CURL_INCLUDE_DIRS}")
else ()
        message(FATAL_ERROR "CURL library not found. Please install curl via vcpkg: vcpkg install curl")
endif ()

# 查找nlohmann_json库
find_package(nlohmann_json CONFIG REQUIRED)
if (nlohmann_json_FOUND)
        message(STATUS "Found nlohmann_json")
else ()
        message(FATAL_ERROR "nlohmann_json library not found. Please install nlohmann-json via vcpkg: vcpkg install nlohmann-json")
endif ()

# 平台特定的依赖检查
if (WIN32)
        # Windows特定的依赖
        message(STATUS "Configuring Windows-specific dependencies")
elseif (UNIX AND NOT APPLE)
        # Linux特定的依赖
        message(STATUS "Configuring Linux-specific dependencies")
        find_package(Threads REQUIRED)
        find_package(PkgConfig QUIET)
elseif (APPLE)
        # macOS特定的依赖
        message(STATUS "Configuring macOS-specific dependencies")
        find_package(Threads REQUIRED)
endif ()

# 编译器特定设置
if (MSVC)
        # MSVC编译器设置
        set(CMAKE_MSVC_RUNTIME_LIBRARY "MultiThreaded$<$<CONFIG:Debug>:Debug>")
        add_compile_options(/W4)
        add_compile_definitions(_CRT_SECURE_NO_WARNINGS)
        # 启用多核编译
        add_compile_options(/MP)
        # 架构特定优化
        if (CMAKE_GENERATOR_PLATFORM STREQUAL "x64")
                add_compile_options(/favor:INTEL64)
        elseif (CMAKE_GENERATOR_PLATFORM STREQUAL "ARM64")
                add_compile_options(/arch:ARMv8)
        endif ()
elseif (CMAKE_CXX_COMPILER_ID STREQUAL "GNU" OR CMAKE_CXX_COMPILER_ID STREQUAL "Clang")
        # GCC/Clang编译器设置
        add_compile_options(-Wall -Wextra -pedantic)
        if (CMAKE_BUILD_TYPE STREQUAL "Release")
                add_compile_options(-O3)
                # 架构特定优化
                if (CMAKE_SYSTEM_PROCESSOR MATCHES "x86_64|AMD64")
                        add_compile_options(-march=x86-64 -mtune=generic)
                elseif (CMAKE_SYSTEM_PROCESSOR MATCHES "aarch64|ARM64")
                        add_compile_options(-march=armv8-a -mtune=generic)
                elseif (CMAKE_SYSTEM_PROCESSOR MATCHES "arm")
                        add_compile_options(-march=armv7-a -mfpu=neon -mtune=generic)
                endif ()
        endif ()
        # 启用所有合理的警告
        add_compile_options(-Wno-unused-parameter)
endif ()

# 平台特定的链接设置
if (WIN32)
        # Windows特定设置
        add_compile_definitions(NOMINMAX WIN32_LEAN_AND_MEAN)
elseif (UNIX AND NOT APPLE)
        # Linux特定设置
        find_package(Threads REQUIRED)
elseif (APPLE)
        # macOS特定设置
        find_package(Threads REQUIRED)
endif ()

# 包含目录
include_directories(${CMAKE_SOURCE_DIR}/include)
include_directories(${CMAKE_BINARY_DIR}/include) # 包含生成的版本头文件

# 源文件和头文件
set(YUMECARD_SOURCES
        src/main.cpp
)

set(YUMECARD_HEADERS
        include/head.hpp
        include/github_api.hpp
        include/read_config.hpp
        include/set_config.hpp
        include/github_subscriber.hpp
        include/screenshot.hpp
        include/platform_utils.hpp
        include/system_info.hpp
)

# 创建可执行文件
add_executable(YumeCard ${YUMECARD_SOURCES} ${YUMECARD_HEADERS})

# 链接库
target_link_libraries(YumeCard PRIVATE CURL::libcurl nlohmann_json::nlohmann_json)

# 平台特定的链接库
if (WIN32)
        # Windows平台链接库
        target_link_libraries(YumeCard PRIVATE ws2_32 wldap32 crypt32)
elseif (UNIX AND NOT APPLE)
        # Linux平台链接库
        target_link_libraries(YumeCard PRIVATE Threads::Threads dl)
elseif (APPLE)
        # macOS平台链接库
        target_link_libraries(YumeCard PRIVATE Threads::Threads)
        find_library(COREFOUNDATION_LIBRARY CoreFoundation)
        find_library(SYSTEMCONFIGURATION_LIBRARY SystemConfiguration)
        if (COREFOUNDATION_LIBRARY AND SYSTEMCONFIGURATION_LIBRARY)
                target_link_libraries(YumeCard PRIVATE ${COREFOUNDATION_LIBRARY} ${SYSTEMCONFIGURATION_LIBRARY})
        endif ()
endif ()

# 设置目标属性
set_target_properties(YumeCard PROPERTIES
        OUTPUT_NAME "YumeCard"
        DEBUG_POSTFIX "_d"
)

# 为不同架构设置特定的输出名称
if (CMAKE_SIZEOF_VOID_P EQUAL 8)
        set_target_properties(YumeCard PROPERTIES OUTPUT_NAME "YumeCard_x64")
else ()
        set_target_properties(YumeCard PROPERTIES OUTPUT_NAME "YumeCard_x86")
endif ()

# ARM架构特殊处理
if (CMAKE_SYSTEM_PROCESSOR MATCHES "arm" OR CMAKE_SYSTEM_PROCESSOR MATCHES "aarch64")
        if (CMAKE_SIZEOF_VOID_P EQUAL 8)
                set_target_properties(YumeCard PROPERTIES OUTPUT_NAME "YumeCard_arm64")
        else ()
                set_target_properties(YumeCard PROPERTIES OUTPUT_NAME "YumeCard_arm32")
        endif ()
endif ()

# 添加post-build命令，确保Style和config目录存在于构建目录中
add_custom_command(TARGET YumeCard POST_BUILD
        COMMAND ${CMAKE_COMMAND} -E make_directory $<TARGET_FILE_DIR:YumeCard>/Style
        COMMAND ${CMAKE_COMMAND} -E make_directory $<TARGET_FILE_DIR:YumeCard>/Style/backgrounds
        COMMAND ${CMAKE_COMMAND} -E make_directory $<TARGET_FILE_DIR:YumeCard>/config
        COMMENT "Creating required directories"
)

# 复制必要的文件到构建目录
add_custom_command(TARGET YumeCard POST_BUILD
        COMMAND ${CMAKE_COMMAND} -E copy_if_different
        "${CMAKE_SOURCE_DIR}/Style/custom.css"
        "${CMAKE_SOURCE_DIR}/Style/index.html"
        "${CMAKE_SOURCE_DIR}/Style/screenshot.js"
        "$<TARGET_FILE_DIR:YumeCard>/Style/"
        COMMAND ${CMAKE_COMMAND} -E copy_directory
        "${CMAKE_SOURCE_DIR}/Style/backgrounds"
        "$<TARGET_FILE_DIR:YumeCard>/Style/backgrounds"
        COMMAND ${CMAKE_COMMAND} -E copy_if_different
        "${CMAKE_SOURCE_DIR}/config/config.json"
        "$<TARGET_FILE_DIR:YumeCard>/config/"
        COMMENT "Copying required files"
)

# 安装规则
install(TARGETS YumeCard
        RUNTIME DESTINATION bin
        LIBRARY DESTINATION lib
        ARCHIVE DESTINATION lib
)

# 安装必要的文件
install(DIRECTORY ${CMAKE_SOURCE_DIR}/Style/
        DESTINATION bin/Style
        FILES_MATCHING
        PATTERN "*.css"
        PATTERN "*.html"
        PATTERN "*.js"
)

install(DIRECTORY ${CMAKE_SOURCE_DIR}/Style/backgrounds/
        DESTINATION bin/Style/backgrounds
        FILES_MATCHING
        PATTERN "*.png"
        PATTERN "*.jpg"
        PATTERN "*.jpeg"
        PATTERN "*.gif"
)

install(FILES ${CMAKE_SOURCE_DIR}/config/config.json
        DESTINATION bin/config
)

# CPack配置用于创建安装包
include(CPack)
set(CPACK_PACKAGE_NAME "YumeCard")
set(CPACK_PACKAGE_VERSION "${PROJECT_VERSION}")
set(CPACK_PACKAGE_DESCRIPTION_SUMMARY "YumeCard GitHub订阅工具")
set(CPACK_PACKAGE_VENDOR "YumeYuka")

# 平台特定的打包设置
if (WIN32)
        set(CPACK_GENERATOR "ZIP;NSIS")
        set(CPACK_NSIS_DISPLAY_NAME "YumeCard")
        set(CPACK_NSIS_PACKAGE_NAME "YumeCard")
elseif (APPLE)
        set(CPACK_GENERATOR "ZIP;DragNDrop")
else ()
        set(CPACK_GENERATOR "ZIP;TGZ;DEB")
        set(CPACK_DEBIAN_PACKAGE_MAINTAINER "YumeYuka")
endif ()

# 创建多架构构建脚本
if (WIN32)
        # Windows批处理脚本
        file(WRITE "${CMAKE_BINARY_DIR}/build_all_architectures.bat"
                "@echo off\n"
                "echo Building for all Windows architectures...\n"
                "echo.\n"
                "echo Building x64...\n"
                "cmake -B build-x64 -A x64 -DCMAKE_BUILD_TYPE=Release\n"
                "cmake --build build-x64 --config Release\n"
                "echo.\n"
                "echo Building x86...\n"
                "cmake -B build-x86 -A Win32 -DCMAKE_BUILD_TYPE=Release\n"
                "cmake --build build-x86 --config Release\n"
                "echo.\n"
                "echo Build complete!\n"
                "pause\n"
        )
else ()
        # Unix shell脚本
        file(WRITE "${CMAKE_BINARY_DIR}/build_all_architectures.sh"
                "#!/bin/bash\n"
                "echo \"Building for all architectures...\"\n"
                "echo \"\"\n"
                "echo \"Building native architecture...\"\n"
                "cmake -B build-native -DCMAKE_BUILD_TYPE=Release\n"
                "cmake --build build-native\n"
                "echo \"\"\n"
                "echo \"Build complete!\"\n"
        )
        execute_process(COMMAND chmod +x "${CMAKE_BINARY_DIR}/build_all_architectures.sh")
endif ()

# YumeCard 多平台性能优化配置

## 编译器优化选项

### MSVC (Windows)

```cmake
# Release 优化
set(CMAKE_CXX_FLAGS_RELEASE "/O2 /Ob2 /DNDEBUG /GL")
set(CMAKE_EXE_LINKER_FLAGS_RELEASE "/LTCG /OPT:REF /OPT:ICF")

# 架构特定优化
if(CMAKE_GENERATOR_PLATFORM STREQUAL "x64")
    add_compile_options(/favor:INTEL64)
elseif(CMAKE_GENERATOR_PLATFORM STREQUAL "ARM64")
    add_compile_options(/arch:ARMv8)
endif()

# 多核编译
add_compile_options(/MP)
```

### GCC/Clang (Linux/macOS)

```cmake
# Release 优化
set(CMAKE_CXX_FLAGS_RELEASE "-O3 -DNDEBUG -flto")
set(CMAKE_EXE_LINKER_FLAGS_RELEASE "-flto")

# 架构特定优化
if(CMAKE_SYSTEM_PROCESSOR MATCHES "x86_64|AMD64")
    add_compile_options(-march=x86-64 -mtune=generic)
elseif(CMAKE_SYSTEM_PROCESSOR MATCHES "aarch64|ARM64")
    add_compile_options(-march=armv8-a -mtune=generic)
elseif(CMAKE_SYSTEM_PROCESSOR MATCHES "arm")
    add_compile_options(-march=armv7-a -mfpu=neon -mtune=generic)
endif()
```

## 内存优化

### 静态链接 (Windows)

```cmake
set(CMAKE_MSVC_RUNTIME_LIBRARY "MultiThreaded$<$<CONFIG:Debug>:Debug>")
```

### 动态链接 (Linux/macOS)

```cmake
set(BUILD_SHARED_LIBS ON)
```

## 并行构建配置

### Windows

```bat
cmake --build . --config Release --parallel %NUMBER_OF_PROCESSORS%
```

### Linux/macOS

```bash
cmake --build . --config Release --parallel $(nproc)
```

## 交叉编译优化

### ARM64 优化

```cmake
# ARM64 NEON 指令集支持
if(CMAKE_SYSTEM_PROCESSOR MATCHES "aarch64|ARM64")
    add_compile_options(-mfpu=neon)
    add_compile_definitions(HAVE_NEON=1)
endif()
```

### x86 SIMD 优化

```cmake
# SSE/AVX 指令集支持
if(CMAKE_SYSTEM_PROCESSOR MATCHES "x86_64|AMD64")
    add_compile_options(-msse4.2 -mavx2)
    add_compile_definitions(HAVE_SSE=1 HAVE_AVX=1)
endif()
```

## 性能分析配置

### Debug 构建

```cmake
if(CMAKE_BUILD_TYPE STREQUAL "Debug")
    add_compile_options(-g -O0)
    add_compile_definitions(DEBUG=1)
endif()
```

### Profile 构建

```cmake
if(CMAKE_BUILD_TYPE STREQUAL "RelWithDebInfo")
    add_compile_options(-O2 -g)
    add_compile_definitions(PROFILE=1)
endif()
```

## 平台特定优化

### Windows 特定

```cmake
if(WIN32)
    # 减少Windows头文件包含
    add_compile_definitions(WIN32_LEAN_AND_MEAN NOMINMAX)
    
    # 目标Windows版本
    add_compile_definitions(_WIN32_WINNT=0x0601)
endif()
```

### Linux 特定

```cmake
if(UNIX AND NOT APPLE)
    # 线程支持
    find_package(Threads REQUIRED)
    target_link_libraries(${PROJECT_NAME} PRIVATE Threads::Threads)
    
    # 位置无关代码
    set(CMAKE_POSITION_INDEPENDENT_CODE ON)
endif()
```

### macOS 特定

```cmake
if(APPLE)
    # 最低macOS版本
    set(CMAKE_OSX_DEPLOYMENT_TARGET "10.15")
    
    # Universal Binary
    set(CMAKE_OSX_ARCHITECTURES "x86_64;arm64")
endif()
```

## 依赖库优化

### vcpkg 配置

```cmake
# 静态库优先
set(VCPKG_LIBRARY_LINKAGE static)

# 架构特定三元组
if(CMAKE_SIZEOF_VOID_P EQUAL 8)
    set(VCPKG_TARGET_TRIPLET x64-windows-static)
else()
    set(VCPKG_TARGET_TRIPLET x86-windows-static)
endif()
```

### 系统库优化

```cmake
# 优先使用系统库
find_package(PkgConfig QUIET)
if(PkgConfig_FOUND)
    pkg_check_modules(DEPS IMPORTED_TARGET zlib libcurl)
    if(DEPS_FOUND)
        target_link_libraries(${PROJECT_NAME} PRIVATE PkgConfig::DEPS)
    endif()
endif()
```

## 构建缓存优化

### ccache 支持

```cmake
find_program(CCACHE_PROGRAM ccache)
if(CCACHE_PROGRAM)
    set_property(GLOBAL PROPERTY RULE_LAUNCH_COMPILE "${CCACHE_PROGRAM}")
    message(STATUS "Using ccache: ${CCACHE_PROGRAM}")
endif()
```

### sccache 支持 (Windows)

```cmake
find_program(SCCACHE_PROGRAM sccache)
if(SCCACHE_PROGRAM AND WIN32)
    set_property(GLOBAL PROPERTY RULE_LAUNCH_COMPILE "${SCCACHE_PROGRAM}")
    message(STATUS "Using sccache: ${SCCACHE_PROGRAM}")
endif()
```

## 测试性能优化

### 并行测试

```cmake
include(CTest)
enable_testing()

# 并行运行测试
set_property(GLOBAL PROPERTY CTEST_USE_LAUNCHERS ON)
```

### 基准测试

```cmake
# 性能基准测试
add_executable(benchmark src/benchmark.cpp)
target_link_libraries(benchmark PRIVATE ${PROJECT_NAME}_lib)

# 仅在Release模式下构建基准测试
if(CMAKE_BUILD_TYPE STREQUAL "Release")
    add_test(NAME benchmark_test COMMAND benchmark)
endif()
```

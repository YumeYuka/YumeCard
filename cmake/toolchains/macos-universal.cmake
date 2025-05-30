# macOS通用二进制（Universal Binary）工具链文件
set(CMAKE_SYSTEM_NAME Darwin)
set(CMAKE_SYSTEM_PROCESSOR universal)

# 设置macOS部署目标
set(CMAKE_OSX_DEPLOYMENT_TARGET "10.15")

# 设置通用架构
set(CMAKE_OSX_ARCHITECTURES "x86_64;arm64")

# 编译器设置
set(CMAKE_C_COMPILER clang)
set(CMAKE_CXX_COMPILER clang++)

# 设置根路径查找模式
set(CMAKE_FIND_ROOT_PATH_MODE_PROGRAM NEVER)
set(CMAKE_FIND_ROOT_PATH_MODE_LIBRARY ONLY)
set(CMAKE_FIND_ROOT_PATH_MODE_INCLUDE ONLY)
set(CMAKE_FIND_ROOT_PATH_MODE_PACKAGE ONLY)

# 针对不同架构的编译选项
set(CMAKE_CXX_FLAGS_INIT "-arch x86_64 -arch arm64")
set(CMAKE_C_FLAGS_INIT "-arch x86_64 -arch arm64")

# 链接器选项
set(CMAKE_EXE_LINKER_FLAGS_INIT "-arch x86_64 -arch arm64")
set(CMAKE_SHARED_LINKER_FLAGS_INIT "-arch x86_64 -arch arm64")

# vcpkg配置（需要为每个架构分别构建）
set(VCPKG_TARGET_TRIPLET x64-osx)

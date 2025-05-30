# Linux ARM64 交叉编译工具链文件
set(CMAKE_SYSTEM_NAME Linux)
set(CMAKE_SYSTEM_PROCESSOR aarch64)

# 设置编译器
set(CMAKE_C_COMPILER aarch64-linux-gnu-gcc)
set(CMAKE_CXX_COMPILER aarch64-linux-gnu-g++)

# 设置链接器
set(CMAKE_LINKER aarch64-linux-gnu-ld)
set(CMAKE_AR aarch64-linux-gnu-ar)
set(CMAKE_RANLIB aarch64-linux-gnu-ranlib)
set(CMAKE_STRIP aarch64-linux-gnu-strip)

# 设置sysroot（如果需要）
# set(CMAKE_SYSROOT /usr/aarch64-linux-gnu)

# 设置根路径查找模式
set(CMAKE_FIND_ROOT_PATH_MODE_PROGRAM NEVER)
set(CMAKE_FIND_ROOT_PATH_MODE_LIBRARY ONLY)
set(CMAKE_FIND_ROOT_PATH_MODE_INCLUDE ONLY)
set(CMAKE_FIND_ROOT_PATH_MODE_PACKAGE ONLY)

# ARM64 特定编译选项
set(CMAKE_CXX_FLAGS_INIT "-march=armv8-a")
set(CMAKE_C_FLAGS_INIT "-march=armv8-a")

# 设置pkg-config
set(PKG_CONFIG_EXECUTABLE aarch64-linux-gnu-pkg-config)

# 为vcpkg设置目标三元组
set(VCPKG_TARGET_TRIPLET arm64-linux)

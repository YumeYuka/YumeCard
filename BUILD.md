# YumeCard 多架构构建指南

YumeCard 支持在多个平台和架构上构建和运行，包括 Windows、Linux 和 macOS。

## 支持的平台和架构

### Windows

- **x64** (AMD64/Intel 64位)
- **x86** (Intel 32位)
- **ARM64** (ARM 64位)
- **ARM32** (ARM 32位)

### Linux

- **x64** (AMD64/Intel 64位)
- **x86** (Intel 32位)
- **ARM64** (AArch64)
- **ARM32** (ARM 32位)
- **RISC-V 64位**
- **RISC-V 32位**
- **MIPS 64位**
- **MIPS 32位**
- **PowerPC 64位**
- **PowerPC 32位**

### macOS

- **x64** (Intel 64位)
- **ARM64** (Apple Silicon M1/M2/M3)
- **x86** (Intel 32位，旧版本)

### FreeBSD

- **x64** (AMD64)
- **x86** (Intel 32位)
- **ARM64** (AArch64)

## 依赖要求

### 基本依赖

- **CMake** >= 3.16
- **C++20** 兼容的编译器
- **vcpkg** 包管理器
- **Node.js** (用于截图功能)

### 平台特定依赖

#### Windows

- **Visual Studio 2019/2022** 或 **MinGW-w64**
- **vcpkg** (推荐安装路径: `C:\tool\vcpkg` 或 `C:\vcpkg`)

#### Linux

- **GCC 9+** 或 **Clang 10+**
- **vcpkg** (通常安装在 `/usr/local/share/vcpkg` 或 `$HOME/vcpkg`)
- **pkg-config**
- **curl** 开发库
- **Node.js**

#### macOS

- **Xcode** 或 **Xcode Command Line Tools**
- **Homebrew** (推荐)
- **vcpkg**

## 快速开始

### 1. 安装 vcpkg

#### Windows (PowerShell)

```powershell
# 克隆 vcpkg
git clone https://github.com/Microsoft/vcpkg.git C:\tool\vcpkg
cd C:\tool\vcpkg

# 初始化 vcpkg
.\bootstrap-vcpkg.bat

# 集成到 Visual Studio
.\vcpkg integrate install
```

#### Linux/macOS

```bash
# 克隆 vcpkg
git clone https://github.com/Microsoft/vcpkg.git ~/vcpkg
cd ~/vcpkg

# 初始化 vcpkg
./bootstrap-vcpkg.sh

# 设置环境变量 (添加到 ~/.bashrc 或 ~/.zshrc)
export VCPKG_ROOT=$HOME/vcpkg
export PATH=$VCPKG_ROOT:$PATH
```

### 2. 安装依赖库

```bash
# 安装 CURL 和 nlohmann_json
vcpkg install curl nlohmann-json

# 对于特定架构 (示例)
vcpkg install curl:x64-windows nlohmann-json:x64-windows  # Windows x64
vcpkg install curl:arm64-linux nlohmann-json:arm64-linux  # Linux ARM64
vcpkg install curl:arm64-osx nlohmann-json:arm64-osx      # macOS ARM64
```

### 3. 构建项目

#### Windows

##### 使用 Visual Studio

```batch
# x64 构建
cmake -B build-x64 -A x64 -DCMAKE_TOOLCHAIN_FILE=C:\tool\vcpkg\scripts\buildsystems\vcpkg.cmake
cmake --build build-x64 --config Release

# x86 构建
cmake -B build-x86 -A Win32 -DCMAKE_TOOLCHAIN_FILE=C:\tool\vcpkg\scripts\buildsystems\vcpkg.cmake
cmake --build build-x86 --config Release

# ARM64 构建 (需要 ARM64 工具链)
cmake -B build-arm64 -A ARM64 -DCMAKE_TOOLCHAIN_FILE=C:\tool\vcpkg\scripts\buildsystems\vcpkg.cmake
cmake --build build-arm64 --config Release
```

##### 自动构建所有架构

```batch
# 运行生成的批处理脚本
build\build_all_architectures.bat
```

#### Linux

##### 本地架构构建

```bash
# 配置
cmake -B build -DCMAKE_BUILD_TYPE=Release -DCMAKE_TOOLCHAIN_FILE=$VCPKG_ROOT/scripts/buildsystems/vcpkg.cmake

# 构建
cmake --build build

# 或者使用生成的脚本
chmod +x build/build_all_architectures.sh
./build/build_all_architectures.sh
```

##### 交叉编译 (ARM64 示例)

```bash
# 安装交叉编译工具链
sudo apt install gcc-aarch64-linux-gnu g++-aarch64-linux-gnu

# 配置 ARM64 构建
cmake -B build-arm64 \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_TOOLCHAIN_FILE=$VCPKG_ROOT/scripts/buildsystems/vcpkg.cmake \
    -DVCPKG_TARGET_TRIPLET=arm64-linux \
    -DCMAKE_C_COMPILER=aarch64-linux-gnu-gcc \
    -DCMAKE_CXX_COMPILER=aarch64-linux-gnu-g++

# 构建
cmake --build build-arm64
```

#### macOS

##### 通用构建 (支持 Intel 和 Apple Silicon)

```bash
# 配置
cmake -B build -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_TOOLCHAIN_FILE=$VCPKG_ROOT/scripts/buildsystems/vcpkg.cmake \
    -DCMAKE_OSX_ARCHITECTURES="x86_64;arm64"

# 构建
cmake --build build
```

##### 特定架构构建

```bash
# Intel x64
cmake -B build-x64 -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_TOOLCHAIN_FILE=$VCPKG_ROOT/scripts/buildsystems/vcpkg.cmake \
    -DCMAKE_OSX_ARCHITECTURES=x86_64
cmake --build build-x64

# Apple Silicon ARM64
cmake -B build-arm64 -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_TOOLCHAIN_FILE=$VCPKG_ROOT/scripts/buildsystems/vcpkg.cmake \
    -DCMAKE_OSX_ARCHITECTURES=arm64
cmake --build build-arm64
```

## 输出文件命名

项目会根据目标架构自动命名输出文件：

- **x64**: `YumeCard_x64`
- **x86**: `YumeCard_x86`
- **ARM64**: `YumeCard_arm64`
- **ARM32**: `YumeCard_arm32`

调试版本会添加 `_d` 后缀，例如 `YumeCard_x64_d`。

## 安装和打包

### 安装到系统

```bash
# 构建并安装
cmake --build build --target install

# 指定安装路径
cmake --install build --prefix /usr/local
```

### 创建安装包

```bash
# 创建平台特定的安装包
cmake --build build --target package

# Windows: 生成 ZIP 和 NSIS 安装包
# Linux: 生成 ZIP、TGZ 和 DEB 包
# macOS: 生成 ZIP 和 DMG 包
```

## 验证构建

构建完成后，可以使用以下命令验证：

```bash
# 查看版本信息
./YumeCard_x64 help

# 测试截图功能
./YumeCard_x64 test-screenshot
```

## 故障排除

### 常见问题

1. **vcpkg 路径问题**
    - 确保 `CMAKE_TOOLCHAIN_FILE` 指向正确的 vcpkg 工具链文件
    - 设置 `VCPKG_ROOT` 环境变量

2. **依赖库未找到**
    - 重新安装依赖: `vcpkg install curl nlohmann-json`
    - 清理并重新配置: `rm -rf build && cmake -B build ...`

3. **Node.js 未找到**
    - 安装 Node.js: https://nodejs.org/
    - 确保 `node` 命令在 PATH 中

4. **交叉编译失败**
    - 安装目标架构的工具链
    - 使用正确的 VCPKG_TARGET_TRIPLET

### 获取帮助

如果遇到问题，请：

1. 检查 CMake 配置输出
2. 查看编译错误日志
3. 确认所有依赖已正确安装
4. 提交 Issue 并附上详细的错误信息

## 贡献

欢迎为多架构支持贡献代码！请确保：

1. 代码在所有支持的平台上都能编译
2. 添加适当的平台检测宏
3. 更新构建文档
4. 测试新增的架构支持

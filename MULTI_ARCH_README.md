# YumeCard 多架构支持

YumeCard 是一个支持多平台、多架构的GitHub订阅工具，具有完整的跨平台构建和部署能力。

## 🏗️ 支持的平台和架构

### Windows

- ✅ **x64** (Intel/AMD 64位)
- ✅ **x86** (Intel/AMD 32位)
- ✅ **ARM64** (ARM 64位)
- ✅ **ARM32** (ARM 32位)

### Linux

- ✅ **x64** (Intel/AMD 64位)
- ✅ **x86** (Intel/AMD 32位)
- ✅ **ARM64** (AArch64)
- ✅ **ARM32** (ARMv7)
- ✅ **RISC-V 64位**
- ✅ **RISC-V 32位**
- ✅ **MIPS 64位**
- ✅ **MIPS 32位**
- ✅ **PowerPC 64位**

### macOS

- ✅ **x64** (Intel 64位)
- ✅ **ARM64** (Apple Silicon M1/M2/M3)
- ✅ **Universal Binary** (x64 + ARM64)

### FreeBSD

- ✅ **x64** (AMD64)
- ✅ **x86** (Intel 32位)
- ✅ **ARM64** (AArch64)

## 🚀 快速开始

### 1. 安装依赖

**自动安装依赖 (推荐):**

Windows:

```cmd
REM 检查并安装所有依赖
.\scripts\install_dependencies.bat

REM 或分步安装
.\scripts\install_dependencies.bat --basic
.\scripts\install_dependencies.bat --vcpkg
.\scripts\install_dependencies.bat --deps
```

Linux:

```bash
# 安装所有依赖
./scripts/install_dependencies.sh

# 或分步安装
./scripts/install_dependencies.sh --basic
./scripts/install_dependencies.sh --cross
./scripts/install_dependencies.sh --vcpkg
./scripts/install_dependencies.sh --deps
```

**手动安装:**

**所有平台共同依赖:**

- CMake >= 3.16
- C++20兼容编译器
- vcpkg 包管理器
- Node.js (用于截图功能)

**Windows:**

```bash
# 使用Chocolatey安装
choco install cmake nodejs git

# 安装Visual Studio 2022 (推荐) 或 MinGW-w64
# 安装vcpkg到 C:\tool\vcpkg 或 C:\vcpkg
```

**Linux (Ubuntu/Debian):**

```bash
sudo apt update
sudo apt install cmake build-essential nodejs npm git

# 安装vcpkg
git clone https://github.com/Microsoft/vcpkg.git
cd vcpkg && ./bootstrap-vcpkg.sh
```

**macOS:**

```bash
# 使用Homebrew安装
brew install cmake node git

# 安装Xcode命令行工具
xcode-select --install

# 安装vcpkg
git clone https://github.com/Microsoft/vcpkg.git
cd vcpkg && ./bootstrap-vcpkg.sh
```

### 2. 构建项目

**使用高级构建脚本 (推荐):**

Unix系统 (Linux/macOS):

```bash
# 构建当前架构
./scripts/build_multi_arch.sh

# 构建所有支持的架构
./scripts/build_multi_arch.sh all

# 交叉编译ARM64版本
./scripts/build_multi_arch.sh --cross arm64

# 构建、测试并打包
./scripts/build_multi_arch.sh --test --package x64
```

Windows:

```cmd
REM 构建当前架构
.\scripts\build_multi_arch.bat

REM 构建所有架构
.\scripts\build_multi_arch.bat all

REM 构建、测试并打包
.\scripts\build_multi_arch.bat --test --package x64
```

**手动构建:**

```bash
# 基本构建
cmake -B build -DCMAKE_BUILD_TYPE=Release
cmake --build build

# 指定架构 (Windows)
cmake -B build-x64 -A x64 -DCMAKE_BUILD_TYPE=Release
cmake -B build-arm64 -A ARM64 -DCMAKE_BUILD_TYPE=Release

# macOS通用二进制
cmake -B build-universal -DCMAKE_OSX_ARCHITECTURES="x86_64;arm64"
```

### 3. 验证构建

```bash
# 检查多架构支持状态
./scripts/check_multi_arch.sh

# 运行系统信息检查
./build/bin/YumeCard_x64 system-info

# 生成诊断报告
./build/bin/YumeCard_x64 diagnostic report.txt
```

## 🔧 新增功能

### 系统信息命令

显示详细的系统信息和兼容性检查:

```bash
YumeCard system-info
```

输出内容:

- 平台信息 (操作系统、架构、位数)
- 构建信息 (编译器、构建类型)
- 环境检查 (Node.js、vcpkg)
- 兼容性验证 (依赖文件检查)

### 诊断命令

生成完整的诊断报告:

```bash
YumeCard diagnostic [输出文件路径]
```

生成内容:

- 完整系统信息
- 环境变量
- 平台特定诊断
- 时间戳和版本信息

## 📁 项目结构

```
YumeCard/
├── cmake/
│   └── toolchains/           # 交叉编译工具链文件
│       ├── windows-arm64.cmake
│       ├── linux-arm64.cmake
│       └── macos-universal.cmake
├── scripts/
│   ├── build_multi_arch.sh   # Unix多架构构建脚本
│   ├── build_multi_arch.bat  # Windows多架构构建脚本
│   └── check_multi_arch.sh   # 多架构状态检查脚本
├── .github/
│   └── workflows/
│       └── multi-arch-build.yml  # GitHub Actions CI/CD
├── include/
│   ├── head.hpp              # 平台检测宏定义
│   ├── platform_utils.hpp    # 跨平台工具类
│   ├── system_info.hpp       # 系统信息和诊断
│   └── ...
├── src/
│   └── main.cpp              # 主程序(含多架构命令)
├── CMakeLists.txt            # 多架构CMake配置
├── BUILD.md                  # 详细构建说明
└── MULTI_ARCH_STATUS.md      # 多架构支持状态
```

## 🔄 CI/CD 自动化

### GitHub Actions工作流

自动构建以下平台和架构组合:

- Windows: x64, x86, ARM64
- Linux: x64, ARM64
- macOS: x64, ARM64, Universal

工作流特性:

- ✅ 自动依赖安装
- ✅ 多架构并行构建
- ✅ 交叉编译支持
- ✅ 自动测试验证
- ✅ 构建产物上传
- ✅ 发布版本管理

### 触发条件

- 推送到 `main` 或 `develop` 分支
- 创建Pull Request到 `main` 分支
- 发布新版本标签

## 🎯 架构检测原理

### 编译时检测

使用预处理器宏进行平台和架构检测:

```cpp
// 平台检测
#ifdef _WIN32
    #define YUMECARD_PLATFORM_WINDOWS
#elif defined(__linux__)
    #define YUMECARD_PLATFORM_LINUX
#elif defined(__APPLE__)
    #define YUMECARD_PLATFORM_MACOS
#endif

// 架构检测
#if defined(__x86_64__) || defined(_M_X64)
    #define YUMECARD_ARCH_X64
#elif defined(__aarch64__) || defined(_M_ARM64)
    #define YUMECARD_ARCH_ARM64
#endif
```

### 运行时检测

系统信息类提供运行时平台信息:

```cpp
SystemInfoManager info;
info.printSystemInfo();  // 显示当前平台信息
info.checkCompatibility();  // 检查兼容性
```

## 📦 构建产物

构建完成后生成以下文件:

- `YumeCard_x64[.exe]` - x64架构可执行文件
- `YumeCard_arm64[.exe]` - ARM64架构可执行文件
- `YumeCard_x86[.exe]` - x86架构可执行文件
- 各种格式的安装包 (ZIP, DEB, DMG等)

调试版本自动添加 `_d` 后缀。

## 🛠️ 开发指南

### 添加新架构支持

1. 在 `include/head.hpp` 中添加架构检测宏
2. 在 `CMakeLists.txt` 中添加架构特定配置
3. 更新 `.github/workflows/multi-arch-build.yml`
4. 如需要，创建交叉编译工具链文件

### 平台特定代码

使用条件编译处理平台差异:

```cpp
#ifdef YUMECARD_PLATFORM_WINDOWS
    // Windows特定代码
#elif defined(YUMECARD_PLATFORM_LINUX)
    // Linux特定代码
#elif defined(YUMECARD_PLATFORM_MACOS)
    // macOS特定代码
#endif
```

## 📋 故障排除

### 常见问题

**1. vcpkg找不到**

```bash
# 设置环境变量
export VCPKG_ROOT=/path/to/vcpkg
# 或使用CMake参数
cmake -DCMAKE_TOOLCHAIN_FILE=/path/to/vcpkg/scripts/buildsystems/vcpkg.cmake
```

**2. 交叉编译工具链缺失**

```bash
# Linux ARM64交叉编译工具
sudo apt install gcc-aarch64-linux-gnu g++-aarch64-linux-gnu

# Linux ARM32交叉编译工具
sudo apt install gcc-arm-linux-gnueabihf g++-arm-linux-gnueabihf
```

**3. Node.js未找到**

```bash
# 检查Node.js安装
node --version
npm --version

# 安装Node.js (如果需要)
# Windows: choco install nodejs
# Linux: sudo apt install nodejs npm
# macOS: brew install node
```

### 调试技巧

**启用详细输出:**

```bash
cmake --build build --verbose
```

**检查平台检测:**

```bash
./YumeCard_x64 system-info
```

**生成详细诊断:**

```bash
./YumeCard_x64 diagnostic debug_report.txt
```

## 📚 相关文档

- [BUILD.md](BUILD.md) - 详细构建说明
- [MULTI_ARCH_STATUS.md](MULTI_ARCH_STATUS.md) - 多架构支持状态
- [.github/workflows/multi-arch-build.yml](.github/workflows/multi-arch-build.yml) - CI/CD配置

## 🤝 贡献指南

1. Fork项目仓库
2. 创建特性分支: `git checkout -b feature/new-arch-support`
3. 提交更改: `git commit -am 'Add new architecture support'`
4. 推送分支: `git push origin feature/new-arch-support`
5. 创建Pull Request

确保新增架构支持包括:

- [ ] 平台检测宏定义
- [ ] CMake配置更新
- [ ] CI/CD工作流更新
- [ ] 文档更新
- [ ] 测试验证

---

**维护者**: YumeYuka  
**最后更新**: 2025-05-30  
**版本**: 0.1.0

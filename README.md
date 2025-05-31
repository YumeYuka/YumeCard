# 🌙 YumeCard - GitHub 仓库订阅与提交卡片生成工具

[![License](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)
[![C++](https://img.shields.io/badge/C%2B%2B-23-blue.svg)](https://isocpp.org/)
[![CMake](https://img.shields.io/badge/CMake-3.16%2B-green.svg)](https://cmake.org/)
[![Platform](https://img.shields.io/badge/platform-Windows%20%7C%20Linux-lightgrey.svg)](#)
[![GitHub](https://img.shields.io/badge/GitHub-API-black.svg)](https://docs.github.com/en/rest)

> 🎨 一个优雅的 GitHub 仓库监控工具，自动生成精美的提交卡片截图

## ✨ 功能特性

- 🔍 **实时监控** - 自动监控 GitHub 仓库的新提交
- 🎨 **美观卡片** - 生成精美的提交信息卡片
- 🌈 **自定义样式** - 支持自定义背景和CSS样式
- 📸 **自动截图** - 使用 Puppeteer 自动生成高质量截图
- ⚡ **跨平台** - 支持 Windows 和 Linux 系统
- 🔧 **灵活配置** - JSON 配置文件，易于管理
- 📊 **系统诊断** - 内置系统信息和兼容性检查

## 🚀 快速开始

### 📋 系统要求

- **操作系统**: Windows 10+ 或 Linux
- **编译器**: 支持 C++23 标准的编译器
- **CMake**: 3.16 或更高版本
- **Node.js**: 用于 Puppeteer 截图功能
- **依赖库**: libcurl, nlohmann/json, zlib

### 🛠️ 构建安装

1. **克隆仓库**
```bash
git clone https://github.com/YumeYuka/YumeCard.git
cd YumeCard
```

2. **安装依赖**
```bash
# 安装 Node.js 依赖
npm install

# 使用 vcpkg 安装 C++ 依赖
vcpkg install
```

3. **构建项目**
```bash
mkdir build
cd build
cmake ..
cmake --build . --config Release
```

### node.js 环境配置
确保您的系统已安装 Node.js 和 npm。可以通过以下命令检查版本：
```bash
node -v
npm -v
```
4. **运行项目**
```bash
pnpm i 
```

如果出现错误，请确保您的 Node.js 版本符合要求，并且已正确安装 Puppeteer。
```bash
pnpm rebuild puppeteer 
pnpm approve-builds
# 然后选择允许 puppeteer 运行构建脚本
```


### ⚙️ 配置设置

1. **设置 GitHub Token**
```bash
./YumeCard set-token your_github_token_here
```

2. **添加仓库订阅**
```bash
./YumeCard add YumeYuka YumeCard main
```

3. **开始监控**
```bash
./YumeCard monitor 10  # 每10分钟检查一次
```

## 📖 使用说明

### 🎯 命令行界面

#### 全局选项
| 选项              | 描述             | 默认值     |
| ----------------- | ---------------- | ---------- |
| `--config <路径>` | 指定配置文件目录 | `./config` |
| `--style <路径>`  | 指定样式文件目录 | `./Style`  |
| `--output <路径>` | 指定输出图像目录 | `./Style`  |
| `--version`       | 显示版本信息     | -          |
| `--help`          | 显示帮助信息     | -          |

#### 主要命令

**📌 添加仓库订阅**
```bash
YumeCard add <owner> <repo> [branch]
```
- `owner`: GitHub 用户名或组织名
- `repo`: 仓库名称
- `branch`: 分支名称（可选，默认为 main）

**🔍 检查仓库更新**
```bash
YumeCard check <owner> <repo>
```

**👀 监控模式**
```bash
YumeCard monitor [interval]
```
- `interval`: 检查间隔（分钟），默认为 10

**📋 列出订阅**
```bash
YumeCard list
```

**🔑 设置 Token**
```bash
YumeCard set-token <token>
```

**📸 测试截图**
```bash
YumeCard test-screenshot
```

**🖥️ 系统信息**
```bash
YumeCard system-info
```

### 📁 项目结构

```
YumeCard/
├── 📁 config/          # 配置文件目录
│   └── config.json     # 主配置文件
├── 📁 Style/           # 样式和模板文件
│   ├── index.html      # HTML 模板
│   ├── custom.css      # 自定义样式
│   ├── screenshot.js   # 截图脚本
│   └── 📁 backgrounds/ # 背景图片
├── 📁 src/             # 源代码
├── 📁 include/         # 头文件
├── 📁 build/           # 构建输出
└── 📁 docs/            # 文档
```

### ⚙️ 配置文件

**config.json 示例:**
```json
{
  "GitHub": {
    "username": "YumeYuka",
    "backgrounds": "true",
    "token": "your_github_token",
    "repository": [
      {
        "owner": "YumeYuka",
        "branch": "main",
        "repo": "YumeCard",
        "lastsha": ""
      }
    ]
  }
}
```

### 🎨 自定义样式

您可以通过修改 `Style/custom.css` 来自定义卡片样式，或在 `Style/backgrounds/` 目录中添加自定义背景图片。

## 🔧 高级功能

### 📊 性能优化

项目采用了多种性能优化策略：
- 静态链接减少依赖
- 异步 HTTP 请求
- 内存池管理
- 智能缓存机制

详细信息请参考 [性能优化文档](docs/PERFORMANCE_OPTIMIZATION.md)。

### 🐛 诊断和调试

```bash
# 生成诊断报告
YumeCard diagnostic

# 查看系统兼容性
YumeCard system-info
```

## 🤝 贡献指南

我们欢迎所有形式的贡献！

1. Fork 本仓库
2. 创建功能分支 (`git checkout -b feature/AmazingFeature`)
3. 提交更改 (`git commit -m 'Add some AmazingFeature'`)
4. 推送到分支 (`git push origin feature/AmazingFeature`)
5. 打开 Pull Request

## 📝 许可证

本项目采用 MIT 许可证 - 查看 [LICENSE](LICENSE) 文件了解详情。

## 🙏 致谢

- [nlohmann/json](https://github.com/nlohmann/json) - JSON 处理库
- [libcurl](https://curl.se/libcurl/) - HTTP 客户端库
- [Puppeteer](https://pptr.dev/) - 无头浏览器控制
- [vcpkg](https://vcpkg.io/) - C++ 包管理器

## 📞 联系方式

- 作者: YumeYuka
- GitHub: [@YumeYuka](https://github.com/YumeYuka)
- 项目链接: [https://github.com/YumeYuka/YumeCard](https://github.com/YumeYuka/YumeCard)

---

**⭐ 如果这个项目对您有帮助，请给个 Star 支持一下！**
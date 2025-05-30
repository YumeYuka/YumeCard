#!/bin/bash
# YumeCard Linux交叉编译支持脚本

set -e

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$PROJECT_ROOT"

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

echo -e "${CYAN}═══════════════════════════════════════════════════════════════════════════════${NC}"
echo -e "${CYAN}                     YumeCard Linux交叉编译支持设置                            ${NC}"
echo -e "${CYAN}═══════════════════════════════════════════════════════════════════════════════${NC}"
echo

# 检测当前系统
if [[ "$OSTYPE" == "linux-gnu"* ]]; then
    PLATFORM="Linux"
    DISTRO=$(lsb_release -si 2>/dev/null || echo "Unknown")
elif [[ "$OSTYPE" == "darwin"* ]]; then
    PLATFORM="macOS"
    DISTRO="macOS"
elif [[ "$OSTYPE" == "msys" || "$OSTYPE" == "cygwin" ]]; then
    PLATFORM="Windows"
    DISTRO="Windows"
else
    PLATFORM="Unknown"
    DISTRO="Unknown"
fi

echo -e "${BLUE}▶ 系统信息${NC}"
echo "───────────────────────────────────────────────────────────────────────────────"
echo "  平台: $PLATFORM"
echo "  发行版: $DISTRO"
echo "  架构: $(uname -m)"
echo

# 检查必要工具
echo -e "${BLUE}▶ 检查构建工具${NC}"
echo "───────────────────────────────────────────────────────────────────────────────"

check_tool() {
    if command -v "$1" >/dev/null 2>&1; then
        echo -e "  ${GREEN}✅${NC} $1"
        return 0
    else
        echo -e "  ${RED}❌${NC} $1"
        return 1
    fi
}

MISSING_TOOLS=()

if ! check_tool "cmake"; then
    MISSING_TOOLS+=("cmake")
fi

if ! check_tool "git"; then
    MISSING_TOOLS+=("git")
fi

if ! check_tool "curl"; then
    MISSING_TOOLS+=("curl")
fi

if ! check_tool "wget"; then
    MISSING_TOOLS+=("wget")
fi

if ! check_tool "tar"; then
    MISSING_TOOLS+=("tar")
fi

if ! check_tool "unzip"; then
    MISSING_TOOLS+=("unzip")
fi

echo

# 安装缺失的工具
if [ ${#MISSING_TOOLS[@]} -gt 0 ]; then
    echo -e "${YELLOW}⚠️  检测到缺失的工具: ${MISSING_TOOLS[*]}${NC}"
    echo -e "${BLUE}▶ 安装缺失的工具${NC}"
    echo "───────────────────────────────────────────────────────────────────────────────"

    if [[ "$PLATFORM" == "Linux" ]]; then
        # 检测包管理器
        if command -v apt-get >/dev/null 2>&1; then
            echo "  使用 apt-get 安装工具..."
            sudo apt-get update
            for tool in "${MISSING_TOOLS[@]}"; do
                case $tool in
                "cmake")
                    sudo apt-get install -y cmake
                    ;;
                "git")
                    sudo apt-get install -y git
                    ;;
                "curl")
                    sudo apt-get install -y curl
                    ;;
                "wget")
                    sudo apt-get install -y wget
                    ;;
                "tar")
                    sudo apt-get install -y tar
                    ;;
                "unzip")
                    sudo apt-get install -y unzip
                    ;;
                esac
            done
        elif command -v yum >/dev/null 2>&1; then
            echo "  使用 yum 安装工具..."
            for tool in "${MISSING_TOOLS[@]}"; do
                sudo yum install -y "$tool"
            done
        elif command -v pacman >/dev/null 2>&1; then
            echo "  使用 pacman 安装工具..."
            for tool in "${MISSING_TOOLS[@]}"; do
                sudo pacman -S --noconfirm "$tool"
            done
        else
            echo -e "  ${RED}❌${NC} 未找到支持的包管理器"
            echo "  请手动安装: ${MISSING_TOOLS[*]}"
            exit 1
        fi
    elif [[ "$PLATFORM" == "macOS" ]]; then
        if command -v brew >/dev/null 2>&1; then
            echo "  使用 Homebrew 安装工具..."
            for tool in "${MISSING_TOOLS[@]}"; do
                brew install "$tool"
            done
        else
            echo -e "  ${RED}❌${NC} 请先安装 Homebrew: https://brew.sh/"
            exit 1
        fi
    fi
    echo
fi

# 检查交叉编译工具链
echo -e "${BLUE}▶ 检查交叉编译工具链${NC}"
echo "───────────────────────────────────────────────────────────────────────────────"

check_cross_compiler() {
    local arch="$1"
    local prefix="$2"

    if command -v "${prefix}-gcc" >/dev/null 2>&1; then
        echo -e "  ${GREEN}✅${NC} $arch 交叉编译器 (${prefix})"
        return 0
    else
        echo -e "  ${RED}❌${NC} $arch 交叉编译器 (${prefix})"
        return 1
    fi
}

CROSS_COMPILERS=()

if [[ "$PLATFORM" == "Linux" ]]; then
    if ! check_cross_compiler "ARM64" "aarch64-linux-gnu"; then
        CROSS_COMPILERS+=("gcc-aarch64-linux-gnu")
    fi

    if ! check_cross_compiler "ARM32" "arm-linux-gnueabihf"; then
        CROSS_COMPILERS+=("gcc-arm-linux-gnueabihf")
    fi

    if ! check_cross_compiler "x86" "i686-linux-gnu"; then
        CROSS_COMPILERS+=("gcc-multilib")
    fi
fi

echo

# 安装交叉编译工具链
if [ ${#CROSS_COMPILERS[@]} -gt 0 ]; then
    echo -e "${YELLOW}⚠️  检测到缺失的交叉编译工具链: ${CROSS_COMPILERS[*]}${NC}"
    echo -e "${BLUE}▶ 安装交叉编译工具链${NC}"
    echo "───────────────────────────────────────────────────────────────────────────────"

    if [[ "$PLATFORM" == "Linux" ]]; then
        if command -v apt-get >/dev/null 2>&1; then
            echo "  使用 apt-get 安装交叉编译工具链..."
            sudo apt-get update
            for compiler in "${CROSS_COMPILERS[@]}"; do
                sudo apt-get install -y "$compiler"
            done
        else
            echo -e "  ${YELLOW}⚠️${NC} 请手动安装交叉编译工具链: ${CROSS_COMPILERS[*]}"
        fi
    fi
    echo
fi

# 检查并安装vcpkg
echo -e "${BLUE}▶ 检查vcpkg包管理器${NC}"
echo "───────────────────────────────────────────────────────────────────────────────"

VCPKG_ROOT=""
if [[ -n "$VCPKG_ROOT" ]]; then
    VCPKG_ROOT="$VCPKG_ROOT"
elif [[ -d "/usr/local/share/vcpkg" ]]; then
    VCPKG_ROOT="/usr/local/share/vcpkg"
elif [[ -d "$HOME/vcpkg" ]]; then
    VCPKG_ROOT="$HOME/vcpkg"
fi

if [[ -n "$VCPKG_ROOT" && -f "$VCPKG_ROOT/vcpkg" ]]; then
    echo -e "  ${GREEN}✅${NC} vcpkg 已安装: $VCPKG_ROOT"
else
    echo -e "  ${YELLOW}⚠️${NC} vcpkg 未找到，正在安装..."

    # 安装vcpkg
    VCPKG_ROOT="$HOME/vcpkg"
    git clone https://github.com/Microsoft/vcpkg.git "$VCPKG_ROOT"
    cd "$VCPKG_ROOT"
    ./bootstrap-vcpkg.sh

    # 设置环境变量
    echo "export VCPKG_ROOT=\"$VCPKG_ROOT\"" >>~/.bashrc
    echo "export PATH=\"\$PATH:\$VCPKG_ROOT\"" >>~/.bashrc

    echo -e "  ${GREEN}✅${NC} vcpkg 安装完成: $VCPKG_ROOT"
    echo -e "  ${BLUE}ℹ️${NC}  请重新启动终端或运行: source ~/.bashrc"
fi

echo

# 安装依赖包
echo -e "${BLUE}▶ 安装项目依赖包${NC}"
echo "───────────────────────────────────────────────────────────────────────────────"

if [[ -n "$VCPKG_ROOT" && -f "$VCPKG_ROOT/vcpkg" ]]; then
    cd "$VCPKG_ROOT"

    # 为不同架构安装依赖
    TRIPLETS=("x64-linux")

    # 如果有交叉编译工具链，添加更多架构
    if command -v aarch64-linux-gnu-gcc >/dev/null 2>&1; then
        TRIPLETS+=("arm64-linux")
    fi

    if command -v arm-linux-gnueabihf-gcc >/dev/null 2>&1; then
        TRIPLETS+=("arm-linux")
    fi

    for triplet in "${TRIPLETS[@]}"; do
        echo "  安装 $triplet 依赖包..."
        ./vcpkg install curl:$triplet nlohmann-json:$triplet
    done

    echo -e "  ${GREEN}✅${NC} 依赖包安装完成"
else
    echo -e "  ${RED}❌${NC} vcpkg 不可用，跳过依赖包安装"
fi

echo

# 创建构建脚本
echo -e "${BLUE}▶ 创建Linux构建脚本${NC}"
echo "───────────────────────────────────────────────────────────────────────────────"

cd "$PROJECT_ROOT"

# 创建Linux本地构建脚本
cat >"build_linux_native.sh" <<'EOF'
#!/bin/bash
# YumeCard Linux本地构建脚本

set -e

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$PROJECT_ROOT"

echo "构建Linux本地版本..."

# 创建构建目录
mkdir -p build-linux-native
cd build-linux-native

# 配置CMake
cmake .. \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_TOOLCHAIN_FILE="$VCPKG_ROOT/scripts/buildsystems/vcpkg.cmake" \
    -DVCPKG_TARGET_TRIPLET=x64-linux

# 构建
cmake --build . --config Release -j$(nproc)

echo "构建完成: build-linux-native/bin/"
EOF

# 创建Linux ARM64交叉编译脚本
if command -v aarch64-linux-gnu-gcc >/dev/null 2>&1; then
    cat >"build_linux_arm64.sh" <<'EOF'
#!/bin/bash
# YumeCard Linux ARM64交叉编译脚本

set -e

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$PROJECT_ROOT"

echo "交叉编译Linux ARM64版本..."

# 创建构建目录
mkdir -p build-linux-arm64
cd build-linux-arm64

# 配置CMake
cmake .. \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_TOOLCHAIN_FILE="../cmake/toolchains/linux-arm64.cmake" \
    -DVCPKG_CHAINLOAD_TOOLCHAIN_FILE="$VCPKG_ROOT/scripts/buildsystems/vcpkg.cmake" \
    -DVCPKG_TARGET_TRIPLET=arm64-linux

# 构建
cmake --build . --config Release -j$(nproc)

echo "构建完成: build-linux-arm64/bin/"
EOF
fi

chmod +x *.sh

echo -e "  ${GREEN}✅${NC} Linux构建脚本创建完成"
echo

# 测试构建
echo -e "${BLUE}▶ 测试构建${NC}"
echo "───────────────────────────────────────────────────────────────────────────────"

if [[ "$1" == "--test" ]]; then
    echo "  开始测试构建..."

    if [[ -f "build_linux_native.sh" ]]; then
        echo "  测试本地构建..."
        ./build_linux_native.sh

        if [[ -f "build-linux-native/bin/YumeCard_x64" ]]; then
            echo -e "  ${GREEN}✅${NC} 本地构建成功"
            echo "  测试运行..."
            ./build-linux-native/bin/YumeCard_x64 --help >/dev/null 2>&1 || true
        else
            echo -e "  ${RED}❌${NC} 本地构建失败"
        fi
    fi

    if [[ -f "build_linux_arm64.sh" ]] && command -v aarch64-linux-gnu-gcc >/dev/null 2>&1; then
        echo "  测试ARM64交叉编译..."
        ./build_linux_arm64.sh || echo -e "  ${YELLOW}⚠️${NC} ARM64交叉编译可能需要额外配置"
    fi
else
    echo -e "  ${BLUE}ℹ️${NC}  使用 --test 参数来测试构建"
fi

echo

# 总结
echo -e "${BLUE}▶ 设置完成总结${NC}"
echo "───────────────────────────────────────────────────────────────────────────────"
echo -e "  ${GREEN}✅${NC} Linux交叉编译环境设置完成"
echo
echo "可用的构建命令:"
echo "  本地构建:       ./build_linux_native.sh"
if [[ -f "build_linux_arm64.sh" ]]; then
    echo "  ARM64交叉编译:  ./build_linux_arm64.sh"
fi
echo
echo "多架构构建:"
echo "  所有架构:       ./scripts/build_multi_arch.sh"
echo
echo "状态检查:"
echo "  检查状态:       ./scripts/check_multi_arch.sh"
echo

echo -e "${GREEN}✅ Linux交叉编译支持设置完成${NC}"

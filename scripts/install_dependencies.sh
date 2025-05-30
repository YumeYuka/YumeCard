#!/bin/bash

# YumeCard 多架构依赖安装脚本 (Linux)
# 用于设置交叉编译环境

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# 检测发行版
detect_distro() {
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        echo $ID
    else
        echo "unknown"
    fi
}

# 安装基本构建工具
install_basic_tools() {
    local distro=$(detect_distro)

    print_info "安装基本构建工具..."

    case $distro in
    ubuntu | debian)
        sudo apt-get update
        sudo apt-get install -y \
            build-essential \
            cmake \
            git \
            curl \
            nodejs \
            npm \
            pkg-config \
            ninja-build
        ;;
    fedora | centos | rhel)
        if command -v dnf &>/dev/null; then
            sudo dnf install -y \
                gcc \
                gcc-c++ \
                cmake \
                git \
                curl \
                nodejs \
                npm \
                pkg-config \
                ninja-build
        else
            sudo yum install -y \
                gcc \
                gcc-c++ \
                cmake \
                git \
                curl \
                nodejs \
                npm \
                pkg-config \
                ninja-build
        fi
        ;;
    arch)
        sudo pacman -S --noconfirm \
            base-devel \
            cmake \
            git \
            curl \
            nodejs \
            npm \
            pkg-config \
            ninja
        ;;
    *)
        print_warning "未识别的发行版: $distro"
        print_info "请手动安装: gcc, g++, cmake, git, curl, nodejs, npm"
        ;;
    esac

    print_success "基本构建工具安装完成"
}

# 安装交叉编译工具链
install_cross_compilers() {
    local distro=$(detect_distro)

    print_info "安装交叉编译工具链..."

    case $distro in
    ubuntu | debian)
        # ARM64 交叉编译工具
        sudo apt-get install -y \
            gcc-aarch64-linux-gnu \
            g++-aarch64-linux-gnu \
            libc6-dev-arm64-cross

        # ARM32 交叉编译工具
        sudo apt-get install -y \
            gcc-arm-linux-gnueabihf \
            g++-arm-linux-gnueabihf \
            libc6-dev-armhf-cross

        # RISC-V 交叉编译工具 (如果可用)
        if apt-cache search gcc-riscv64-linux-gnu | grep -q gcc-riscv64-linux-gnu; then
            sudo apt-get install -y \
                gcc-riscv64-linux-gnu \
                g++-riscv64-linux-gnu
            print_success "RISC-V 64位交叉编译工具已安装"
        else
            print_warning "RISC-V 交叉编译工具不可用"
        fi
        ;;
    fedora)
        # ARM64 交叉编译工具
        sudo dnf install -y \
            gcc-aarch64-linux-gnu \
            gcc-c++-aarch64-linux-gnu

        # ARM32 交叉编译工具
        sudo dnf install -y \
            gcc-arm-linux-gnu \
            gcc-c++-arm-linux-gnu
        ;;
    *)
        print_warning "请手动安装交叉编译工具链"
        print_info "ARM64: gcc-aarch64-linux-gnu, g++-aarch64-linux-gnu"
        print_info "ARM32: gcc-arm-linux-gnueabihf, g++-arm-linux-gnueabihf"
        ;;
    esac

    print_success "交叉编译工具链安装完成"
}

# 安装vcpkg
install_vcpkg() {
    print_info "安装vcpkg包管理器..."

    if [ ! -d "$HOME/vcpkg" ]; then
        git clone https://github.com/Microsoft/vcpkg.git "$HOME/vcpkg"
        cd "$HOME/vcpkg"
        ./bootstrap-vcpkg.sh

        # 添加到PATH
        if ! grep -q "export VCPKG_ROOT=" ~/.bashrc; then
            echo "export VCPKG_ROOT=$HOME/vcpkg" >>~/.bashrc
            echo "export PATH=\$PATH:\$VCPKG_ROOT" >>~/.bashrc
        fi

        print_success "vcpkg安装完成"
        print_info "请运行 'source ~/.bashrc' 或重新登录以使环境变量生效"
    else
        print_info "vcpkg已存在，更新中..."
        cd "$HOME/vcpkg"
        git pull
        print_success "vcpkg更新完成"
    fi
}

# 安装依赖包
install_dependencies() {
    print_info "安装项目依赖包..."

    if [ -d "$HOME/vcpkg" ]; then
        cd "$HOME/vcpkg"

        # 安装本地架构依赖
        ./vcpkg install curl nlohmann-json --triplet x64-linux

        # 如果交叉编译工具可用，安装交叉编译依赖
        if command -v aarch64-linux-gnu-gcc &>/dev/null; then
            print_info "安装ARM64依赖..."
            ./vcpkg install curl nlohmann-json --triplet arm64-linux
        fi

        if command -v arm-linux-gnueabihf-gcc &>/dev/null; then
            print_info "安装ARM32依赖..."
            ./vcpkg install curl nlohmann-json --triplet arm-linux
        fi

        print_success "依赖包安装完成"
    else
        print_error "vcpkg未安装，跳过依赖包安装"
    fi
}

# 显示帮助
show_help() {
    echo "YumeCard Linux 多架构依赖安装脚本"
    echo ""
    echo "用法: $0 [选项]"
    echo ""
    echo "选项:"
    echo "  --basic         只安装基本构建工具"
    echo "  --cross         只安装交叉编译工具链"
    echo "  --vcpkg         只安装vcpkg"
    echo "  --deps          只安装项目依赖"
    echo "  --all           安装所有组件 (默认)"
    echo "  --help          显示此帮助信息"
    echo ""
    echo "示例:"
    echo "  $0              # 安装所有组件"
    echo "  $0 --basic      # 只安装基本工具"
    echo "  $0 --cross      # 只安装交叉编译工具"
}

# 主函数
main() {
    case "${1:---all}" in
    --basic)
        install_basic_tools
        ;;
    --cross)
        install_cross_compilers
        ;;
    --vcpkg)
        install_vcpkg
        ;;
    --deps)
        install_dependencies
        ;;
    --all)
        install_basic_tools
        install_cross_compilers
        install_vcpkg
        install_dependencies
        ;;
    --help)
        show_help
        ;;
    *)
        print_error "未知选项: $1"
        show_help
        exit 1
        ;;
    esac

    print_success "安装完成！"
    print_info "现在可以运行 './scripts/build_multi_arch.sh' 来构建多架构版本"
}

main "$@"

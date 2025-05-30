#!/bin/bash

# YumeCard 高级多架构构建脚本
# 支持Windows、Linux、macOS的多种架构构建

set -e # 遇到错误就退出

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 打印带颜色的消息
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

# 显示帮助信息
show_help() {
    echo "YumeCard 高级多架构构建脚本"
    echo ""
    echo "用法: $0 [选项] [架构...]"
    echo ""
    echo "架构选项:"
    echo "  x64         构建 x64 架构"
    echo "  x86         构建 x86 架构"
    echo "  arm64       构建 ARM64 架构"
    echo "  arm32       构建 ARM32 架构"
    echo "  universal   构建 macOS 通用二进制"
    echo "  all         构建所有支持的架构"
    echo ""
    echo "选项:"
    echo "  --clean     构建前清理"
    echo "  --debug     构建调试版本"
    echo "  --release   构建发布版本（默认）"
    echo "  --cross     启用交叉编译"
    echo "  --test      构建后运行测试"
    echo "  --package   生成安装包"
    echo "  --parallel  并行构建"
    echo "  --help      显示此帮助信息"
    echo ""
    echo "示例:"
    echo "  $0 x64 arm64                    # 构建 x64 和 ARM64"
    echo "  $0 --clean --debug all          # 清理后构建所有架构的调试版本"
    echo "  $0 --cross --release arm64      # 交叉编译 ARM64 发布版本"
    echo "  $0 --test --package x64         # 构建、测试并打包 x64 版本"
}

# 检测当前平台
detect_platform() {
    case "$(uname -s)" in
    Linux*) echo "Linux" ;;
    Darwin*) echo "macOS" ;;
    CYGWIN* | MINGW* | MSYS*) echo "Windows" ;;
    *) echo "Unknown" ;;
    esac
}

# 检测可用的架构
get_available_architectures() {
    local platform=$1
    case $platform in
    "Linux")
        echo "x64 x86 arm64 arm32"
        ;;
    "macOS")
        echo "x64 arm64 universal"
        ;;
    "Windows")
        echo "x64 x86 arm64 arm32"
        ;;
    *)
        echo "x64"
        ;;
    esac
}

# 获取CMake生成器
get_cmake_generator() {
    local platform=$1
    case $platform in
    "Windows") echo "Visual Studio 17 2022" ;;
    *) echo "Unix Makefiles" ;;
    esac
}

# 获取vcpkg三元组
get_vcpkg_triplet() {
    local platform=$1
    local arch=$2
    case $platform in
    "Windows")
        case $arch in
        "x64") echo "x64-windows" ;;
        "x86") echo "x86-windows" ;;
        "arm64") echo "arm64-windows" ;;
        "arm32") echo "arm-windows" ;;
        esac
        ;;
    "Linux")
        case $arch in
        "x64") echo "x64-linux" ;;
        "x86") echo "x86-linux" ;;
        "arm64") echo "arm64-linux" ;;
        "arm32") echo "arm-linux" ;;
        esac
        ;;
    "macOS")
        case $arch in
        "x64") echo "x64-osx" ;;
        "arm64") echo "arm64-osx" ;;
        "universal") echo "x64-osx" ;;
        esac
        ;;
    esac
}

# 构建单个架构
build_architecture() {
    local platform=$1
    local arch=$2
    local build_type=$3
    local use_cross=$4

    print_info "开始构建 $platform $arch ($build_type)"

    local build_dir="build-$arch"
    local generator=$(get_cmake_generator "$platform")
    local triplet=$(get_vcpkg_triplet "$platform" "$arch")

    # 创建构建目录
    if [ "$CLEAN_BUILD" = "true" ] && [ -d "$build_dir" ]; then
        print_info "清理构建目录: $build_dir"
        rm -rf "$build_dir"
    fi

    mkdir -p "$build_dir"

    # 准备CMake参数
    cmake_args=(
        "-B" "$build_dir"
        "-G" "$generator"
        "-DCMAKE_BUILD_TYPE=$build_type"
        "-DVCPKG_TARGET_TRIPLET=$triplet"
    )

    # 添加vcpkg工具链
    if [ -f "vcpkg/scripts/buildsystems/vcpkg.cmake" ]; then
        cmake_args+=("-DCMAKE_TOOLCHAIN_FILE=vcpkg/scripts/buildsystems/vcpkg.cmake")
    fi

    # 平台特定配置
    case $platform in
    "Windows")
        case $arch in
        "x64") cmake_args+=("-A" "x64") ;;
        "x86") cmake_args+=("-A" "Win32") ;;
        "arm64") cmake_args+=("-A" "ARM64") ;;
        "arm32") cmake_args+=("-A" "ARM") ;;
        esac
        ;;
    "macOS")
        if [ "$arch" = "universal" ]; then
            cmake_args+=("-DCMAKE_OSX_ARCHITECTURES=x86_64;arm64")
        elif [ "$arch" = "arm64" ]; then
            cmake_args+=("-DCMAKE_OSX_ARCHITECTURES=arm64")
        elif [ "$arch" = "x64" ]; then
            cmake_args+=("-DCMAKE_OSX_ARCHITECTURES=x86_64")
        fi
        ;;
    "Linux")
        if [ "$use_cross" = "true" ] && [ "$arch" = "arm64" ]; then
            cmake_args+=("-DCMAKE_TOOLCHAIN_FILE=cmake/toolchains/linux-arm64.cmake")
        elif [ "$use_cross" = "true" ] && [ "$arch" = "arm32" ]; then
            cmake_args+=("-DCMAKE_C_COMPILER=arm-linux-gnueabihf-gcc")
            cmake_args+=("-DCMAKE_CXX_COMPILER=arm-linux-gnueabihf-g++")
        fi
        ;;
    esac

    # 配置项目
    print_info "配置CMake..."
    if ! cmake "${cmake_args[@]}"; then
        print_error "CMake配置失败"
        return 1
    fi

    # 构建项目
    print_info "开始编译..."
    build_cmd=("cmake" "--build" "$build_dir" "--config" "$build_type")

    if [ "$PARALLEL_BUILD" = "true" ]; then
        build_cmd+=("--parallel")
    fi

    if ! "${build_cmd[@]}"; then
        print_error "编译失败"
        return 1
    fi

    print_success "构建完成: $platform $arch"

    # 运行测试
    if [ "$RUN_TESTS" = "true" ]; then
        print_info "运行测试..."
        run_tests "$build_dir" "$platform" "$arch"
    fi

    # 生成包
    if [ "$CREATE_PACKAGE" = "true" ]; then
        print_info "生成安装包..."
        create_package "$build_dir" "$platform" "$arch"
    fi

    return 0
}

# 运行测试
run_tests() {
    local build_dir=$1
    local platform=$2
    local arch=$3

    cd "$build_dir/bin" || return 1

    case $platform in
    "Windows")
        local exe="./YumeCard_${arch}.exe"
        ;;
    *)
        local exe="./YumeCard_${arch}"
        ;;
    esac

    if [ -f "$exe" ]; then
        print_info "测试可执行文件..."
        if $exe help >/dev/null 2>&1; then
            print_success "基本功能测试通过"
        else
            print_warning "基本功能测试失败"
        fi

        print_info "测试系统信息命令..."
        if $exe system-info >/dev/null 2>&1; then
            print_success "系统信息测试通过"
        else
            print_warning "系统信息测试失败"
        fi
    else
        print_warning "可执行文件不存在: $exe"
    fi

    cd ../..
}

# 创建安装包
create_package() {
    local build_dir=$1
    local platform=$2
    local arch=$3

    cd "$build_dir" || return 1

    print_info "生成安装包..."
    if cpack >/dev/null 2>&1; then
        print_success "安装包生成完成"
    else
        print_warning "安装包生成失败"
    fi

    cd ..
}

# 主函数
main() {
    # 默认值
    BUILD_TYPE="Release"
    CLEAN_BUILD=false
    USE_CROSS=false
    RUN_TESTS=false
    CREATE_PACKAGE=false
    PARALLEL_BUILD=false
    ARCHITECTURES=()

    # 解析参数
    while [[ $# -gt 0 ]]; do
        case $1 in
        --help)
            show_help
            exit 0
            ;;
        --clean)
            CLEAN_BUILD=true
            shift
            ;;
        --debug)
            BUILD_TYPE="Debug"
            shift
            ;;
        --release)
            BUILD_TYPE="Release"
            shift
            ;;
        --cross)
            USE_CROSS=true
            shift
            ;;
        --test)
            RUN_TESTS=true
            shift
            ;;
        --package)
            CREATE_PACKAGE=true
            shift
            ;;
        --parallel)
            PARALLEL_BUILD=true
            shift
            ;;
        all)
            platform=$(detect_platform)
            available=$(get_available_architectures "$platform")
            ARCHITECTURES+=($available)
            shift
            ;;
        x64 | x86 | arm64 | arm32 | universal)
            ARCHITECTURES+=("$1")
            shift
            ;;
        *)
            print_error "未知参数: $1"
            show_help
            exit 1
            ;;
        esac
    done

    # 检测平台
    platform=$(detect_platform)
    print_info "检测到平台: $platform"

    # 如果没有指定架构，使用默认架构
    if [ ${#ARCHITECTURES[@]} -eq 0 ]; then
        case $platform in
        "Windows" | "Linux") ARCHITECTURES=("x64") ;;
        "macOS") ARCHITECTURES=("universal") ;;
        *) ARCHITECTURES=("x64") ;;
        esac
        print_info "使用默认架构: ${ARCHITECTURES[*]}"
    fi

    # 显示构建信息
    print_info "构建配置:"
    print_info "  平台: $platform"
    print_info "  架构: ${ARCHITECTURES[*]}"
    print_info "  构建类型: $BUILD_TYPE"
    print_info "  交叉编译: $USE_CROSS"
    print_info "  运行测试: $RUN_TESTS"
    print_info "  生成包: $CREATE_PACKAGE"
    print_info "  并行构建: $PARALLEL_BUILD"
    echo ""

    # 构建每个架构
    success_count=0
    total_count=${#ARCHITECTURES[@]}

    for arch in "${ARCHITECTURES[@]}"; do
        if build_architecture "$platform" "$arch" "$BUILD_TYPE" "$USE_CROSS"; then
            ((success_count++))
        fi
        echo ""
    done

    # 显示构建结果
    print_info "构建完成: $success_count/$total_count 成功"

    if [ $success_count -eq $total_count ]; then
        print_success "所有架构构建成功！"
        exit 0
    else
        print_error "部分架构构建失败"
        exit 1
    fi
}

# 运行主函数
main "$@"

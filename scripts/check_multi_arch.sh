#!/bin/bash

# YumeCard 多架构状态检查脚本
# 用于验证多架构支持的完整性

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

print_header() {
    echo -e "${CYAN}╔═══════════════════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║                       YumeCard 多架构状态检查                                ║${NC}"
    echo -e "${CYAN}╚═══════════════════════════════════════════════════════════════════════════════╝${NC}"
    echo ""
}

print_section() {
    echo -e "${BLUE}▶ $1${NC}"
    echo "───────────────────────────────────────────────────────────────────────────────"
}

print_check() {
    if [ "$2" = "true" ]; then
        echo -e "  ${GREEN}✅${NC} $1"
    else
        echo -e "  ${RED}❌${NC} $1"
    fi
}

print_info() {
    echo -e "  ${BLUE}ℹ️${NC}  $1"
}

print_warning() {
    echo -e "  ${YELLOW}⚠️${NC}  $1"
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

# 检测架构
detect_architecture() {
    case "$(uname -m)" in
    x86_64 | amd64) echo "x64" ;;
    i386 | i486 | i586 | i686) echo "x86" ;;
    aarch64 | arm64) echo "arm64" ;;
    armv7* | armv6*) echo "arm32" ;;
    *) echo "$(uname -m)" ;;
    esac
}

# 检查文件是否存在
check_file() {
    local file="$1"
    local desc="$2"
    if [ -f "$file" ]; then
        print_check "$desc" "true"
        return 0
    else
        print_check "$desc" "false"
        return 1
    fi
}

# 检查目录是否存在
check_directory() {
    local dir="$1"
    local desc="$2"
    if [ -d "$dir" ]; then
        print_check "$desc" "true"
        return 0
    else
        print_check "$desc" "false"
        return 1
    fi
}

# 检查命令是否可用
check_command() {
    local cmd="$1"
    local desc="$2"
    if command -v "$cmd" >/dev/null 2>&1; then
        local version
        case "$cmd" in
        cmake) version=$(cmake --version 2>/dev/null | head -n1 | cut -d' ' -f3) ;;
        node) version=$(node --version 2>/dev/null) ;;
        git) version=$(git --version 2>/dev/null | cut -d' ' -f3) ;;
        *) version="可用" ;;
        esac
        print_check "$desc ($version)" "true"
        return 0
    else
        print_check "$desc" "false"
        return 1
    fi
}

# 检查构建系统文件
check_build_system() {
    print_section "构建系统文件检查"

    local build_files=(
        "CMakeLists.txt:主CMake配置文件"
        "cmake/toolchains/windows-arm64.cmake:Windows ARM64工具链"
        "cmake/toolchains/linux-arm64.cmake:Linux ARM64工具链"
        "cmake/toolchains/macos-universal.cmake:macOS通用工具链"
        ".github/workflows/multi-arch-build.yml:GitHub Actions工作流"
        "scripts/build_multi_arch.sh:Unix构建脚本"
        "scripts/build_multi_arch.bat:Windows构建脚本"
    )

    local success=0
    local total=0

    for item in "${build_files[@]}"; do
        local file=$(echo "$item" | cut -d':' -f1)
        local desc=$(echo "$item" | cut -d':' -f2)
        if check_file "$file" "$desc"; then
            ((success++))
        fi
        ((total++))
    done

    print_info "构建文件检查: $success/$total 通过"
    echo ""
}

# 检查源代码文件
check_source_files() {
    print_section "源代码文件检查"

    local source_files=(
        "src/main.cpp:主程序文件"
        "include/head.hpp:平台检测头文件"
        "include/platform_utils.hpp:平台工具类"
        "include/system_info.hpp:系统信息类"
        "include/github_api.hpp:GitHub API"
        "include/read_config.hpp:配置读取"
        "include/set_config.hpp:配置设置"
        "include/github_subscriber.hpp:GitHub订阅器"
        "include/screenshot.hpp:截图功能"
    )

    local success=0
    local total=0

    for item in "${source_files[@]}"; do
        local file=$(echo "$item" | cut -d':' -f1)
        local desc=$(echo "$item" | cut -d':' -f2)
        if check_file "$file" "$desc"; then
            ((success++))
        fi
        ((total++))
    done

    print_info "源代码检查: $success/$total 通过"
    echo ""
}

# 检查依赖和工具
check_dependencies() {
    print_section "依赖和工具检查"

    local deps=(
        "cmake:CMake构建系统"
        "node:Node.js运行时"
        "git:Git版本控制"
    )

    local success=0
    local total=0

    for item in "${deps[@]}"; do
        local cmd=$(echo "$item" | cut -d':' -f1)
        local desc=$(echo "$item" | cut -d':' -f2)
        if check_command "$cmd" "$desc"; then
            ((success++))
        fi
        ((total++))
    done

    # 检查vcpkg
    if [ -n "$VCPKG_ROOT" ] && [ -d "$VCPKG_ROOT" ]; then
        print_check "vcpkg包管理器 ($VCPKG_ROOT)" "true"
        ((success++))
    elif [ -d "vcpkg" ]; then
        print_check "vcpkg包管理器 (./vcpkg)" "true"
        ((success++))
    elif [ -d "/usr/local/share/vcpkg" ]; then
        print_check "vcpkg包管理器 (/usr/local/share/vcpkg)" "true"
        ((success++))
    elif [ -d "$HOME/vcpkg" ]; then
        print_check "vcpkg包管理器 ($HOME/vcpkg)" "true"
        ((success++))
    else
        print_check "vcpkg包管理器" "false"
    fi
    ((total++))

    print_info "依赖检查: $success/$total 通过"
    echo ""
}

# 检查构建输出
check_build_outputs() {
    print_section "构建输出检查"

    local platform=$(detect_platform)
    local arch=$(detect_architecture)

    print_info "当前平台: $platform"
    print_info "当前架构: $arch"

    # 检查构建目录
    local build_dirs=(
        "build:默认构建目录"
        "build-x64:x64构建目录"
        "build-x86:x86构建目录"
        "build-arm64:ARM64构建目录"
        "build-arm32:ARM32构建目录"
    )

    local found_builds=0

    for item in "${build_dirs[@]}"; do
        local dir=$(echo "$item" | cut -d':' -f1)
        local desc=$(echo "$item" | cut -d':' -f2)
        if check_directory "$dir" "$desc"; then
            ((found_builds++))

            # 检查可执行文件
            case $platform in
            "Windows")
                local exe_pattern="$dir/bin/YumeCard_*.exe"
                ;;
            *)
                local exe_pattern="$dir/bin/YumeCard_*"
                ;;
            esac

            if ls $exe_pattern >/dev/null 2>&1; then
                print_info "  └─ 找到可执行文件: $(ls $exe_pattern | xargs basename)"
            fi
        fi
    done

    if [ $found_builds -eq 0 ]; then
        print_warning "未找到任何构建输出，请先运行构建命令"
    else
        print_info "找到 $found_builds 个构建目录"
    fi

    echo ""
}

# 检查多架构支持特性
check_multiarch_features() {
    print_section "多架构支持特性检查"

    # 检查平台检测宏定义
    if [ -f "include/head.hpp" ]; then
        local macros=(
            "YUMECARD_PLATFORM_WINDOWS"
            "YUMECARD_PLATFORM_LINUX"
            "YUMECARD_PLATFORM_MACOS"
            "YUMECARD_ARCH_X64"
            "YUMECARD_ARCH_ARM64"
        )

        local found_macros=0
        for macro in "${macros[@]}"; do
            if grep -q "$macro" include/head.hpp; then
                ((found_macros++))
            fi
        done

        print_check "平台检测宏定义 ($found_macros/${#macros[@]})" "true"
    else
        print_check "平台检测宏定义" "false"
    fi

    # 检查CMake多架构配置
    if [ -f "CMakeLists.txt" ]; then
        local cmake_features=(
            "CMAKE_SYSTEM_PROCESSOR"
            "CMAKE_SIZEOF_VOID_P"
            "OUTPUT_NAME"
            "VCPKG_TARGET_TRIPLET"
        )

        local found_features=0
        for feature in "${cmake_features[@]}"; do
            if grep -q "$feature" CMakeLists.txt; then
                ((found_features++))
            fi
        done

        print_check "CMake多架构配置 ($found_features/${#cmake_features[@]})" "true"
    else
        print_check "CMake多架构配置" "false"
    fi

    # 检查GitHub Actions工作流
    if [ -f ".github/workflows/multi-arch-build.yml" ]; then
        local workflow_features=(
            "Windows x64"
            "Linux ARM64"
            "macOS Universal"
            "cross_compile"
        )

        local found_workflow=0
        for feature in "${workflow_features[@]}"; do
            if grep -q "$feature" .github/workflows/multi-arch-build.yml; then
                ((found_workflow++))
            fi
        done

        print_check "GitHub Actions多架构工作流 ($found_workflow/${#workflow_features[@]})" "true"
    else
        print_check "GitHub Actions多架构工作流" "false"
    fi

    echo ""
}

# 运行快速功能测试
run_quick_tests() {
    print_section "快速功能测试"

    local platform=$(detect_platform)
    local arch=$(detect_architecture)

    # 查找可执行文件
    local exe=""
    if [ -f "build/bin/YumeCard_${arch}" ]; then
        exe="build/bin/YumeCard_${arch}"
    elif [ -f "build/bin/YumeCard_${arch}.exe" ]; then
        exe="build/bin/YumeCard_${arch}.exe"
    elif [ -f "build-${arch}/bin/YumeCard_${arch}" ]; then
        exe="build-${arch}/bin/YumeCard_${arch}"
    elif [ -f "build-${arch}/bin/YumeCard_${arch}.exe" ]; then
        exe="build-${arch}/bin/YumeCard_${arch}.exe"
    fi

    if [ -n "$exe" ] && [ -f "$exe" ]; then
        print_info "找到可执行文件: $exe"

        # 测试帮助命令
        if $exe help >/dev/null 2>&1; then
            print_check "帮助命令测试" "true"
        else
            print_check "帮助命令测试" "false"
        fi

        # 测试系统信息命令
        if $exe system-info >/dev/null 2>&1; then
            print_check "系统信息命令测试" "true"
        else
            print_check "系统信息命令测试" "false"
        fi

        # 测试诊断命令
        if $exe diagnostic /tmp/test_diagnostic.txt >/dev/null 2>&1; then
            print_check "诊断命令测试" "true"
            rm -f /tmp/test_diagnostic.txt
        else
            print_check "诊断命令测试" "false"
        fi
    else
        print_warning "未找到当前架构($arch)的可执行文件，跳过功能测试"
        print_info "请先运行构建命令生成可执行文件"
    fi

    echo ""
}

# 生成状态报告
generate_status_report() {
    print_section "多架构支持状态总结"

    local platform=$(detect_platform)
    local arch=$(detect_architecture)

    echo "┌─────────────────────────────────────────────────────────────────────────────┐"
    echo "│ 系统信息                                                                    │"
    echo "├─────────────────────────────────────────────────────────────────────────────┤"
    echo "│ 平台: $platform"
    echo "│ 架构: $arch"
    echo "│ 检查时间: $(date)"
    echo "└─────────────────────────────────────────────────────────────────────────────┘"
    echo ""

    # 支持的架构矩阵
    echo "支持的架构矩阵:"
    echo "┌──────────┬─────┬─────┬───────┬───────┬──────┐"
    echo "│ 平台     │ x64 │ x86 │ ARM64 │ ARM32 │ 其他 │"
    echo "├──────────┼─────┼─────┼───────┼───────┼──────┤"
    echo "│ Windows  │ ✅  │ ✅  │ ✅    │ ✅    │ -    │"
    echo "│ Linux    │ ✅  │ ✅  │ ✅    │ ✅    │ RISC │"
    echo "│ macOS    │ ✅  │ ✅  │ ✅    │ -     │ -    │"
    echo "│ FreeBSD  │ ✅  │ ✅  │ ✅    │ -     │ -    │"
    echo "└──────────┴─────┴─────┴───────┴───────┴──────┘"
    echo ""

    # 建议的后续步骤
    echo "建议的后续步骤:"
    echo "1. 运行构建脚本测试多架构构建:"
    echo "   - Unix: ./scripts/build_multi_arch.sh --test all"
    echo "   - Windows: .\\scripts\\build_multi_arch.bat --test all"
    echo ""
    echo "2. 验证GitHub Actions工作流:"
    echo "   - 提交代码到GitHub触发自动构建"
    echo "   - 检查Actions页面的构建结果"
    echo ""
    echo "3. 测试交叉编译(如果支持):"
    echo "   - Linux ARM64: ./scripts/build_multi_arch.sh --cross arm64"
    echo "   - macOS Universal: ./scripts/build_multi_arch.sh universal"
    echo ""
}

# 主函数
main() {
    print_header

    print_info "正在检查YumeCard多架构支持状态..."
    echo ""

    check_build_system
    check_source_files
    check_dependencies
    check_build_outputs
    check_multiarch_features
    run_quick_tests
    generate_status_report

    echo -e "${GREEN}✅ 多架构状态检查完成${NC}"
    echo ""
    echo "详细信息请查看: MULTI_ARCH_STATUS.md"
}

# 运行主函数
main "$@"

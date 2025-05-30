#!/bin/bash
# YumeCard Linux交叉编译测试脚本

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

echo -e "${CYAN}╔═══════════════════════════════════════════════════════════════════════════════╗${NC}"
echo -e "${CYAN}║                     YumeCard Linux交叉编译测试                               ║${NC}"
echo -e "${CYAN}╚═══════════════════════════════════════════════════════════════════════════════╝${NC}"
echo

# 检测当前平台
detect_platform() {
    case "$(uname -s)" in
    Linux*) echo "Linux" ;;
    Darwin*) echo "macOS" ;;
    CYGWIN* | MINGW* | MSYS*) echo "Windows" ;;
    *) echo "Unknown" ;;
    esac
}

PLATFORM=$(detect_platform)
echo -e "${BLUE}▶ 当前平台: $PLATFORM${NC}"
echo

if [[ "$PLATFORM" != "Linux" && "$PLATFORM" != "macOS" ]]; then
    echo -e "${RED}❌ 此脚本仅支持Linux和macOS平台${NC}"
    exit 1
fi

# 检查交叉编译工具
echo -e "${BLUE}▶ 检查交叉编译工具${NC}"
echo "───────────────────────────────────────────────────────────────────────────────"

check_compiler() {
    local name="$1"
    local cmd="$2"

    if command -v "$cmd" >/dev/null 2>&1; then
        local version=$($cmd --version | head -n1)
        echo -e "  ${GREEN}✅${NC} $name: $version"
        return 0
    else
        echo -e "  ${RED}❌${NC} $name 不可用"
        return 1
    fi
}

AVAILABLE_TARGETS=()

# 检查本地编译器
if check_compiler "本地 GCC" "gcc"; then
    AVAILABLE_TARGETS+=("native")
fi

# 检查ARM64交叉编译器
if check_compiler "ARM64 交叉编译器" "aarch64-linux-gnu-gcc"; then
    AVAILABLE_TARGETS+=("arm64")
fi

# 检查ARM32交叉编译器
if check_compiler "ARM32 交叉编译器" "arm-linux-gnueabihf-gcc"; then
    AVAILABLE_TARGETS+=("arm32")
fi

# 检查RISC-V交叉编译器
if check_compiler "RISC-V 交叉编译器" "riscv64-linux-gnu-gcc"; then
    AVAILABLE_TARGETS+=("riscv64")
fi

echo
echo -e "${BLUE}▶ 可用的构建目标: ${AVAILABLE_TARGETS[*]}${NC}"
echo

if [ ${#AVAILABLE_TARGETS[@]} -eq 0 ]; then
    echo -e "${RED}❌ 没有可用的编译器${NC}"
    exit 1
fi

# 测试构建函数
test_build() {
    local target="$1"
    local arch="$2"
    local compiler="$3"
    local build_dir="build-test-$arch"

    echo -e "${YELLOW}▶ 测试构建 $target ($arch)${NC}"
    echo "───────────────────────────────────────────────────────────────────────────────"

    # 清理构建目录
    if [ -d "$build_dir" ]; then
        rm -rf "$build_dir"
    fi

    mkdir -p "$build_dir"
    cd "$build_dir"

    local cmake_args=(
        ".."
        "-DCMAKE_BUILD_TYPE=Release"
    )

    # 根据目标设置特定参数
    case $target in
    "native")
        # 本地构建，无需特殊配置
        ;;
    "arm64")
        cmake_args+=(
            "-DCMAKE_TOOLCHAIN_FILE=../cmake/toolchains/linux-arm64.cmake"
            "-DVCPKG_TARGET_TRIPLET=arm64-linux"
        )
        ;;
    "arm32")
        cmake_args+=(
            "-DCMAKE_C_COMPILER=arm-linux-gnueabihf-gcc"
            "-DCMAKE_CXX_COMPILER=arm-linux-gnueabihf-g++"
            "-DVCPKG_TARGET_TRIPLET=arm-linux"
        )
        ;;
    "riscv64")
        cmake_args+=(
            "-DCMAKE_C_COMPILER=riscv64-linux-gnu-gcc"
            "-DCMAKE_CXX_COMPILER=riscv64-linux-gnu-g++"
            "-DVCPKG_TARGET_TRIPLET=riscv64-linux"
        )
        ;;
    esac

    # 添加vcpkg支持
    if [ -f "../vcpkg/scripts/buildsystems/vcpkg.cmake" ]; then
        cmake_args+=("-DCMAKE_TOOLCHAIN_FILE=../vcpkg/scripts/buildsystems/vcpkg.cmake")
    elif [ -n "$VCPKG_ROOT" ] && [ -f "$VCPKG_ROOT/scripts/buildsystems/vcpkg.cmake" ]; then
        cmake_args+=("-DCMAKE_TOOLCHAIN_FILE=$VCPKG_ROOT/scripts/buildsystems/vcpkg.cmake")
    fi

    echo "  配置CMake..."
    if cmake "${cmake_args[@]}" >/dev/null 2>&1; then
        echo -e "  ${GREEN}✅${NC} CMake配置成功"
    else
        echo -e "  ${RED}❌${NC} CMake配置失败"
        cd ..
        return 1
    fi

    echo "  开始编译..."
    if make -j$(nproc) >/dev/null 2>&1; then
        echo -e "  ${GREEN}✅${NC} 编译成功"

        # 检查生成的可执行文件
        local exe_name=""
        case $arch in
        "native") exe_name="YumeCard_x64" ;;
        "arm64") exe_name="YumeCard_arm64" ;;
        "arm32") exe_name="YumeCard_arm32" ;;
        "riscv64") exe_name="YumeCard_riscv64" ;;
        esac

        if [ -f "bin/$exe_name" ]; then
            local size=$(stat -c%s "bin/$exe_name")
            echo -e "  ${GREEN}✅${NC} 可执行文件: bin/$exe_name (${size} bytes)"

            # 检查文件类型
            local file_type=$(file "bin/$exe_name" | cut -d: -f2)
            echo -e "  ${BLUE}ℹ️${NC}  文件类型: $file_type"
        else
            echo -e "  ${YELLOW}⚠️${NC}  可执行文件不存在: bin/$exe_name"
        fi
    else
        echo -e "  ${RED}❌${NC} 编译失败"
        cd ..
        return 1
    fi

    cd ..
    return 0
}

# 执行测试
SUCCESS_COUNT=0
TOTAL_COUNT=${#AVAILABLE_TARGETS[@]}

for target in "${AVAILABLE_TARGETS[@]}"; do
    case $target in
    "native") test_build "$target" "native" "gcc" ;;
    "arm64") test_build "$target" "arm64" "aarch64-linux-gnu-gcc" ;;
    "arm32") test_build "$target" "arm32" "arm-linux-gnueabihf-gcc" ;;
    "riscv64") test_build "$target" "riscv64" "riscv64-linux-gnu-gcc" ;;
    esac

    if [ $? -eq 0 ]; then
        ((SUCCESS_COUNT++))
    fi
    echo
done

# 测试结果总结
echo -e "${BLUE}▶ 测试结果总结${NC}"
echo "───────────────────────────────────────────────────────────────────────────────"
echo -e "  成功: ${GREEN}$SUCCESS_COUNT${NC}/$TOTAL_COUNT"

if [ $SUCCESS_COUNT -eq $TOTAL_COUNT ]; then
    echo -e "  ${GREEN}✅ 所有交叉编译测试通过${NC}"
    exit 0
else
    echo -e "  ${YELLOW}⚠️  部分交叉编译测试失败${NC}"
    exit 1
fi

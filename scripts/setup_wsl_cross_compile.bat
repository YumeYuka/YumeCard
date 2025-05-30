@echo off
REM YumeCard Windows子系统Linux (WSL) 支持脚本

setlocal enabledelayedexpansion

set "RED=[91m"
set "GREEN=[92m"
set "YELLOW=[93m"
set "BLUE=[94m"
set "CYAN=[96m"
set "NC=[0m"

echo %CYAN%═══════════════════════════════════════════════════════════════════════════════%NC%
echo %CYAN%                     YumeCard WSL多平台编译支持                               %NC%
echo %CYAN%═══════════════════════════════════════════════════════════════════════════════%NC%
echo.

REM 检查WSL是否安装
echo %BLUE%▶ 检查WSL环境%NC%
echo ───────────────────────────────────────────────────────────────────────────────

wsl --version >nul 2>&1
if errorlevel 1 (
    echo   %RED%❌%NC% WSL 未安装
    echo   %BLUE%ℹ️%NC%  请先安装WSL: wsl --install
    echo   %BLUE%ℹ️%NC%  或参考: https://docs.microsoft.com/en-us/windows/wsl/install
    pause
    exit /b 1
) else (
    echo   %GREEN%✅%NC% WSL 已安装
)

REM 列出可用的WSL发行版
echo   %BLUE%ℹ️%NC%  可用的WSL发行版:
wsl --list --verbose

echo.

REM 检查默认WSL发行版
for /f "tokens=2" %%i in ('wsl --list --quiet') do (
    set "DEFAULT_DISTRO=%%i"
    goto :found_default
)
:found_default

if not defined DEFAULT_DISTRO (
    echo   %RED%❌%NC% 未找到默认WSL发行版
    echo   %BLUE%ℹ️%NC%  请先安装Linux发行版，推荐: wsl --install -d Ubuntu
    pause
    exit /b 1
)

echo   %GREEN%✅%NC% 默认WSL发行版: %DEFAULT_DISTRO%
echo.

REM 在WSL中设置开发环境
echo %BLUE%▶ 在WSL中设置开发环境%NC%
echo ───────────────────────────────────────────────────────────────────────────────

echo   正在WSL中安装构建工具...
wsl -e bash -c "sudo apt-get update && sudo apt-get install -y build-essential cmake git curl wget ninja-build"

if errorlevel 1 (
    echo   %RED%❌%NC% WSL构建工具安装失败
    pause
    exit /b 1
)

echo   %GREEN%✅%NC% WSL构建工具安装完成
echo.

REM 安装交叉编译工具链
echo %BLUE%▶ 安装交叉编译工具链%NC%
echo ───────────────────────────────────────────────────────────────────────────────

echo   正在安装ARM64交叉编译工具链...
wsl -e bash -c "sudo apt-get install -y gcc-aarch64-linux-gnu g++-aarch64-linux-gnu"

echo   正在安装ARM32交叉编译工具链...
wsl -e bash -c "sudo apt-get install -y gcc-arm-linux-gnueabihf g++-arm-linux-gnueabihf"

echo   正在安装multilib支持...
wsl -e bash -c "sudo apt-get install -y gcc-multilib g++-multilib"

echo   %GREEN%✅%NC% 交叉编译工具链安装完成
echo.

REM 在WSL中安装vcpkg
echo %BLUE%▶ 在WSL中安装vcpkg%NC%
echo ───────────────────────────────────────────────────────────────────────────────

wsl -e bash -c "
if [ ! -d \"\$HOME/vcpkg\" ]; then
    echo '  克隆vcpkg仓库...'
    git clone https://github.com/Microsoft/vcpkg.git \$HOME/vcpkg
    cd \$HOME/vcpkg
    ./bootstrap-vcpkg.sh
    echo 'export VCPKG_ROOT=\"\$HOME/vcpkg\"' >> \$HOME/.bashrc
    echo 'export PATH=\"\$PATH:\$HOME/vcpkg\"' >> \$HOME/.bashrc
    echo '  vcpkg安装完成'
else
    echo '  vcpkg已存在'
fi
"

echo   %GREEN%✅%NC% vcpkg安装完成
echo.

REM 安装依赖包
echo %BLUE%▶ 在WSL中安装项目依赖%NC%
echo ───────────────────────────────────────────────────────────────────────────────

echo   正在安装x64依赖...
wsl -e bash -c "
source \$HOME/.bashrc
cd \$HOME/vcpkg
./vcpkg install curl:x64-linux nlohmann-json:x64-linux
"

echo   正在安装ARM64依赖...
wsl -e bash -c "
source \$HOME/.bashrc
cd \$HOME/vcpkg
./vcpkg install curl:arm64-linux nlohmann-json:arm64-linux || echo '  ARM64依赖安装可能失败，这是正常的'
"

echo   %GREEN%✅%NC% 依赖包安装完成
echo.

REM 创建WSL构建脚本
echo %BLUE%▶ 创建WSL构建脚本%NC%
echo ───────────────────────────────────────────────────────────────────────────────

REM 获取当前Windows路径并转换为WSL路径
for %%I in ("%CD%") do set "WIN_PROJECT_PATH=%%~fI"
set "WSL_PROJECT_PATH=%WIN_PROJECT_PATH:\=/%"
set "WSL_PROJECT_PATH=%WSL_PROJECT_PATH:C:=/mnt/c%"

REM 创建WSL构建脚本
(
echo #!/bin/bash
echo # YumeCard WSL构建脚本
echo.
echo set -e
echo.
echo PROJECT_ROOT="%WSL_PROJECT_PATH%"
echo cd "$PROJECT_ROOT"
echo.
echo echo "在WSL中构建YumeCard..."
echo.
echo # 设置环境变量
echo export VCPKG_ROOT="$HOME/vcpkg"
echo export PATH="$PATH:$HOME/vcpkg"
echo.
echo # 创建构建目录
echo mkdir -p build-wsl-x64
echo cd build-wsl-x64
echo.
echo # 配置CMake
echo cmake .. \
echo     -DCMAKE_BUILD_TYPE=Release \
echo     -DCMAKE_TOOLCHAIN_FILE="$VCPKG_ROOT/scripts/buildsystems/vcpkg.cmake" \
echo     -DVCPKG_TARGET_TRIPLET=x64-linux \
echo     -GNinja
echo.
echo # 构建
echo ninja
echo.
echo echo "WSL构建完成: build-wsl-x64/bin/"
echo.
echo # 如果有ARM64工具链，也构建ARM64版本
echo if command -v aarch64-linux-gnu-gcc ^^^>/dev/null 2^^^>^^^&1; then
echo     echo "构建ARM64版本..."
echo     cd "$PROJECT_ROOT"
echo     mkdir -p build-wsl-arm64
echo     cd build-wsl-arm64
echo     
echo     cmake .. \
echo         -DCMAKE_BUILD_TYPE=Release \
echo         -DCMAKE_TOOLCHAIN_FILE="../cmake/toolchains/linux-arm64.cmake" \
echo         -DVCPKG_CHAINLOAD_TOOLCHAIN_FILE="$VCPKG_ROOT/scripts/buildsystems/vcpkg.cmake" \
echo         -DVCPKG_TARGET_TRIPLET=arm64-linux \
echo         -GNinja
echo     
echo     ninja
echo     echo "WSL ARM64构建完成: build-wsl-arm64/bin/"
echo fi
) > build_wsl.sh

echo   %GREEN%✅%NC% WSL构建脚本创建完成: build_wsl.sh
echo.

REM 创建Windows批处理文件来调用WSL构建
(
echo @echo off
echo REM 使用WSL构建YumeCard
echo.
echo echo 使用WSL构建YumeCard...
echo wsl -e bash ./build_wsl.sh
echo.
echo if errorlevel 1 ^(
echo     echo 构建失败
echo     pause
echo     exit /b 1
echo ^)
echo.
echo echo WSL构建完成^^!
echo echo.
echo echo 可执行文件位置:
echo if exist "build-wsl-x64\bin\" ^(
echo     echo   x64版本: build-wsl-x64\bin\
echo ^)
echo if exist "build-wsl-arm64\bin\" ^(
echo     echo   ARM64版本: build-wsl-arm64\bin\
echo ^)
echo.
echo pause
) > build_with_wsl.bat

echo   %GREEN%✅%NC% Windows WSL构建脚本创建完成: build_with_wsl.bat
echo.

REM 测试WSL环境
echo %BLUE%▶ 测试WSL环境%NC%
echo ───────────────────────────────────────────────────────────────────────────────

echo   测试WSL中的构建工具...
wsl -e bash -c "cmake --version && gcc --version" >nul 2>&1
if errorlevel 1 (
    echo   %RED%❌%NC% WSL构建工具测试失败
) else (
    echo   %GREEN%✅%NC% WSL构建工具正常
)

echo   测试WSL中的vcpkg...
wsl -e bash -c "source ~/.bashrc && \$VCPKG_ROOT/vcpkg version" >nul 2>&1
if errorlevel 1 (
    echo   %YELLOW%⚠️%NC%  WSL vcpkg可能需要手动配置
) else (
    echo   %GREEN%✅%NC% WSL vcpkg正常
)

echo.

REM 如果用户要求测试构建
if "%1"=="--test" (
    echo %BLUE%▶ 测试构建%NC%
    echo ───────────────────────────────────────────────────────────────────────────────
    
    echo   开始测试WSL构建...
    call build_with_wsl.bat
    
    if exist "build-wsl-x64\bin\YumeCard_x64" (
        echo   %GREEN%✅%NC% WSL构建测试成功
    ) else (
        echo   %RED%❌%NC% WSL构建测试失败
    )
    echo.
)

REM 总结
echo %BLUE%▶ WSL设置完成总结%NC%
echo ───────────────────────────────────────────────────────────────────────────────
echo   %GREEN%✅%NC% WSL多平台编译环境设置完成
echo.
echo 可用的构建命令:
echo   Windows本地构建:    .\scripts\build_multi_arch.bat
echo   WSL Linux构建:      .\build_with_wsl.bat
echo   直接WSL构建:        wsl bash ./build_wsl.sh
echo.
echo WSL中的工具:
echo   进入WSL:           wsl
echo   WSL中的项目路径:    %WSL_PROJECT_PATH%
echo.
echo 状态检查:
echo   检查状态:          .\scripts\check_multi_arch.bat
echo.

echo %GREEN%✅ WSL多平台编译支持设置完成%NC%
echo.
echo %BLUE%ℹ️%NC%  现在你可以在Windows上构建Windows版本，在WSL中构建Linux版本
echo %BLUE%ℹ️%NC%  使用 --test 参数来测试WSL构建
echo.
pause

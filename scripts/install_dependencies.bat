@echo off
setlocal enabledelayedexpansion

REM YumeCard 多架构依赖安装脚本 (Windows)

set "RED=[91m"
set "GREEN=[92m"
set "YELLOW=[93m"
set "BLUE=[94m"
set "NC=[0m"

:main
if "%1"=="--help" goto show_help
if "%1"=="--basic" goto install_basic
if "%1"=="--vcpkg" goto install_vcpkg
if "%1"=="--deps" goto install_deps
if "%1"=="--all" goto install_all
if "%1"=="" goto install_all

echo %RED%[ERROR]%NC% 未知选项: %1
goto show_help

:install_all
call :install_basic
call :install_vcpkg
call :install_deps
goto end

:install_basic
echo %BLUE%[INFO]%NC% 检查基本工具...

REM 检查CMake
cmake --version >nul 2>&1
if errorlevel 1 (
    echo %YELLOW%[WARNING]%NC% CMake 未找到
    echo %BLUE%[INFO]%NC% 请从 https://cmake.org/download/ 下载安装
) else (
    echo %GREEN%[SUCCESS]%NC% CMake 已安装
)

REM 检查Node.js
node --version >nul 2>&1
if errorlevel 1 (
    echo %YELLOW%[WARNING]%NC% Node.js 未找到
    echo %BLUE%[INFO]%NC% 请从 https://nodejs.org/ 下载安装
) else (
    echo %GREEN%[SUCCESS]%NC% Node.js 已安装
)

REM 检查Git
git --version >nul 2>&1
if errorlevel 1 (
    echo %YELLOW%[WARNING]%NC% Git 未找到
    echo %BLUE%[INFO]%NC% 请从 https://git-scm.com/ 下载安装
) else (
    echo %GREEN%[SUCCESS]%NC% Git 已安装
)

REM 检查Visual Studio
if exist "C:\Program Files\Microsoft Visual Studio\2022\Professional\MSBuild\Current\Bin\MSBuild.exe" (
    echo %GREEN%[SUCCESS]%NC% Visual Studio 2022 Professional 已安装
) else if exist "C:\Program Files\Microsoft Visual Studio\2022\Community\MSBuild\Current\Bin\MSBuild.exe" (
    echo %GREEN%[SUCCESS]%NC% Visual Studio 2022 Community 已安装
) else if exist "C:\Program Files\Microsoft Visual Studio\2022\Enterprise\MSBuild\Current\Bin\MSBuild.exe" (
    echo %GREEN%[SUCCESS]%NC% Visual Studio 2022 Enterprise 已安装
) else (
    echo %YELLOW%[WARNING]%NC% Visual Studio 2022 未找到
    echo %BLUE%[INFO]%NC% 请安装 Visual Studio 2022 并包含 C++ 构建工具
)

echo %GREEN%[SUCCESS]%NC% 基本工具检查完成
goto :eof

:install_vcpkg
echo %BLUE%[INFO]%NC% 检查vcpkg安装...

set "vcpkg_found=false"

if exist "C:\tool\vcpkg\vcpkg.exe" (
    set "vcpkg_found=true"
    set "vcpkg_path=C:\tool\vcpkg"
    echo %GREEN%[SUCCESS]%NC% vcpkg 已安装在 C:\tool\vcpkg
) else if exist "C:\vcpkg\vcpkg.exe" (
    set "vcpkg_found=true"
    set "vcpkg_path=C:\vcpkg"
    echo %GREEN%[SUCCESS]%NC% vcpkg 已安装在 C:\vcpkg
) else if defined VCPKG_ROOT (
    if exist "%VCPKG_ROOT%\vcpkg.exe" (
        set "vcpkg_found=true"
        set "vcpkg_path=%VCPKG_ROOT%"
        echo %GREEN%[SUCCESS]%NC% vcpkg 已安装在 %VCPKG_ROOT%
    )
)

if "%vcpkg_found%"=="false" (
    echo %YELLOW%[WARNING]%NC% vcpkg 未找到
    echo %BLUE%[INFO]%NC% 建议安装步骤:
    echo   1. git clone https://github.com/Microsoft/vcpkg.git C:\tool\vcpkg
    echo   2. cd C:\tool\vcpkg
    echo   3. .\bootstrap-vcpkg.bat
    echo   4. 设置环境变量 VCPKG_ROOT=C:\tool\vcpkg
) else (
    echo %BLUE%[INFO]%NC% 更新vcpkg...
    pushd "!vcpkg_path!"
    git pull
    .\bootstrap-vcpkg.bat
    popd
    echo %GREEN%[SUCCESS]%NC% vcpkg 更新完成
)

goto :eof

:install_deps
echo %BLUE%[INFO]%NC% 安装项目依赖...

set "vcpkg_exe="

if exist "C:\tool\vcpkg\vcpkg.exe" (
    set "vcpkg_exe=C:\tool\vcpkg\vcpkg.exe"
) else if exist "C:\vcpkg\vcpkg.exe" (
    set "vcpkg_exe=C:\vcpkg\vcpkg.exe"
) else if defined VCPKG_ROOT (
    if exist "%VCPKG_ROOT%\vcpkg.exe" (
        set "vcpkg_exe=%VCPKG_ROOT%\vcpkg.exe"
    )
)

if "%vcpkg_exe%"=="" (
    echo %RED%[ERROR]%NC% vcpkg 未找到，无法安装依赖
    goto :eof
)

echo %BLUE%[INFO]%NC% 使用vcpkg: %vcpkg_exe%

REM 安装x64依赖
echo %BLUE%[INFO]%NC% 安装x64依赖...
"%vcpkg_exe%" install curl nlohmann-json --triplet x64-windows
if errorlevel 1 (
    echo %YELLOW%[WARNING]%NC% x64依赖安装可能有问题
) else (
    echo %GREEN%[SUCCESS]%NC% x64依赖安装完成
)

REM 安装x86依赖
echo %BLUE%[INFO]%NC% 安装x86依赖...
"%vcpkg_exe%" install curl nlohmann-json --triplet x86-windows
if errorlevel 1 (
    echo %YELLOW%[WARNING]%NC% x86依赖安装可能有问题
) else (
    echo %GREEN%[SUCCESS]%NC% x86依赖安装完成
)

REM 尝试安装ARM64依赖（可能需要特殊支持）
echo %BLUE%[INFO]%NC% 尝试安装ARM64依赖...
"%vcpkg_exe%" install curl nlohmann-json --triplet arm64-windows
if errorlevel 1 (
    echo %YELLOW%[WARNING]%NC% ARM64依赖安装失败（可能需要特殊编译器支持）
) else (
    echo %GREEN%[SUCCESS]%NC% ARM64依赖安装完成
)

echo %GREEN%[SUCCESS]%NC% 依赖安装完成

goto :eof

:show_help
echo YumeCard Windows 多架构依赖安装脚本
echo.
echo 用法: %~nx0 [选项]
echo.
echo 选项:
echo   --basic         只检查基本构建工具
echo   --vcpkg         只检查/安装vcpkg
echo   --deps          只安装项目依赖
echo   --all           检查所有组件 (默认)
echo   --help          显示此帮助信息
echo.
echo 示例:
echo   %~nx0              # 检查所有组件
echo   %~nx0 --basic      # 只检查基本工具
echo   %~nx0 --vcpkg      # 只处理vcpkg
echo   %~nx0 --deps       # 只安装依赖
goto :eof

:end
echo %GREEN%[SUCCESS]%NC% 安装检查完成！
echo %BLUE%[INFO]%NC% 现在可以运行 '.\scripts\build_multi_arch.bat' 来构建多架构版本

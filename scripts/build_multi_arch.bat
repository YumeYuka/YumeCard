@echo off
setlocal enabledelayedexpansion

REM YumeCard 高级多架构构建脚本 (Windows版本)
REM 支持Windows的多种架构构建

set "RED=[91m"
set "GREEN=[92m"
set "YELLOW=[93m"
set "BLUE=[94m"
set "NC=[0m"

REM 默认值
set "BUILD_TYPE=Release"
set "CLEAN_BUILD=false"
set "RUN_TESTS=false"
set "CREATE_PACKAGE=false"
set "PARALLEL_BUILD=false"
set "ARCHITECTURES="

:parse_args
if "%~1"=="" goto end_parse
if "%~1"=="--help" goto show_help
if "%~1"=="--clean" set "CLEAN_BUILD=true" & shift & goto parse_args
if "%~1"=="--debug" set "BUILD_TYPE=Debug" & shift & goto parse_args
if "%~1"=="--release" set "BUILD_TYPE=Release" & shift & goto parse_args
if "%~1"=="--test" set "RUN_TESTS=true" & shift & goto parse_args
if "%~1"=="--package" set "CREATE_PACKAGE=true" & shift & goto parse_args
if "%~1"=="--parallel" set "PARALLEL_BUILD=true" & shift & goto parse_args
if "%~1"=="all" set "ARCHITECTURES=x64 x86 arm64 arm32" & shift & goto parse_args
if "%~1"=="x64" set "ARCHITECTURES=!ARCHITECTURES! x64" & shift & goto parse_args
if "%~1"=="x86" set "ARCHITECTURES=!ARCHITECTURES! x86" & shift & goto parse_args
if "%~1"=="arm64" set "ARCHITECTURES=!ARCHITECTURES! arm64" & shift & goto parse_args
if "%~1"=="arm32" set "ARCHITECTURES=!ARCHITECTURES! arm32" & shift & goto parse_args
echo %RED%[ERROR]%NC% 未知参数: %~1
goto show_help

:end_parse

REM 如果没有指定架构，使用默认x64
if "%ARCHITECTURES%"=="" set "ARCHITECTURES=x64"

echo %BLUE%[INFO]%NC% YumeCard Windows 多架构构建脚本
echo %BLUE%[INFO]%NC% 构建配置:
echo %BLUE%[INFO]%NC%   架构: %ARCHITECTURES%
echo %BLUE%[INFO]%NC%   构建类型: %BUILD_TYPE%
echo %BLUE%[INFO]%NC%   运行测试: %RUN_TESTS%
echo %BLUE%[INFO]%NC%   生成包: %CREATE_PACKAGE%
echo %BLUE%[INFO]%NC%   并行构建: %PARALLEL_BUILD%
echo.

set "success_count=0"
set "total_count=0"

for %%a in (%ARCHITECTURES%) do (
    set /a total_count+=1
    call :build_architecture %%a
    if !errorlevel! equ 0 (
        set /a success_count+=1
    )
    echo.
)

echo %BLUE%[INFO]%NC% 构建完成: !success_count!/!total_count! 成功

if !success_count! equ !total_count! (
    echo %GREEN%[SUCCESS]%NC% 所有架构构建成功！
    exit /b 0
) else (
    echo %RED%[ERROR]%NC% 部分架构构建失败
    exit /b 1
)

:build_architecture
set "arch=%~1"
echo %BLUE%[INFO]%NC% 开始构建 Windows %arch% ^(%BUILD_TYPE%^)

set "build_dir=build-%arch%"
set "generator=Visual Studio 17 2022"

REM 设置平台和三元组
if "%arch%"=="x64" (
    set "platform=x64"
    set "triplet=x64-windows"
) else if "%arch%"=="x86" (
    set "platform=Win32"
    set "triplet=x86-windows"
) else if "%arch%"=="arm64" (
    set "platform=ARM64"
    set "triplet=arm64-windows"
    
    REM 检查ARM64编译器支持
    echo %BLUE%[INFO]%NC% 检查ARM64编译器支持...
    cl 2>&1 | findstr /c:"for ARM64" >nul
    if errorlevel 1 (
        echo %YELLOW%[WARNING]%NC% ARM64编译器可能不可用
        echo %YELLOW%[WARNING]%NC% 请确保安装了Visual Studio ARM64组件
        echo %YELLOW%[WARNING]%NC% 将尝试使用工具链文件进行配置
        set "use_toolchain=true"
    ) else (
        echo %GREEN%[SUCCESS]%NC% ARM64编译器可用
        set "use_toolchain=false"
    )
) else if "%arch%"=="arm32" (
    set "platform=ARM"
    set "triplet=arm-windows"
    
    REM 检查Windows SDK对ARM32的支持
    echo %YELLOW%[WARNING]%NC% ARM32可能需要较旧的Windows SDK版本
) else (
    echo %RED%[ERROR]%NC% 不支持的架构: %arch%
    exit /b 1
)

REM 清理构建目录
if "%CLEAN_BUILD%"=="true" (
    if exist "%build_dir%" (
        echo %BLUE%[INFO]%NC% 清理构建目录: %build_dir%
        rmdir /s /q "%build_dir%"
    )
)

if not exist "%build_dir%" mkdir "%build_dir%"

REM 配置CMake
echo %BLUE%[INFO]%NC% 配置CMake...

REM 特殊处理ARM64架构
if "%arch%"=="arm64" (
    if "%use_toolchain%"=="true" (
        if exist "cmake\toolchains\windows-arm64.cmake" (
            set "cmake_cmd=cmake -B %build_dir% -G "%generator%" -DCMAKE_TOOLCHAIN_FILE=cmake\toolchains\windows-arm64.cmake -DCMAKE_BUILD_TYPE=%BUILD_TYPE% -DVCPKG_TARGET_TRIPLET=%triplet%"
            echo %BLUE%[INFO]%NC% 使用ARM64工具链文件
        ) else (
            echo %RED%[ERROR]%NC% ARM64工具链文件不存在: cmake\toolchains\windows-arm64.cmake
            exit /b 1
        )
    ) else (
        set "cmake_cmd=cmake -B %build_dir% -G "%generator%" -A %platform% -DCMAKE_BUILD_TYPE=%BUILD_TYPE% -DVCPKG_TARGET_TRIPLET=%triplet%"
    )
) else (
    set "cmake_cmd=cmake -B %build_dir% -G "%generator%" -A %platform% -DCMAKE_BUILD_TYPE=%BUILD_TYPE% -DVCPKG_TARGET_TRIPLET=%triplet%"
)

REM 添加vcpkg工具链
set "vcpkg_toolchain="
if exist "vcpkg\scripts\buildsystems\vcpkg.cmake" (
    set "vcpkg_toolchain=vcpkg\scripts\buildsystems\vcpkg.cmake"
) else if exist "C:\tool\vcpkg\scripts\buildsystems\vcpkg.cmake" (
    set "vcpkg_toolchain=C:\tool\vcpkg\scripts\buildsystems\vcpkg.cmake"
) else if exist "C:\vcpkg\scripts\buildsystems\vcpkg.cmake" (
    set "vcpkg_toolchain=C:\vcpkg\scripts\buildsystems\vcpkg.cmake"
) else if defined VCPKG_ROOT (
    if exist "%VCPKG_ROOT%\scripts\buildsystems\vcpkg.cmake" (
        set "vcpkg_toolchain=%VCPKG_ROOT%\scripts\buildsystems\vcpkg.cmake"
    )
)

if not "%vcpkg_toolchain%"=="" (
    echo %BLUE%[INFO]%NC% 使用vcpkg工具链: %vcpkg_toolchain%
    set "cmake_cmd=!cmake_cmd! -DCMAKE_TOOLCHAIN_FILE=%vcpkg_toolchain%"
) else (
    echo %YELLOW%[WARNING]%NC% 未找到vcpkg工具链，可能导致依赖库查找失败
)

%cmake_cmd%
if errorlevel 1 (
    echo %RED%[ERROR]%NC% CMake配置失败
    exit /b 1
)

REM 构建项目
echo %BLUE%[INFO]%NC% 开始编译...
set "build_cmd=cmake --build %build_dir% --config %BUILD_TYPE%"

if "%PARALLEL_BUILD%"=="true" (
    set "build_cmd=!build_cmd! --parallel"
)

%build_cmd%
if errorlevel 1 (
    echo %RED%[ERROR]%NC% 编译失败
    exit /b 1
)

echo %GREEN%[SUCCESS]%NC% 构建完成: Windows %arch%

REM 运行测试
if "%RUN_TESTS%"=="true" (
    call :run_tests "%build_dir%" "%arch%"
)

REM 生成包
if "%CREATE_PACKAGE%"=="true" (
    call :create_package "%build_dir%" "%arch%"
)

exit /b 0

:run_tests
set "build_dir=%~1"
set "arch=%~2"

echo %BLUE%[INFO]%NC% 运行测试...
pushd "%build_dir%\bin"

set "exe=YumeCard_%arch%.exe"
if not exist "%exe%" (
    echo %YELLOW%[WARNING]%NC% 可执行文件不存在: %exe%
    popd
    exit /b 0
)

echo %BLUE%[INFO]%NC% 测试可执行文件...
%exe% help >nul 2>&1
if errorlevel 1 (
    echo %YELLOW%[WARNING]%NC% 基本功能测试失败
) else (
    echo %GREEN%[SUCCESS]%NC% 基本功能测试通过
)

echo %BLUE%[INFO]%NC% 测试系统信息命令...
%exe% system-info >nul 2>&1
if errorlevel 1 (
    echo %YELLOW%[WARNING]%NC% 系统信息测试失败
) else (
    echo %GREEN%[SUCCESS]%NC% 系统信息测试通过
)

popd
exit /b 0

:create_package
set "build_dir=%~1"
set "arch=%~2"

echo %BLUE%[INFO]%NC% 生成安装包...
pushd "%build_dir%"

cpack >nul 2>&1
if errorlevel 1 (
    echo %YELLOW%[WARNING]%NC% 安装包生成失败
) else (
    echo %GREEN%[SUCCESS]%NC% 安装包生成完成
)

popd
exit /b 0

:show_help
echo YumeCard Windows 多架构构建脚本
echo.
echo 用法: %~nx0 [选项] [架构...]
echo.
echo 架构选项:
echo   x64         构建 x64 架构
echo   x86         构建 x86 架构
echo   arm64       构建 ARM64 架构
echo   arm32       构建 ARM32 架构
echo   all         构建所有支持的架构
echo.
echo 选项:
echo   --clean     构建前清理
echo   --debug     构建调试版本
echo   --release   构建发布版本（默认）
echo   --test      构建后运行测试
echo   --package   生成安装包
echo   --parallel  并行构建
echo   --help      显示此帮助信息
echo.
echo 示例:
echo   %~nx0 x64 arm64                    # 构建 x64 和 ARM64
echo   %~nx0 --clean --debug all          # 清理后构建所有架构的调试版本
echo   %~nx0 --test --package x64         # 构建、测试并打包 x64 版本
exit /b 0

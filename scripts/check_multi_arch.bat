@echo off
setlocal enabledelayedexpansion

REM YumeCard 多架构支持状态检查脚本 (Windows版本)

set "RED=[91m"
set "GREEN=[92m"
set "YELLOW=[93m"
set "BLUE=[94m"
set "CYAN=[96m"
set "NC=[0m"

echo %CYAN%╔═══════════════════════════════════════════════════════════════════════════════╗%NC%
echo %CYAN%║                     YumeCard 多架构支持状态检查                              ║%NC%
echo %CYAN%╚═══════════════════════════════════════════════════════════════════════════════╝%NC%
echo.

REM 设置项目根目录
cd /d "%~dp0\.."
set "PROJECT_ROOT=%CD%"

REM 检查构建系统文件
echo %BLUE%▶ 构建系统文件检查%NC%
echo ───────────────────────────────────────────────────────────────────────────────
call :check_file "%PROJECT_ROOT%\CMakeLists.txt" "主CMake配置文件"
call :check_file "%PROJECT_ROOT%\cmake\toolchains\windows-arm64.cmake" "Windows ARM64工具链"
call :check_file "%PROJECT_ROOT%\cmake\toolchains\linux-arm64.cmake" "Linux ARM64工具链"
call :check_file "%PROJECT_ROOT%\cmake\toolchains\macos-universal.cmake" "macOS通用工具链"
call :check_file "%PROJECT_ROOT%\.github\workflows\multi-arch-build.yml" "GitHub Actions工作流"
call :check_file "%PROJECT_ROOT%\scripts\build_multi_arch.sh" "Unix构建脚本"
call :check_file "%PROJECT_ROOT%\scripts\build_multi_arch.bat" "Windows构建脚本"
echo.

REM 检查源代码文件
echo %BLUE%▶ 源代码文件检查%NC%
echo ───────────────────────────────────────────────────────────────────────────────
call :check_file "%PROJECT_ROOT%\src\main.cpp" "主程序文件"
call :check_file "%PROJECT_ROOT%\include\head.hpp" "平台检测头文件"
call :check_file "%PROJECT_ROOT%\include\platform_utils.hpp" "平台工具类"
call :check_file "%PROJECT_ROOT%\include\system_info.hpp" "系统信息类"
call :check_file "%PROJECT_ROOT%\include\github_api.hpp" "GitHub API"
call :check_file "%PROJECT_ROOT%\include\read_config.hpp" "配置读取"
call :check_file "%PROJECT_ROOT%\include\set_config.hpp" "配置设置"
call :check_file "%PROJECT_ROOT%\include\github_subscriber.hpp" "GitHub订阅器"
call :check_file "%PROJECT_ROOT%\include\screenshot.hpp" "截图功能"
echo.

REM 检查依赖和工具
echo %BLUE%▶ 依赖和工具检查%NC%
echo ───────────────────────────────────────────────────────────────────────────────
call :check_command "cmake" "CMake构建系统"
call :check_command "node" "Node.js运行时"
call :check_command "git" "Git版本控制"

REM 检查vcpkg
if exist "C:\tool\vcpkg\vcpkg.exe" (
    echo   %GREEN%✅%NC% vcpkg包管理器 (C:\tool\vcpkg)
) else if exist "C:\vcpkg\vcpkg.exe" (
    echo   %GREEN%✅%NC% vcpkg包管理器 (C:\vcpkg)
) else if defined VCPKG_ROOT (
    if exist "%VCPKG_ROOT%\vcpkg.exe" (
        echo   %GREEN%✅%NC% vcpkg包管理器 (%VCPKG_ROOT%)
    ) else (
        echo   %RED%❌%NC% vcpkg包管理器
    )
) else (
    echo   %RED%❌%NC% vcpkg包管理器
)
echo.

REM 检查构建输出
echo %BLUE%▶ 构建输出检查%NC%
echo ───────────────────────────────────────────────────────────────────────────────
echo   %BLUE%ℹ️%NC%  当前平台: Windows
echo   %BLUE%ℹ️%NC%  当前架构: %PROCESSOR_ARCHITECTURE%

set "found_builds=0"

for %%d in (build build-x64 build-x86 build-arm64 build-arm32) do (
    if exist "%%d" (
        echo   %GREEN%✅%NC% 构建目录: %%d
        set /a found_builds+=1
        
        REM 检查可执行文件
        if exist "%%d\bin\YumeCard_*.exe" (
            for %%f in (%%d\bin\YumeCard_*.exe) do (
                echo     └─ 找到可执行文件: %%~nxf
            )
        )
    ) else (
        echo   %RED%❌%NC% 构建目录: %%d
    )
)

if !found_builds! equ 0 (
    echo   %YELLOW%⚠️%NC%  未找到任何构建输出，请先运行构建命令
) else (
    echo   %BLUE%ℹ️%NC%  找到 !found_builds! 个构建目录
)
echo.

REM 检查多架构支持特性
echo %BLUE%▶ 多架构支持特性检查%NC%
echo ───────────────────────────────────────────────────────────────────────────────

REM 检查平台检测宏定义
if exist "include\head.hpp" (
    findstr /c:"YUMECARD_PLATFORM_WINDOWS" "include\head.hpp" >nul && (
        set "found_macros=1"
    ) || (
        set "found_macros=0"
    )
    
    if !found_macros! gtr 0 (
        echo   %GREEN%✅%NC% 平台检测宏定义
    ) else (
        echo   %RED%❌%NC% 平台检测宏定义
    )
) else (
    echo   %RED%❌%NC% 平台检测宏定义
)

REM 检查CMake多架构配置
if exist "CMakeLists.txt" (
    findstr /c:"CMAKE_SYSTEM_PROCESSOR" "CMakeLists.txt" >nul && (
        echo   %GREEN%✅%NC% CMake多架构配置
    ) || (
        echo   %RED%❌%NC% CMake多架构配置
    )
) else (
    echo   %RED%❌%NC% CMake多架构配置
)

REM 检查GitHub Actions工作流
if exist ".github\workflows\multi-arch-build.yml" (
    findstr /c:"Windows x64" ".github\workflows\multi-arch-build.yml" >nul && (
        echo   %GREEN%✅%NC% GitHub Actions多架构工作流
    ) || (
        echo   %RED%❌%NC% GitHub Actions多架构工作流
    )
) else (
    echo   %RED%❌%NC% GitHub Actions多架构工作流
)
echo.

REM 快速功能测试
echo %BLUE%▶ 快速功能测试%NC%
echo ───────────────────────────────────────────────────────────────────────────────

set "exe_found=0"
for %%f in (build\bin\YumeCard_*.exe build-*\bin\YumeCard_*.exe) do (
    if exist "%%f" (
        echo   %BLUE%ℹ️%NC%  找到可执行文件: %%f
        set "exe_found=1"
        
        REM 测试帮助命令
        "%%f" help >nul 2>&1
        if !errorlevel! equ 0 (
            echo   %GREEN%✅%NC% 帮助命令测试
        ) else (
            echo   %RED%❌%NC% 帮助命令测试
        )
        
        REM 测试系统信息命令
        "%%f" system-info >nul 2>&1
        if !errorlevel! equ 0 (
            echo   %GREEN%✅%NC% 系统信息命令测试
        ) else (
            echo   %RED%❌%NC% 系统信息命令测试
        )
        
        goto :test_done
    )
)

if !exe_found! equ 0 (
    echo   %YELLOW%⚠️%NC%  未找到可执行文件，跳过功能测试
    echo   %BLUE%ℹ️%NC%  请先运行构建命令生成可执行文件
)

:test_done
echo.

REM 多架构支持状态总结
echo %BLUE%▶ 多架构支持状态总结%NC%
echo ───────────────────────────────────────────────────────────────────────────────
echo ┌─────────────────────────────────────────────────────────────────────────────┐
echo │ 系统信息                                                                    │
echo ├─────────────────────────────────────────────────────────────────────────────┤
echo │ 平台: Windows
echo │ 架构: %PROCESSOR_ARCHITECTURE%
echo │ 检查时间: %date% %time%
echo └─────────────────────────────────────────────────────────────────────────────┘
echo.

echo 支持的架构矩阵:
echo ┌──────────┬─────┬─────┬───────┬───────┬──────┐
echo │ 平台     │ x64 │ x86 │ ARM64 │ ARM32 │ 其他 │
echo ├──────────┼─────┼─────┼───────┼───────┼──────┤
echo │ Windows  │ ✅  │ ✅  │ ✅    │ ✅    │ -    │
echo │ Linux    │ ✅  │ ✅  │ ✅    │ ✅    │ RISC │
echo │ macOS    │ ✅  │ ✅  │ ✅    │ -     │ -    │
echo │ FreeBSD  │ ✅  │ ✅  │ ✅    │ -     │ -    │
echo └──────────┴─────┴─────┴───────┴───────┴──────┘
echo.

echo 建议的后续步骤:
echo 1. 运行构建脚本测试多架构构建:
echo    - Windows: .\scripts\build_multi_arch.bat --test all
echo.
echo 2. 验证GitHub Actions工作流:
echo    - 提交代码到GitHub触发自动构建
echo    - 检查Actions页面的构建结果
echo.
echo 3. 测试交叉编译(如果支持):
echo    - Windows ARM64: .\scripts\build_multi_arch.bat arm64
echo.

echo %GREEN%✅ 多架构状态检查完成%NC%
echo.
echo 详细信息请查看: MULTI_ARCH_STATUS.md

goto :eof

:check_file
if exist "%~1" (
    echo   %GREEN%✅%NC% %~2
) else (
    echo   %RED%❌%NC% %~2
)
goto :eof

:check_command
%~1 --version >nul 2>&1
if !errorlevel! equ 0 (
    echo   %GREEN%✅%NC% %~2
) else (
    echo   %RED%❌%NC% %~2
)
goto :eof

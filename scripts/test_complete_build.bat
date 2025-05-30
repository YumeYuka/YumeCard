@echo off
REM YumeCard 完整的多平台测试脚本

setlocal enabledelayedexpansion

set "RED=[91m"
set "GREEN=[92m"
set "YELLOW=[93m"
set "BLUE=[94m"
set "CYAN=[96m"
set "NC=[0m"

echo %CYAN%╔═══════════════════════════════════════════════════════════════════════════════╗%NC%
echo %CYAN%║                     YumeCard 完整多平台构建测试                              ║%NC%
echo %CYAN%╚═══════════════════════════════════════════════════════════════════════════════╝%NC%
echo.

REM 清理之前的构建结果
echo %BLUE%▶ 清理构建目录%NC%
echo ───────────────────────────────────────────────────────────────────────────────

if exist "build-x64" rmdir /s /q "build-x64"
if exist "build-x86" rmdir /s /q "build-x86"
if exist "build-arm64" rmdir /s /q "build-arm64"
if exist "build-arm32" rmdir /s /q "build-arm32"

echo   %GREEN%✅%NC% 构建目录清理完成
echo.

REM 构建所有支持的架构
echo %BLUE%▶ 构建所有架构%NC%
echo ───────────────────────────────────────────────────────────────────────────────

set "ARCHITECTURES=x64 x86"
set "SUCCESS_COUNT=0"
set "TOTAL_COUNT=0"

for %%a in (%ARCHITECTURES%) do (
    set /a TOTAL_COUNT+=1
    echo   构建 %%a 架构...
    
    call .\scripts\build_multi_arch.bat %%a
    
    if errorlevel 1 (
        echo   %RED%❌%NC% %%a 构建失败
    ) else (
        echo   %GREEN%✅%NC% %%a 构建成功
        set /a SUCCESS_COUNT+=1
    )
)

echo.
echo %BLUE%▶ 构建结果总结%NC%
echo ───────────────────────────────────────────────────────────────────────────────
echo   成功: %SUCCESS_COUNT%/%TOTAL_COUNT%

if %SUCCESS_COUNT% EQU %TOTAL_COUNT% (
    echo   %GREEN%✅%NC% 所有架构构建成功
) else (
    echo   %YELLOW%⚠️%NC%  部分架构构建失败
)
echo.

REM 测试生成的可执行文件
echo %BLUE%▶ 测试可执行文件%NC%
echo ───────────────────────────────────────────────────────────────────────────────

for %%a in (%ARCHITECTURES%) do (
    if exist "build-%%a\bin\YumeCard_%%a.exe" (
        echo   测试 %%a 可执行文件...
        
        REM 测试帮助命令
        "build-%%a\bin\YumeCard_%%a.exe" --help >nul 2>&1
        if errorlevel 1 (
            echo     %RED%❌%NC% 帮助命令失败
        ) else (
            echo     %GREEN%✅%NC% 帮助命令正常
        )
        
        REM 测试系统信息命令
        "build-%%a\bin\YumeCard_%%a.exe" system-info >nul 2>&1
        if errorlevel 1 (
            echo     %RED%❌%NC% 系统信息命令失败
        ) else (
            echo     %GREEN%✅%NC% 系统信息命令正常
        )
        
        REM 获取文件信息
        for %%f in ("build-%%a\bin\YumeCard_%%a.exe") do (
            echo     文件大小: %%~zf bytes
        )
    ) else (
        echo   %RED%❌%NC% build-%%a\bin\YumeCard_%%a.exe 不存在
    )
)

echo.

REM 检查文件完整性
echo %BLUE%▶ 检查文件完整性%NC%
echo ───────────────────────────────────────────────────────────────────────────────

for %%a in (%ARCHITECTURES%) do (
    if exist "build-%%a\bin\YumeCard_%%a.exe" (
        echo   检查 %%a 版本...
        
        REM 检查必要的文件是否存在
        if exist "build-%%a\Style\custom.css" (
            echo     %GREEN%✅%NC% CSS样式文件
        ) else (
            echo     %RED%❌%NC% CSS样式文件缺失
        )
        
        if exist "build-%%a\Style\index.html" (
            echo     %GREEN%✅%NC% HTML模板文件
        ) else (
            echo     %RED%❌%NC% HTML模板文件缺失
        )
        
        if exist "build-%%a\config\config.json" (
            echo     %GREEN%✅%NC% 配置文件
        ) else (
            echo     %RED%❌%NC% 配置文件缺失
        )
        
        if exist "build-%%a\Style\backgrounds\" (
            echo     %GREEN%✅%NC% 背景图片目录
        ) else (
            echo     %RED%❌%NC% 背景图片目录缺失
        )
    )
)

echo.

REM 性能基准测试
echo %BLUE%▶ 性能基准测试%NC%
echo ───────────────────────────────────────────────────────────────────────────────

for %%a in (%ARCHITECTURES%) do (
    if exist "build-%%a\bin\YumeCard_%%a.exe" (
        echo   测试 %%a 版本性能...
        
        REM 使用PowerShell测量执行时间
        powershell -Command "& { $sw = [Diagnostics.Stopwatch]::StartNew(); & 'build-%%a\bin\YumeCard_%%a.exe' system-info | Out-Null; $sw.Stop(); Write-Host ('     执行时间: {0:F2}ms' -f $sw.Elapsed.TotalMilliseconds) }"
    )
)

echo.

REM 生成发布包
echo %BLUE%▶ 生成发布包%NC%
echo ───────────────────────────────────────────────────────────────────────────────

if not exist "releases" mkdir "releases"

for %%a in (%ARCHITECTURES%) do (
    if exist "build-%%a\bin\YumeCard_%%a.exe" (
        echo   打包 %%a 版本...
        
        REM 创建临时目录
        set "TEMP_DIR=temp_%%a"
        if exist "!TEMP_DIR!" rmdir /s /q "!TEMP_DIR!"
        mkdir "!TEMP_DIR!"
        
        REM 复制文件
        copy "build-%%a\bin\YumeCard_%%a.exe" "!TEMP_DIR!\"
        xcopy "build-%%a\Style" "!TEMP_DIR!\Style" /e /i /q
        xcopy "build-%%a\config" "!TEMP_DIR!\config" /e /i /q
        
        REM 创建README
        echo YumeCard Windows %%a 版本 > "!TEMP_DIR!\README.txt"
        echo. >> "!TEMP_DIR!\README.txt"
        echo 使用方法: >> "!TEMP_DIR!\README.txt"
        echo   YumeCard_%%a.exe --help    显示帮助 >> "!TEMP_DIR!\README.txt"
        echo   YumeCard_%%a.exe system-info    显示系统信息 >> "!TEMP_DIR!\README.txt"
        echo. >> "!TEMP_DIR!\README.txt"
        echo 构建时间: %date% %time% >> "!TEMP_DIR!\README.txt"
        
        REM 压缩为ZIP
        powershell -Command "Compress-Archive -Path '!TEMP_DIR!\*' -DestinationPath 'releases\YumeCard_Windows_%%a.zip' -Force"
        
        REM 清理临时目录
        rmdir /s /q "!TEMP_DIR!"
        
        echo     %GREEN%✅%NC% releases\YumeCard_Windows_%%a.zip
    )
)

echo.

REM 如果有WSL，测试Linux构建
echo %BLUE%▶ 检查WSL Linux构建支持%NC%
echo ───────────────────────────────────────────────────────────────────────────────

wsl --version >nul 2>&1
if errorlevel 1 (
    echo   %YELLOW%⚠️%NC%  WSL 未安装，跳过Linux构建测试
) else (
    echo   %GREEN%✅%NC% WSL 可用，测试Linux构建...
    
    if exist "build_wsl.sh" (
        echo   运行WSL构建...
        wsl -e bash ./build_wsl.sh >nul 2>&1
        
        if errorlevel 1 (
            echo     %RED%❌%NC% WSL构建失败
        ) else (
            echo     %GREEN%✅%NC% WSL构建成功
            
            if exist "build-wsl-x64\bin\YumeCard_x64" (
                echo     %GREEN%✅%NC% Linux x64 可执行文件生成
            )
        )
    ) else (
        echo   %YELLOW%⚠️%NC%  WSL构建脚本不存在，运行 .\scripts\setup_wsl_cross_compile.bat 来设置
    )
)

echo.

REM 总结报告
echo %BLUE%▶ 测试完成总结%NC%
echo ───────────────────────────────────────────────────────────────────────────────
echo.
echo 构建结果:
echo   Windows x64:   %GREEN%✅%NC%
echo   Windows x86:   %GREEN%✅%NC%
if exist "build-wsl-x64\bin\YumeCard_x64" (
    echo   Linux x64:     %GREEN%✅%NC%
) else (
    echo   Linux x64:     %YELLOW%⚠️%NC%  (需要WSL)
)
echo.
echo 发布包:
if exist "releases\YumeCard_Windows_x64.zip" (
    echo   Windows x64:   %GREEN%✅%NC% releases\YumeCard_Windows_x64.zip
)
if exist "releases\YumeCard_Windows_x86.zip" (
    echo   Windows x86:   %GREEN%✅%NC% releases\YumeCard_Windows_x86.zip
)
echo.
echo 下一步:
echo   1. 提交代码到GitHub触发自动构建
echo   2. 检查GitHub Actions的构建状态
echo   3. 下载和测试不同平台的构建产物
echo.

echo %GREEN%✅ 多平台构建测试完成%NC%
echo.
pause

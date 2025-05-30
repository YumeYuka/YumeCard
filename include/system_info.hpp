//
// Created by YumeYuka on 2025/5/30.
// 系统信息和平台检测工具
//
#pragma once

#include "head.hpp"
#include "platform_utils.hpp"

namespace Yume {
    class SystemInfoManager {
    private:
        std::map<std::string, std::string> m_systemInfo;

    public:
        SystemInfoManager() { collectSystemInfo(); }

        // 收集系统信息
        void collectSystemInfo() {
            m_systemInfo["OS"]               = SystemInfo::getOSName();
            m_systemInfo["Architecture"]     = SystemInfo::getArchitecture();
            m_systemInfo["64-bit"]           = SystemInfo::is64Bit() ? "Yes" : "No";
            m_systemInfo["Hardware Threads"] = std::to_string(ConcurrencyUtils::getHardwareConcurrency());

            // 编译时信息
            m_systemInfo["Compiler"]      = getCompilerInfo();
            m_systemInfo["Build Type"]    = getBuildType();
            m_systemInfo["CMake Version"] = getCMakeVersion();

            // 运行时环境
            m_systemInfo["Node.js Available"] = CommandUtils::commandExists("node") ? "Yes" : "No";
            m_systemInfo["vcpkg Root"]        = SystemInfo::getEnvironmentVariable("VCPKG_ROOT");
            if (m_systemInfo["vcpkg Root"].empty()) m_systemInfo["vcpkg Root"] = "Not Set";

            // 路径信息
            m_systemInfo["Executable Directory"] = PathUtils::getExecutableDir();
            m_systemInfo["Temp Directory"]       = FileSystemUtils::getTempDirectory();
        }

        // 打印系统信息
        void printSystemInfo() const {
            std::cout << "=== YumeCard System Information ===" << std::endl;
            std::cout << std::endl;

            // 按类别分组打印
            printCategory("Platform Information", {"OS", "Architecture", "64-bit", "Hardware Threads"});

            printCategory("Build Information", {"Compiler", "Build Type", "CMake Version"});

            printCategory("Environment", {"Node.js Available", "vcpkg Root"});

            printCategory("Paths", {"Executable Directory", "Temp Directory"});

            std::cout << "===================================" << std::endl;
        }

        // 获取特定信息
        std::string getInfo(std::string const& key) const {
            auto it = m_systemInfo.find(key);
            return it != m_systemInfo.end() ? it->second : "Unknown";
        }

        // 检查兼容性
        bool checkCompatibility() const {
            std::cout << "=== Compatibility Check ===" << std::endl;
            bool compatible = true;

            // 检查 Node.js
            if (!CommandUtils::commandExists("node")) {
                std::cout << "❌ Node.js not found - Screenshot functionality will not work" << std::endl;
                std::cout << "   Please install Node.js from https://nodejs.org/" << std::endl;
                compatible = false;
            } else {
                auto [exitCode, output] = CommandUtils::executeCommandWithOutput("node --version");
                if (exitCode == 0) std::cout << "✅ Node.js found: " << output << std::endl;
                else std::cout << "⚠️  Node.js found but version check failed" << std::endl;
            }

            // 检查关键目录
            std::vector<std::string> requiredDirs = {"./Style", "./config"};
            for (auto const& dir : requiredDirs) {
                if (FileSystemUtils::directoryExists(dir)) {
                    std::cout << "✅ Directory exists: " << dir << std::endl;
                } else {
                    std::cout << "⚠️  Directory missing: " << dir << " (will be created automatically)"
                              << std::endl;
                }
            }

            // 检查关键文件
            std::vector<std::string> requiredFiles = {"./Style/screenshot.js", "./Style/index.html",
                                                      "./Style/custom.css"};

            for (auto const& file : requiredFiles)
                if (FileSystemUtils::fileExists(file))
                    std::cout << "✅ File exists: " << file << std::endl;
                else std::cout << "⚠️  File missing: " << file << " (may cause issues)" << std::endl;

            std::cout << "=============================" << std::endl;
            return compatible;
        }

        // 生成诊断报告
        void generateDiagnosticReport(std::string const& outputPath = "./diagnostic_report.txt") const {
            std::ofstream report(outputPath);
            if (!report.is_open()) {
                std::cerr << "无法创建诊断报告文件: " << outputPath << std::endl;
                return;
            }

            report << "YumeCard Diagnostic Report" << std::endl;
            report << "Generated: " << getCurrentTimestamp() << std::endl;
            report << "========================================" << std::endl;
            report << std::endl;

            // 系统信息
            report << "[System Information]" << std::endl;
            for (auto const& [key, value] : m_systemInfo) report << key << ": " << value << std::endl;
            report << std::endl;

            // 环境变量
            report << "[Environment Variables]" << std::endl;
            std::vector<std::string> envVars = {"PATH",        "VCPKG_ROOT", "NODE_PATH", "HOME",
                                                "USERPROFILE", "TEMP",       "TMP",       "TMPDIR"};

            for (auto const& var : envVars) {
                std::string value = SystemInfo::getEnvironmentVariable(var);
                report << var << "=" << (value.empty() ? "(not set)" : value) << std::endl;
            }
            report << std::endl;

            // 平台特定的诊断信息
            report << "[Platform Diagnostics]" << std::endl;
            addPlatformDiagnostics(report);

            report.close();
            std::cout << "诊断报告已生成: " << outputPath << std::endl;
        }

    private:
        void printCategory(std::string const& title, std::vector<std::string> const& keys) const {
            std::cout << "[" << title << "]" << std::endl;
            for (auto const& key : keys) {
                auto it = m_systemInfo.find(key);
                if (it != m_systemInfo.end()) std::cout << "  " << key << ": " << it->second << std::endl;
            }
            std::cout << std::endl;
        }

        std::string getCompilerInfo() const {
#ifdef _MSC_VER
            return "MSVC " + std::to_string(_MSC_VER);
#elif defined(__GNUC__)
            return "GCC " + std::to_string(__GNUC__) + "." + std::to_string(__GNUC_MINOR__);
#elif defined(__clang__)
            return "Clang " + std::to_string(__clang_major__) + "." + std::to_string(__clang_minor__);
#else
            return "Unknown";
#endif
        }

        std::string getBuildType() const {
#ifdef NDEBUG
            return "Release";
#else
            return "Debug";
#endif
        }

        std::string getCMakeVersion() const {
#ifdef CMAKE_VERSION
            return CMAKE_VERSION;
#else
            return "Unknown";
#endif
        }

        std::string getCurrentTimestamp() const {
            auto              now    = std::chrono::system_clock::now();
            auto              time_t = std::chrono::system_clock::to_time_t(now);
            std::stringstream ss;
            ss << std::put_time(std::localtime(&time_t), "%Y-%m-%d %H:%M:%S");
            return ss.str();
        }

        void addPlatformDiagnostics(std::ofstream& report) const {
#ifdef YUMECARD_PLATFORM_WINDOWS
            report << "Platform: Windows" << std::endl;

            // Windows特定的诊断
            char  computerName[256];
            DWORD size = sizeof(computerName);
            if (GetComputerNameA(computerName, &size))
                report << "Computer Name: " << computerName << std::endl;

            SYSTEM_INFO sysInfo;
            GetSystemInfo(&sysInfo);
            report << "Number of Processors: " << sysInfo.dwNumberOfProcessors << std::endl;
            report << "Page Size: " << sysInfo.dwPageSize << std::endl;

#elif defined(YUMECARD_PLATFORM_LINUX)
            report << "Platform: Linux" << std::endl;

            // Linux特定的诊断
            struct utsname unameData;
            if (uname(&unameData) == 0) {
                report << "Kernel: " << unameData.sysname << " " << unameData.release << std::endl;
                report << "Hostname: " << unameData.nodename << std::endl;
                report << "Machine: " << unameData.machine << std::endl;
            }

#elif defined(YUMECARD_PLATFORM_MACOS)
            report << "Platform: macOS" << std::endl;

            // macOS特定的诊断
            struct utsname unameData;
            if (uname(&unameData) == 0) {
                report << "Darwin Version: " << unameData.release << std::endl;
                report << "Hostname: " << unameData.nodename << std::endl;
                report << "Machine: " << unameData.machine << std::endl;
            }
#else
            report << "Platform: Unknown" << std::endl;
#endif
        }
    };
}

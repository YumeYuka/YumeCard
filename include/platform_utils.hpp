//
// Created by YumeYuka on 2025/5/30.
// 平台相关的工具类
//
#pragma once

#include "head.hpp"

// 平台特定的常量定义
#ifdef YUMECARD_PLATFORM_WINDOWS
    #ifndef MAX_PATH
        #define MAX_PATH 260
    #endif
    #ifndef PATH_MAX
        #define PATH_MAX MAX_PATH
    #endif
#else
    #ifndef PATH_MAX
        #define PATH_MAX 4096
    #endif
#endif

namespace Yume {
    // 路径工具类
    class PathUtils {
    public:
        // 连接路径
        std::string static joinPath(std::string const& path1, std::string const& path2) {
            if (path1.empty()) return path2;
            if (path2.empty()) return path1;

#ifdef YUMECARD_PLATFORM_WINDOWS
            char separator = '\\';
            // 同时支持正斜杠和反斜杠
            if (path1.back() == '/' || path1.back() == '\\') return path1 + path2;
#else
            char separator = '/';
            if (path1.back() == '/') return path1 + path2;
#endif
            return path1 + separator + path2;
        }

        // 规范化路径
        std::string static normalizePath(std::string const& path) {
            std::string normalized = path;
#ifdef YUMECARD_PLATFORM_WINDOWS
            // 将正斜杠转换为反斜杠
            for (char& c : normalized)
                if (c == '/') c = '\\';
#endif
            return normalized;
        }

        // 获取可执行文件目录
        std::string static getExecutableDir() {
#ifdef YUMECARD_PLATFORM_WINDOWS
            char buffer[MAX_PATH];
            GetModuleFileNameA(nullptr, buffer, MAX_PATH);
            std::string execPath(buffer);
            size_t      pos = execPath.find_last_of("\\/");
            return execPath.substr(0, pos);
#else
            char    buffer[PATH_MAX];
            ssize_t count = readlink("/proc/self/exe", buffer, PATH_MAX);
            if (count != -1) {
                std::string execPath(buffer, count);
                size_t      pos = execPath.find_last_of('/');
                return execPath.substr(0, pos);
            }
            return "./";
#endif
        }
    };

    // 文件系统工具类
    class FileSystemUtils {
    public:
        // 检查文件是否存在
        bool static fileExists(std::string const& path) {
            return std::filesystem::exists(path) && std::filesystem::is_regular_file(path);
        }

        // 检查目录是否存在
        bool static directoryExists(std::string const& path) {
            return std::filesystem::exists(path) && std::filesystem::is_directory(path);
        }

        // 创建目录（递归）
        bool static createDirectories(std::string const& path) {
            try {
                return std::filesystem::create_directories(path);
            } catch (std::exception const&) { return false; }
        }

        // 复制文件
        bool static copyFile(std::string const& source, std::string const& destination) {
            try {
                std::filesystem::copy_file(source, destination,
                                           std::filesystem::copy_options::overwrite_existing);
                return true;
            } catch (std::exception const&) { return false; }
        } // 获取文件大小
        size_t static getFileSize(std::string const& path) {
            try {
                return static_cast<size_t>(std::filesystem::file_size(path));
            } catch (std::exception const&) { return 0; }
        }

        // 获取临时目录
        std::string static getTempDirectory() {
#ifdef YUMECARD_PLATFORM_WINDOWS
            char tempPath[MAX_PATH];
            GetTempPathA(MAX_PATH, tempPath);
            return std::string(tempPath);
#else
            const char* tmpDir = getenv("TMPDIR");
            if (tmpDir) return std::string(tmpDir);
            tmpDir = getenv("TMP");
            if (tmpDir) return std::string(tmpDir);
            tmpDir = getenv("TEMP");
            if (tmpDir) return std::string(tmpDir);
            return "/tmp/";
#endif
        }
    };

    // 命令执行工具类
    class CommandUtils {
    public:
        // 构建Node.js命令
        std::string static buildNodeCommand(std::string const&              scriptPath,
                                            std::vector<std::string> const& args) {
            std::string nodeCmd = getNodeExecutable();
            std::string command = nodeCmd + " \"" + scriptPath + "\"";

            for (auto const& arg : args) command += " \"" + escapeArgument(arg) + "\"";

            return command;
        }

        // 执行命令
        int static executeCommand(std::string const& command) {
#ifdef YUMECARD_PLATFORM_WINDOWS
            return _wsystem(std::wstring(command.begin(), command.end()).c_str());
#else
            return system(command.c_str());
#endif
        }

        // 获取Node.js可执行文件路径
        std::string static getNodeExecutable() {
#ifdef YUMECARD_PLATFORM_WINDOWS
            // 首先尝试 node.exe
            if (commandExists("node.exe")) return "node.exe";
            if (commandExists("node")) return "node";

            // 尝试常见的安装路径
            std::vector<std::string> possiblePaths = {"C:\\Program Files\\nodejs\\node.exe",
                                                      "C:\\Program Files (x86)\\nodejs\\node.exe",
                                                      "C:\\nodejs\\node.exe"};

            for (auto const& path : possiblePaths)
                if (FileSystemUtils::fileExists(path)) return "\"" + path + "\"";

            return "node"; // 回退到默认
#else
            return "node";
#endif
        }

        // 检查命令是否存在
        bool static commandExists(std::string const& command) {
#ifdef YUMECARD_PLATFORM_WINDOWS
            std::string testCmd = "where " + command + " >nul 2>&1";
            return executeCommand(testCmd) == 0;
#else
            std::string testCmd = "which " + command + " >/dev/null 2>&1";
            return executeCommand(testCmd) == 0;
#endif
        }

        // 转义命令行参数
        std::string static escapeArgument(std::string const& arg) {
            std::string escaped = arg;
#ifdef YUMECARD_PLATFORM_WINDOWS
            // 在Windows上，转义双引号
            for (size_t pos = 0; pos < escaped.length(); ++pos) {
                if (escaped[pos] == '"') {
                    escaped.insert(pos, "\\");
                    pos += 2; // 跳过插入的反斜杠和原始的双引号
                }
            }
#else
            // 在Unix系统上，转义特殊字符
            for (size_t pos = 0; pos < escaped.length(); ++pos) {
                if (escaped[pos] == '"' || escaped[pos] == '\'' || escaped[pos] == '\\') {
                    escaped.insert(pos, "\\");
                    pos += 2;
                }
            }
#endif
            return escaped;
        }

        // 执行命令并获取输出
        std::pair<int, std::string> static executeCommandWithOutput(std::string const& command) {
            std::string result;
            int         exitCode = 0;

#ifdef YUMECARD_PLATFORM_WINDOWS
            HANDLE              hRead, hWrite;
            SECURITY_ATTRIBUTES sa;
            sa.nLength              = sizeof(SECURITY_ATTRIBUTES);
            sa.lpSecurityDescriptor = nullptr;
            sa.bInheritHandle       = TRUE;

            if (CreatePipe(&hRead, &hWrite, &sa, 0)) {
                STARTUPINFO         si;
                PROCESS_INFORMATION pi;
                ZeroMemory(&si, sizeof(si));
                si.cb         = sizeof(si);
                si.hStdOutput = hWrite;
                si.hStdError  = hWrite;
                si.dwFlags |= STARTF_USESTDHANDLES;

                // 使用多字节字符串而不是宽字符串
                std::string mutableCommand = command;
                if (CreateProcessA(nullptr, &mutableCommand[0], nullptr, nullptr, TRUE, 0, nullptr,
                                   nullptr, &si, &pi)) {
                    CloseHandle(hWrite);

                    char  buffer[4096];
                    DWORD bytesRead;
                    while (ReadFile(hRead, buffer, sizeof(buffer), &bytesRead, nullptr) && bytesRead > 0)
                        result.append(buffer, bytesRead);

                    WaitForSingleObject(pi.hProcess, INFINITE);
                    DWORD code;
                    GetExitCodeProcess(pi.hProcess, &code);
                    exitCode = static_cast<int>(code);

                    CloseHandle(pi.hProcess);
                    CloseHandle(pi.hThread);
                } else {
                    CloseHandle(hWrite);
                    exitCode = -1;
                }
                CloseHandle(hRead);
            }
#else
            FILE* pipe = popen((command + " 2>&1").c_str(), "r");
            if (pipe) {
                char buffer[4096];
                while (fgets(buffer, sizeof(buffer), pipe) != nullptr) result += buffer;
                exitCode = pclose(pipe);
            } else {
                exitCode = -1;
            }
#endif
            return {exitCode, result};
        }
    };

    // 系统信息工具类
    class SystemInfo {
    public:
        // 获取操作系统名称
        std::string static getOSName() {
#ifdef YUMECARD_PLATFORM_WINDOWS
    #ifdef YUMECARD_PLATFORM_WIN64
            return "Windows x64";
    #else
            return "Windows x86";
    #endif
#elif defined(YUMECARD_PLATFORM_LINUX)
    #ifdef YUMECARD_PLATFORM_LINUX_X64
            return "Linux x64";
    #elif defined(YUMECARD_PLATFORM_LINUX_ARM64)
            return "Linux ARM64";
    #elif defined(YUMECARD_PLATFORM_LINUX_ARM32)
            return "Linux ARM32";
    #else
            return "Linux";
    #endif
#elif defined(YUMECARD_PLATFORM_MACOS)
    #ifdef YUMECARD_PLATFORM_MACOS_ARM64
            return "macOS ARM64";
    #elif defined(YUMECARD_PLATFORM_MACOS_X64)
            return "macOS x64";
    #else
            return "macOS";
    #endif
#else
            return "Unknown";
#endif
        }

        // 获取架构信息
        std::string static getArchitecture() {
#if defined(YUMECARD_PLATFORM_WIN64) || defined(YUMECARD_PLATFORM_LINUX_X64) \
    || defined(YUMECARD_PLATFORM_MACOS_X64)
            return "x64";
#elif defined(YUMECARD_PLATFORM_WIN32)
            return "x86";
#elif defined(YUMECARD_PLATFORM_LINUX_ARM64) || defined(YUMECARD_PLATFORM_MACOS_ARM64)
            return "ARM64";
#elif defined(YUMECARD_PLATFORM_LINUX_ARM32)
            return "ARM32";
#else
            return "Unknown";
#endif
        }

        // 检查是否为64位系统
        bool static is64Bit() { return sizeof(void*) == 8; }

        // 获取环境变量
        std::string static getEnvironmentVariable(std::string const& name) {
            char const* value = std::getenv(name.c_str());
            return value ? std::string(value) : std::string();
        }

        // 设置环境变量
        bool static setEnvironmentVariable(std::string const& name, std::string const& value) {
#ifdef YUMECARD_PLATFORM_WINDOWS
            return SetEnvironmentVariableA(name.c_str(), value.c_str()) != 0;
#else
            return setenv(name.c_str(), value.c_str(), 1) == 0;
#endif
        }
    };

    // 线程和并发工具类
    class ConcurrencyUtils {
    public:
        // 获取硬件并发数
        unsigned int static getHardwareConcurrency() {
            unsigned int cores = std::thread::hardware_concurrency();
            return cores > 0 ? cores : 1;
        }

        // 睡眠指定毫秒数
        void static sleepMilliseconds(unsigned int milliseconds) {
            std::this_thread::sleep_for(std::chrono::milliseconds(milliseconds));
        }

        // 睡眠指定秒数
        void static sleepSeconds(unsigned int seconds) {
            std::this_thread::sleep_for(std::chrono::seconds(seconds));
        }
    };
}

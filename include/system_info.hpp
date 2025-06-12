#pragma once

#include <algorithm> // For std::transform
#include <iostream>
#include <string>
#include <vector>

#include "head.hpp"
#include "version.hpp" // For version information

// Forward declaration if needed, or include the actual header
// #include "platform_utils.hpp" // If CommandUtils is used here for checks

namespace Yume {

    class SystemInfoManager {
    public:
        SystemInfoManager() = default;

        void displaySystemInfo() const {
            std::cout << "--------------------------------------" << std::endl;
            std::cout << "YumeCard System Information" << std::endl;
            std::cout << "--------------------------------------" << std::endl;
            // Reverting to yumecard::version namespace as originally in main.cpp
            std::cout << "YumeCard Version: " << yumecard::version::string << std::endl;
            std::cout << "Build Date: " << yumecard::version::build_date << std::endl;
            std::cout << "Build Commit: " << yumecard::version::build_commit << std::endl;
            std::cout << "Target Platform: " << yumecard::version::target_platform << std::endl;
            std::cout << "Target Architecture: " << yumecard::version::target_arch << std::endl;
            std::cout << "Compiler: " << yumecard::version::compiler << " "
                      << yumecard::version::compiler_version << std::endl;
            std::cout << "--------------------------------------" << std::endl;

            // Basic OS Info (Illustrative - requires platform-specific code for real details)
#ifdef _WIN32
            std::cout << "Operating System: Windows (or MinGW)" << std::endl;
#elif __linux__
            std::cout << "Operating System: Linux" << std::endl;
#elif __APPLE__
            std::cout << "Operating System: macOS" << std::endl;
#else
            std::cout << "Operating System: Unknown" << std::endl;
#endif

            // Placeholder for dependency checks
            std::cout << "Dependency Checks:" << std::endl;
            checkNodeJs();
            // Add more checks as needed (e.g., for curl, git)
            std::cout << "--------------------------------------" << std::endl;
        }

        bool checkNodeJs() const {
            std::cout << "  Checking for Node.js: ";
            // This is a placeholder. Actual check would involve CommandUtils::executeCommand("node
            // --version") and parsing the output or checking the return code. For now, we'll assume it's
            // present if the screenshot functionality is to work. A more robust check is needed for a
            // real application. int result = CommandUtils::executeCommand("node --version > nul 2>&1");
            // // Windows specific to suppress output For cross-platform, redirect to /dev/null or use a
            // library that captures output. if (result == 0) {
            //    std::cout << "Found." << std::endl;
            //    return true;
            // } else {
            //    std::cout << "Not found or error during check." << std::endl;
            //    return false;
            // }
            std::cout << "(Placeholder - Assuming Present)" << std::endl;
            return true; // Placeholder
        }

        // Add other check methods here, e.g.:
        // bool checkCurl() const;
        // bool checkGit() const;

        void generateDiagnosticReport(std::string const& outputPath) const {
            std::ofstream reportFile(outputPath);
            if (!reportFile.is_open()) {
                std::cerr << "Error: Could not open diagnostic report file: " << outputPath << std::endl;
                return;
            }

            reportFile << "YumeCard Diagnostic Report" << std::endl;
            reportFile << "=========================" << std::endl;
            reportFile << "Timestamp: " << getCurrentTimestamp() << std::endl;
            reportFile << std::endl;

            reportFile << "System Information:" << std::endl;
            reportFile << "  YumeCard Version: " << yumecard::version::string << std::endl;
            reportFile << "  Build Date: " << yumecard::version::build_date << std::endl;
            // ... (add all version fields)
#ifdef _WIN32
            reportFile << "  OS: Windows" << std::endl;
#elif __linux__
            reportFile << "  OS: Linux" << std::endl;
#elif __APPLE__
            reportFile << "  OS: macOS" << std::endl;
#else
            reportFile << "  OS: Unknown" << std::endl;
#endif
            reportFile << std::endl;

            reportFile << "Dependency Checks:" << std::endl;
            reportFile << "  Node.js: " << (checkNodeJs() ? "Found" : "Not Found/Error")
                       << " (Placeholder)" << std::endl;
            // ... (add other dependency check results)
            reportFile << std::endl;

            // Placeholder for configuration dump
            reportFile << "Configuration (Placeholder - actual config data would go here):" << std::endl;
            reportFile << "  Config Directory: ./config (example)" << std::endl;
            reportFile << "  Style Directory: ./Style (example)" << std::endl;
            reportFile << std::endl;

            // Placeholder for recent logs (if logging is implemented)
            reportFile << "Recent Logs (Placeholder):" << std::endl;
            reportFile << "  No logging implemented yet." << std::endl;
            reportFile << std::endl;

            reportFile << "=========================" << std::endl;
            reportFile << "End of Report" << std::endl;

            reportFile.close();
            std::cout << "Diagnostic report generated: " << outputPath << std::endl;
        }

    private:
        std::string getCurrentTimestamp() const {
            auto              now       = std::chrono::system_clock::now();
            auto              in_time_t = std::chrono::system_clock::to_time_t(now);
            std::tm           tm_buf;
#if defined(_WIN32) || defined(_WIN64)
            localtime_s(&tm_buf, &in_time_t);
#else
            localtime_r(&in_time_t, &tm_buf);
#endif
            std::stringstream ss;
            ss << std::put_time(&tm_buf, "%Y-%m-%d %X");
            return ss.str();
        }
    };

} // namespace Yume

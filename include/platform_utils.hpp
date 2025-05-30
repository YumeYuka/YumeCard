#pragma once

#include <array>   // For popen buffer if needed later
#include <cstdio>  // For popen, pclose if needed later
#include <cstdlib> // For std::system
#include <sstream> // For buildNodeCommand

#include "head.hpp" // Should include <string>, <vector>, <filesystem>, <iostream> etc.

namespace Yume {

    class PathUtils {
    public:
        std::string static joinPath(std::string const& p1, std::string const& p2) {
            std::filesystem::path path1(p1);
            std::filesystem::path path2(p2);
            return (path1 / path2).string();
        }
    };

    class FileSystemUtils {
    public:
        bool static fileExists(std::string const& filePath) { return std::filesystem::exists(filePath); }

        bool static copyFile(std::string const& sourcePath, std::string const& destinationPath) {
            try {
                // Overwrite if exists, as per typical copy behavior
                std::filesystem::copy_file(sourcePath, destinationPath,
                                           std::filesystem::copy_options::overwrite_existing);
                return true;
            } catch (std::filesystem::filesystem_error const& e) {
                std::cerr << "FileSystemUtils::copyFile error: " << e.what() << std::endl;
                return false;
            }
        }
    };

    class CommandUtils {
    public:
        std::string static buildNodeCommand(std::string const&              scriptPath,
                                            std::vector<std::string> const& args) {
            std::ostringstream command_stream;
            command_stream << "node \"" << scriptPath << "\""; // Enclose scriptPath in quotes
            for (auto const& arg : args)
                command_stream << " \"" << arg << "\""; // Enclose each argument in quotes
            return command_stream.str();
        }

        // Basic command execution, returns exit code.
        // For more complex needs (capturing output, etc.), this would need to be expanded.
        int static executeCommand(std::string const& command) {
            // On Windows, std::system might open a new window for GUI applications.
            // For console applications like node, it should be fine.
            // For cross-platform robustness, especially with paths containing spaces,
            // more advanced process creation APIs might be needed (e.g., CreateProcess on Windows,
            // fork/exec on POSIX).
            int result = std::system(command.c_str());
            // std::system returns a system-dependent value. On POSIX, WEXITSTATUS(result) gives the exit
            // code. On Windows, it directly returns the exit code of the command. For simplicity, we're
            // assuming it returns the exit code directly or 0 for success. A result of -1 often indicates
            // failure to execute the command itself.
            return result;
        }
    };

} // namespace Yume

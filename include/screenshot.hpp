//
// Created by YumeYuka on 2025/5/30.
//

#pragma once

#include "head.hpp"

#pragma once

#include "head.hpp"
#include "platform_utils.hpp"

namespace Yume {
    // 用于管理截图功能的类
    class ScreenshotManager {
    private:
        std::string m_style_dir;

    public:
        ScreenshotManager(std::string style_dir = "./Style"): m_style_dir(std::move(style_dir)) {}
        ~ScreenshotManager() = default;

        // 使用screenshot.js对HTML文件进行截图
        bool takeScreenshot(std::string const& htmlPath, std::string const& outputPath,
                            int quality = 100) {
            // 获取绝对路径
            std::string absHtmlPath   = std::filesystem::absolute(htmlPath).string();
            std::string absOutputPath = std::filesystem::absolute(outputPath).string();

            // 确保截图脚本存在于style目录
            std::string scriptPath      = getScriptPath();
            std::string debugScriptPath = PathUtils::joinPath(m_style_dir, "screenshot.js");

            // 如果文件不同，则复制更新后的截图脚本
            if (FileSystemUtils::fileExists(scriptPath)
                && (!FileSystemUtils::fileExists(debugScriptPath)
                    || std::filesystem::last_write_time(scriptPath)
                           > std::filesystem::last_write_time(debugScriptPath))) {
                if (!FileSystemUtils::copyFile(scriptPath, debugScriptPath)) {
                    std::cerr << "复制截图脚本失败" << std::endl;
                    return false;
                }
                std::cout << "更新了截图脚本: " << debugScriptPath << std::endl;
            }

            // 构建跨平台的Node.js命令
            std::vector<std::string> args = {absHtmlPath, absOutputPath, std::to_string(quality)};

            std::string command = CommandUtils::buildNodeCommand(debugScriptPath, args);

            // 执行命令
            std::cout << "执行截图命令: " << command << std::endl;
            int result = CommandUtils::executeCommand(command);

            // 检查命令执行结果
            if (result == 0) {
                std::cout << "截图成功！已保存到: " << outputPath << std::endl;
                return true;
            } else {
                std::cerr << "截图命令执行失败，返回代码: " << result << std::endl;
                return false;
            }
        }

        // 生成HTML模板
        bool generateTemplate(std::string const&                        templatePath,
                              std::map<std::string, std::string> const& variables,
                              std::string const&                        outputPath) {
            // 读取模板文件
            std::ifstream templateFile(templatePath);
            if (!templateFile.is_open()) {
                std::cerr << "无法打开模板文件: " << templatePath << std::endl;
                return false;
            }

            std::stringstream buffer;
            buffer << templateFile.rdbuf();
            std::string content = buffer.str();
            templateFile.close();

            // 替变量
            for (auto const& [key, value] : variables)
                content = replaceAll(content, "{{" + key + "}}", value);

            // 处理循环标签
            content = processLoops(content);

            // 处理条件标签
            content = processConditions(content);

            // 保存生成的HTML
            std::ofstream outputFile(outputPath);
            if (!outputFile.is_open()) {
                std::cerr << "无法写入输出文件: " << outputPath << std::endl;
                return false;
            }

            outputFile << content;
            outputFile.close();

            std::cout << "成功生成HTML文件: " << outputPath << std::endl;
            return true;
        } // 获取随机背景图片
        std::string getRandomBackground(std::string const& backgroundDir = "") {
            std::string actualBackgroundDir =
                backgroundDir.empty() ? (m_style_dir + "/backgrounds") : backgroundDir;

            std::vector<std::string> imageFiles;

            // 检查目录是否存在
            if (!std::filesystem::exists(actualBackgroundDir)
                || !std::filesystem::is_directory(actualBackgroundDir)) {
                std::cerr << "背景图片目录不存在: " << actualBackgroundDir << std::endl;
                return "";
            }

            // 查找所有图片文件
            for (auto const& entry : std::filesystem::directory_iterator(actualBackgroundDir)) {
                if (entry.is_regular_file()) {
                    std::string extension = entry.path().extension().string();
                    std::transform(extension.begin(), extension.end(), extension.begin(), ::tolower);

                    if (extension == ".jpg" || extension == ".jpeg" || extension == ".png"
                        || extension == ".gif") {
                        imageFiles.push_back(entry.path().string());
                    }
                }
            }

            // 如果没有找到图片文件
            if (imageFiles.empty()) {
                std::cerr << "在背景目录中没有找到图片文件: " << actualBackgroundDir << std::endl;
                return "";
            }

            // 随机选择一张图片
            std::random_device              rd;
            std::mt19937                    gen(rd());
            std::uniform_int_distribution<> dis(0, static_cast<int>(imageFiles.size()) - 1);

            return imageFiles[dis(gen)];
        }

        // 计算图标的CSS位置
        std::pair<int, int> calculateIconPosition(int index, int totalIcons, int containerWidth,
                                                  int containerHeight) { // 计算图标在网格中的位置
            int columns = static_cast<int>(std::ceil(std::sqrt(totalIcons)));
            int rows    = static_cast<int>(std::ceil(static_cast<double>(totalIcons) / columns));

            // 计算每个图标的大小
            int iconWidth  = containerWidth / columns;
            int iconHeight = containerHeight / rows;

            // 计算图标的行和列
            int col = index % columns;
            int row = index / columns;

            // 计算图标的中心位置
            int x = col * iconWidth + iconWidth / 2;
            int y = row * iconHeight + iconHeight / 2;

            return {x, y};
        }

    private:
        // 获取screenshot.js脚本路径
        std::string getScriptPath() const { return m_style_dir + "/screenshot.js"; }

        // 替换字符串中的所有匹配项
        std::string replaceAll(std::string str, std::string const& from, std::string const& to) const {
            size_t start_pos = 0;
            while ((start_pos = str.find(from, start_pos)) != std::string::npos) {
                str.replace(start_pos, from.length(), to);
                start_pos += to.length();
            }
            return str;
        }

        // 处理循环标签 {{#each items}} ... {{/each}}
        std::string processLoops(std::string const& content) const {
            std::string result = content;
            // MSVC might not support std::regex::dotall directly or it behaves differently.
            // For now, as this is a placeholder, we remove the flag.
            // If complex multiline matching is needed, pattern needs adjustment e.g. using [\\s\\S]
            std::regex  loopPattern(R"(\{\{#each\s+([^\}]+)\}\}([\s\S]*?)\{\{\/each\}\})");
            std::smatch matches;

            // 这里仅为示例，实际处理循环标签需要更复杂的逻辑
            // 在实际应用中，您需要从数据结构中获取循环项，并为每个项生成内容

            return result;
        }

        // 处理条件标签 {{#if condition}} ... {{/if}}
        std::string processConditions(std::string const& content) const {
            std::string result = content;
            // MSVC might not support std::regex::dotall directly.
            // As this is a placeholder, we remove the flag.
            std::regex ifPattern(
                R"(\{\{#if\s+([^\}]+)\}\}([\s\S]*?)(?:\{\{else\}\}([\s\S]*?))?\{\{\/if\}\})");
            std::smatch matches;

            // 这里仅为示例，实际处理条件标签需要更复杂的逻辑
            // 在实际应用中，您需要评估条件并选择相应的内容

            return result;
        }
    };
}

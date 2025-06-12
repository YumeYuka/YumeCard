//
// Created by YumeYuka on 2025/5/30.
//

#pragma once

#include "github_api.hpp"
#include "head.hpp"
#include "read_config.hpp"
#include "screenshot.hpp"
#include "set_config.hpp"

namespace Yume {
    class GitHubSubscriber {
    public:
        // 使用map存储commit信息，key为sha，value为包含其他commit信息的vector
        // vector elements: 0:date, 1:author, 2:repo_from_url, 3:html_url, 4:message, 5:avatar_url
        using CommitMap = std::map<std::string, std::vector<std::string>>;

        explicit GitHubSubscriber(std::string config_path = "./config/config.json",
                                  std::string style_dir = "./Style", std::string output_dir = "./Style"):
            m_config_path(std::move(config_path)),
            m_style_dir(std::move(style_dir)),
            m_output_dir(std::move(output_dir)),
            m_readConfig(m_config_path),
            m_githubAPI(m_readConfig.getToken(), m_config_path) {
            if (!m_githubAPI.initialize()) std::cerr << "GitHub API初始化失败！" << std::endl;
        }

        ~GitHubSubscriber() = default;

        // 添加新仓库并立即获取最新commit
        bool addRepository(std::string const& owner, std::string const& repo,
                           std::string const& branch = "main") {
            nlohmann::json config_json;
            std::ifstream  config_in(m_config_path);
            if (config_in.is_open()) {
                config_in >> config_json;
                config_in.close();
            } else {
                std::cerr << "无法打开配置文件: " << m_config_path << std::endl;
                return false;
            }

            Set_config setConfig(config_json, m_config_path);
            setConfig.addRepository(owner, repo, branch);

            // 然后获取该仓库的最新commit
            nlohmann::json commits_json = m_githubAPI.getCommits(owner, repo, 1); // Renamed
            if (commits_json.empty() || !commits_json.is_array()
                || commits_json.size() == 0) { // Added size check
                std::cerr << "获取仓库 " << owner << "/" << repo << " 的commit失败或没有commits！"
                          << std::endl;
                // Still add the repo, but without a sha, or handle as an error?
                // For now, let's assume an error if no commits are found to set an initial sha.
                return false;
            }

            // 获取最新commit的SHA并更新配置文件
            std::string latestSha = commits_json[0]["sha"].get<std::string>();
            setConfig.setLastSha(owner, repo, latestSha);

            std::cout << "成功添加仓库 " << owner << "/" << repo << " 并获取最新commit SHA: " << latestSha
                      << std::endl;
            return true;
        }

        // 检查仓库更新
        CommitMap checkRepositoryUpdates(std::string const& owner, std::string const& repo,
                                         int limit = 10) {
            CommitMap newCommits;

            // 获取仓库当前记录的SHA
            std::string lastSha       = m_readConfig.getLastSha(owner, repo);
            std::string currentBranch = m_readConfig.getBranch(owner, repo);
            if (currentBranch.empty()) currentBranch = "main"; // Default if not found

            // 获取仓库最新的commits
            // GitHubAPI::getCommits 只接受3个参数 (owner, repo, limit)
            // 暂时不支持指定分支，总是获取默认分支的提交
            nlohmann::json commits_json = m_githubAPI.getCommits(owner, repo, limit);
            if (commits_json.empty() || !commits_json.is_array()) {
                std::cerr << "获取仓库 " << owner << "/" << repo << " 的commit失败！" << std::endl;
                return newCommits;
            }

            // 解析commit信息并创建commit map
            CommitMap commitMap = parseCommits(commits_json);

            if (lastSha.empty()) {
                if (!commitMap.empty()) {
                    auto latestCommit =
                        commitMap.begin(); // map is ordered by SHA (string comparison, not time)
                                           // For "latest", we'd typically want the first from API
                                           // response if it's time-sorted The parseCommits populates in
                                           // API order, so begin() is the newest from the fetched batch
                    std::string latestShaToStore = latestCommit->first;
                    updateLastSha(owner, repo, latestShaToStore);
                    // Pass correct number of arguments to generateCommitScreenshot
                    generateCommitScreenshot(owner, repo, currentBranch,
                                             m_readConfig.getDescription(owner, repo), "", commitMap);
                }
                return commitMap; // Return all fetched if no previous SHA
            }

            bool      foundLastSha = false;
            CommitMap tempCommitsInApiOrder; // To preserve API order for selecting "new" ones

            // Iterate in the order received from API (which parseCommits preserves if jsonArray is
            // ordered) nlohmann::json keeps insertion order for objects if they are added like that.
            // std::map sorts by key. So commitMap is sorted by SHA.
            // We need to compare against `lastSha` using the API's order of commits (usually newest
            // first).

            std::vector<std::pair<std::string, std::vector<std::string>>> apiOrderedCommits;
            for (auto const& commitJson : commits_json) {
                std::string sha = commitJson["sha"].get<std::string>();
                if (commitMap.count(sha)) // Ensure it was parsed correctly
                    apiOrderedCommits.push_back({sha, commitMap.at(sha)});
            }

            for (auto const& pair : apiOrderedCommits) {
                std::string const&              sha  = pair.first;
                std::vector<std::string> const& info = pair.second;
                if (sha == lastSha) {
                    foundLastSha = true;
                    break;
                }
                newCommits[sha] = info; // Add to newCommits, will be in SHA-sorted order
            }

            if (!foundLastSha)          // lastSha not in the latest 'limit' commits
                newCommits = commitMap; // return all 'limit' commits

            if (!newCommits.empty()) {
                std::string latestShaToStore = apiOrderedCommits.front().first;
                updateLastSha(owner, repo, latestShaToStore);
                // Pass correct number of arguments to generateCommitScreenshot
                generateCommitScreenshot(owner, repo, currentBranch,
                                         m_readConfig.getDescription(owner, repo), "", newCommits);
            }

            return newCommits;
        }

        // 定期检查所有仓库更新
        void startPeriodicCheck(unsigned int intervalMinutes = 10) {
            bool running = true;

            while (running) { // Basic loop, consider gRunning for graceful shutdown
                ReadConfig currentReadConfig(m_config_path); // Re-read config inside loop
                auto       repositories = currentReadConfig.getAllRepositories();

                for (auto const& repo_json : repositories) { // Renamed repo to repo_json
                    std::string owner    = repo_json["owner"].get<std::string>();
                    std::string repoName = repo_json["repo"].get<std::string>();
                    // std::string branch = repo_json.contains("branch") ?
                    // repo_json["branch"].get<std::string>() : "main"; std::string description =
                    // repo_json.contains("description") ? repo_json["description"].get<std::string>() :
                    // ""; std::string lastUpdate = repo_json.contains("lastsha_date") ?
                    // repo_json["lastsha_date"].get<std::string>() : "";

                    std::cout << "检查仓库 " << owner << "/" << repoName << " 的更新..." << std::endl;
                    CommitMap newCommitsMap = checkRepositoryUpdates(owner, repoName); // Renamed

                    if (newCommitsMap.empty()) {
                        std::cout << "仓库 " << owner << "/" << repoName << " 没有新的commits。"
                                  << std::endl;
                    } else {
                        std::cout << "仓库 " << owner << "/" << repoName << " 有 " << newCommitsMap.size()
                                  << " 个新的commits：" << std::endl;
                        printCommits(newCommitsMap);
                        // Screenshot generation is now handled within checkRepositoryUpdates
                    }
                }

                std::cout << "等待 " << intervalMinutes << " 分钟后再次检查..." << std::endl;
                std::this_thread::sleep_for(std::chrono::minutes(intervalMinutes));
            }
        }

        // 获取特定SHA的commit信息
        std::vector<std::string> getCommitInfoBySha(CommitMap const&   commitMap,
                                                    std::string const& sha) const {
            auto it = commitMap.find(sha);
            if (it != commitMap.end()) return it->second;
            return {};
        }

        // 获取所有SHA
        std::vector<std::string> getAllShas(CommitMap const& commitMap) const {
            std::vector<std::string> shas;
            shas.reserve(commitMap.size());
            for (auto const& pair : commitMap) shas.push_back(pair.first);
            return shas;
        }

        // 打印commits信息 - made public static
        void static printCommits(CommitMap const& commitMap) {
            for (auto const& [sha, info] : commitMap) {
                std::cout << "SHA: " << sha << std::endl;
                std::cout << "日期: " << info[0] << std::endl;
                std::cout << "作者: " << info[1] << std::endl;
                std::cout << "仓库: " << info[2] << std::endl;
                std::cout << "链接: " << info[3] << std::endl;
                std::cout << "消息: " << info[4].substr(0, 50) << (info[4].length() > 50 ? "..." : "")
                          << std::endl;
                if (info.size() > 5 && !info[5].empty()) std::cout << "头像: " << info[5] << std::endl;
                std::cout << "----------------------------" << std::endl;
            }
        }

        // 测试截图生成功能
        bool testScreenshot() {
            CommitMap testCommits;
            testCommits["abcdef1234567890"] = {
                "2025-05-30T12:00:00Z",
                "TestAuthor1",
                "TestOwner/TestRepo",
                "https://github.com/TestOwner/TestRepo/commit/abcdef1234567890",
                "这是第一个测试提交: 新增炫酷功能!",
                "https://avatars.githubusercontent.com/u/1?v=4" // Example Avatar
            };
            testCommits["fedcba0987654321"] = {
                "2025-05-29T10:30:00Z",
                "TestAuthor2",
                "TestOwner/TestRepo",
                "https://github.com/TestOwner/TestRepo/commit/fedcba0987654321",
                "这是第二个测试提交: 修复了一个重要的BUG。",
                "https://avatars.githubusercontent.com/u/2?v=4" // Example Avatar
            };
            testCommits["12345fedcba09876"] = {
                "2025-05-28T08:15:00Z",
                "TestAuthor1",
                "TestOwner/TestRepo",
                "https://github.com/TestOwner/TestRepo/commit/12345fedcba09876",
                "这是第三个测试提交: 文档更新和一些小的重构。",
                "https://avatars.githubusercontent.com/u/1?v=4"};
            std::cout << "正在测试截图生成功能..." << std::endl;
            // Provide dummy values for branch, description, lastUpdate for testing
            generateCommitScreenshot("TestOwner", "TestRepo", "main",
                                     "这是一个用于测试截图功能的示例仓库描述。", "2025-05-30",
                                     testCommits);
            std::cout << "测试截图生成完成！请检查 " << m_output_dir << "/TestOwner_TestRepo.png 文件。"
                      << std::endl;
            return true;
        }

    private:
        std::string m_config_path;
        std::string m_style_dir;
        std::string m_output_dir;
        ReadConfig  m_readConfig;
        GitHubAPI   m_githubAPI;

        // 从commit JSON数组解析commit信息
        CommitMap parseCommits(nlohmann::json const& jsonArray) const {
            CommitMap commitMap;
            if (!jsonArray.is_array()) return commitMap;

            for (auto const& commitJson : jsonArray) {
                if (!commitJson.is_object()) continue; // Skip non-object items

                std::string sha  = commitJson.value("sha", "N/A");
                std::string date = "N/A";
                if (commitJson.contains("commit") && commitJson["commit"].is_object()
                    && commitJson["commit"].contains("committer")
                    && commitJson["commit"]["committer"].is_object()
                    && commitJson["commit"]["committer"].contains("date")) {
                    date = commitJson["commit"]["committer"].value("date", "N/A");
                }

                std::string authorLogin = "N/A";
                std::string avatarUrl   = ""; // Default to empty
                if (commitJson.contains("author") && commitJson["author"].is_object()) {
                    authorLogin = commitJson["author"].value("login", "N/A");
                    avatarUrl   = commitJson["author"].value("avatar_url", "");
                }

                std::string htmlUrl     = commitJson.value("html_url", "");
                std::string repoFromUrl = extractRepoFromUrl(htmlUrl);

                std::string message = "N/A";
                if (commitJson.contains("commit") && commitJson["commit"].is_object())
                    message = commitJson["commit"].value("message", "N/A");

                commitMap[sha] = {date, authorLogin, repoFromUrl, htmlUrl, message, avatarUrl};
            }
            return commitMap;
        }

        // 从URL中提取仓库名
        std::string extractRepoFromUrl(std::string const& url) const {
            std::string owner_local; // Renamed
            std::string repo_local;  // Renamed

            size_t start = url.find("github.com/");
            if (start != std::string::npos) {
                start += 11;

                size_t ownerEnd = url.find("/", start);
                if (ownerEnd != std::string::npos) {
                    owner_local = url.substr(start, ownerEnd - start);

                    size_t repoStart = ownerEnd + 1;
                    size_t repoEnd   = url.find("/", repoStart);
                    if (repoEnd != std::string::npos)
                        repo_local = url.substr(repoStart, repoEnd - repoStart);
                }
            }

            if (!owner_local.empty() && !repo_local.empty()) return owner_local + "/" + repo_local;
            return "";
        }

        // 更新配置文件中的lastsha
        void updateLastSha(std::string const& owner, std::string const& repo, std::string const& sha) {
            nlohmann::json config_json; // Renamed
            std::ifstream  config_in(m_config_path);
            if (config_in.is_open()) {
                config_in >> config_json;
                config_in.close();

                Set_config setConfig(config_json, m_config_path);
                setConfig.setLastSha(owner, repo, sha);

                std::cout << "已更新仓库 " << owner << "/" << repo << " 的最新SHA: " << sha << std::endl;
            } else {
                std::cerr << "无法打开配置文件进行SHA更新: " << m_config_path << std::endl;
            }
        }

        // 替换字符串中的所有匹配项 (helper)
        std::string replaceAll(std::string str, std::string const& from, std::string const& to) const {
            size_t start_pos = 0;
            while ((start_pos = str.find(from, start_pos)) != std::string::npos) {
                str.replace(start_pos, from.length(), to);
                start_pos += to.length(); // Move past the last replaced segment to avoid infinite loops
                                          // if 'to' contains 'from'
            }
            return str;
        }

        // 生成成commit信息的HTML模板并截图
        void generateCommitScreenshot(std::string const& owner, std::string const& repo,
                                      std::string const& branch, std::string const& description,
                                      std::string const& lastUpdate, CommitMap const& commits) {
            std::map<std::string, std::string> variables;
            variables["title"]       = owner + "/" + repo + " GitHub 更新";
            variables["owner"]       = owner;
            variables["repo"]        = repo;
            variables["commitCount"] = std::to_string(commits.size());
            variables["branch"]      = branch;

            auto              now     = std::chrono::system_clock::now();
            auto              nowTime = std::chrono::system_clock::to_time_t(now);
            std::tm          tm_buf;
            localtime_s(&tm_buf, &nowTime);
            std::stringstream dateStream;
            dateStream << std::put_time(&tm_buf, "%Y-%m-%d %H:%M:%S");
            variables["currentDate"] = dateStream.str();
            ScreenshotManager screenshotManager(
                m_style_dir); // Instance of ScreenshotManager with custom style dir            //
                              // 根据配置决定是否使用随机背景图片
            if (m_readConfig.getBackgroundsEnabled()) {
                std::string bgPath = screenshotManager.getRandomBackground(m_style_dir + "/backgrounds");
                if (!bgPath.empty()) {
                    // screenshot.js needs a URL-friendly path, relative to the HTML file or absolute.
                    // Let's make it relative to Style/ if backgrounds is inside Style/
                    std::filesystem::path p = bgPath;
                    variables["backgroundImage"] =
                        "backgrounds/"
                        + p.filename().string(); // Create relative path to backgrounds folder
                } else {
                    variables["backgroundImage"] = ""; // 不使用背景图片
                }
            } else {
                // 如果配置中禁用了背景，不使用背景图片
                variables["backgroundImage"] = "";
            }

            variables["description_html_content"] =
                description.empty() ? "" : "<div class=\"repo-desc\">" + description + "</div>";
            variables["last_update_html_content"] =
                lastUpdate.empty() ? "" : "<div class=\"stat-item\">最后更新: " + lastUpdate + "</div>";

            std::string commitsHtml_content;                  // Renamed
            for (auto const& [sha_key, info_vec] : commits) { // Renamed
                std::string commit_message      = info_vec.size() > 4 ? info_vec[4] : "N/A";
                std::string commit_sha_short    = sha_key.substr(0, 7);
                std::string commit_author_login = info_vec.size() > 1 ? info_vec[1] : "N/A";
                std::string commit_date         = info_vec.size() > 0 ? info_vec[0] : "N/A";
                std::string commit_html_url     = info_vec.size() > 3 ? info_vec[3] : "#";
                std::string commit_avatar_url   = info_vec.size() > 5 ? info_vec[5] : "";

                std::string avatar_html;
                if (!commit_avatar_url.empty()) {
                    avatar_html = "<img src=\"" + commit_avatar_url + "\" alt=\"" + commit_author_login
                                + "\" class=\"author-avatar\">";
                }

                commitsHtml_content +=
                    "<li class=\"commit-item\">" "<div class=\"commit-message\">" + commit_message
                    + "</div>" "<div class=\"commit-details\">" "<span class=\"commit-sha\">"
                    + commit_sha_short + "</span>" "<span class=\"commit-author\">" + avatar_html
                    + "<span>" + commit_author_login + "</span></span>" "<span class=\"commit-date\">"
                    + commit_date
                    + "</span>" "</div>"
                      // 移除了"在GitHub上查看"链接元素
                      "</li>";
            }
            variables["commits_list_html"] = commitsHtml_content;

            // 根据commits数量添加适当的CSS类
            std::string commitListClass = "";
            if (commits.size() <= 2) commitListClass = "few-commits";
            else if (commits.size() >= 6) commitListClass = "many-commits";
            variables["commit_list_class"] = commitListClass;
            std::string templateHtmlPath   = m_style_dir + "/index.html";
            std::string renderedHtmlPath   = m_style_dir + "/rendered.html";

            // 使用仓库名称构建输出文件名
            std::string filename = owner + "_" + repo;
            // 替换文件名中的特殊字符
            std::replace(filename.begin(), filename.end(), '/', '_');

            // 使用指定的输出目录
            std::string screenshotImagePath = m_output_dir + "/" + filename + ".png";

            // 确保输出目录存在
            if (!std::filesystem::exists(m_output_dir)) {
                try {
                    std::filesystem::create_directories(m_output_dir);
                    std::cout << "已创建输出目录: " << m_output_dir << std::endl;
                } catch (std::exception const& e) {
                    std::cerr << "创建输出目录失败: " << e.what() << std::endl;
                }
            }

            if (screenshotManager.generateTemplate(templateHtmlPath, variables, renderedHtmlPath)) {
                if (screenshotManager.takeScreenshot(renderedHtmlPath, screenshotImagePath)) {
                    std::cout << "成功生成仓库 " << owner << "/" << repo
                              << " 的更新截图: " << screenshotImagePath << std::endl;
                } else {
                    std::cerr << "生成截图失败！" << std::endl;
                }
            } else {
                std::cerr << "生成HTML文件失败！" << std::endl;
            }
        }
    };
}

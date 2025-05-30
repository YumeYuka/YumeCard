//
// Created by YumeYuka on 2025/5/30.
//

#pragma once

#include "head.hpp"

namespace Yume {

    // 回调函数用于接收curl的响应数据
    size_t static WriteCallback(void* contents, size_t size, size_t nmemb, std::string* s) {
        size_t newLength = size * nmemb;
        try {
            s->append((char*)contents, newLength);
            return newLength;
        } catch (std::bad_alloc&) { return 0; }
    }

    // GitHub API 封装类
    class GitHubAPI {
    public:
        // Make m_config public or add a getter if it needs to be accessed from main.cpp
        // For now, making it public for simplicity, though a getter is usually preferred.
        nlohmann::json m_config;

        explicit GitHubAPI(std::string token = "", std::string config_path = "./config/config.json"):
            m_curl(nullptr),
            // m_token(std::move(token)), // m_token will be loaded from config or set via setter
            m_initialized(false),
            m_res(CURLE_OK),
            m_config_path(std::move(config_path)) {
            loadConfig(); // Load config on initialization
            if (m_config.contains("GitHub") && m_config["GitHub"].contains("token")) {
                m_token = m_config["GitHub"]["token"].get<std::string>();
            } else if (!token.empty()) {
                m_token = std::move(token); // Use provided token if not in config
                                            // Optionally, save this token to config here if desired
            }
        }

        ~GitHubAPI() { cleanup(); }

        // Add a getter for the config if m_config is to remain private
        // const nlohmann::json& getConfig() const { return m_config; }

        // 初始化CURL
        bool initialize() {
            if (m_initialized) return true;

            curl_global_init(CURL_GLOBAL_DEFAULT);
            m_curl = curl_easy_init();

            if (!m_curl) {
                std::cerr << "Curl initialization failed!" << std::endl;
                return false;
            }

            m_initialized = true;
            return true;
        }

        // 关闭资源
        void cleanup() {
            if (m_curl) {
                curl_easy_cleanup(m_curl);
                m_curl = nullptr;
            }
            curl_global_cleanup();
            m_initialized = false;
        }

        // 获取仓库最新提交
        nlohmann::json getCommits(std::string const& user, std::string const& repo, int limit = 10) {
            std::string url = "https://api.github.com/repos/" + user + "/" + repo + "/commits";
            url += "?per_page=" + std::to_string(limit);
            return performGetRequest(url);
        }

        // 获取仓库最新Issue
        nlohmann::json getIssues(std::string const& user, std::string const& repo, int limit = 10) {
            std::string url = "https://api.github.com/repos/" + user + "/" + repo + "/issues";
            url += "?per_page=" + std::to_string(limit) + "&state=all"; // 获取所有状态的Issue
            return performGetRequest(url);
        }

        // 获取仓库最新Release
        nlohmann::json getReleases(std::string const& user, std::string const& repo, int limit = 10) {
            std::string url = "https://api.github.com/repos/" + user + "/" + repo + "/releases";
            url += "?per_page=" + std::to_string(limit);
            return performGetRequest(url);
        }

        // 获取仓库最新PR
        nlohmann::json getPullRequests(std::string const& user, std::string const& repo, int limit = 10) {
            std::string url = "https://api.github.com/repos/" + user + "/" + repo + "/pulls";
            url += "?per_page=" + std::to_string(limit) + "&state=all";
            return performGetRequest(url);
        }

        // 获取仓库推送事件
        nlohmann::json getEvents(std::string const& user, std::string const& repo, int limit = 30) {
            std::string url = "https://api.github.com/repos/" + user + "/" + repo + "/events";
            url += "?per_page=" + std::to_string(limit);
            return performGetRequest(url);
        }

    private:
        CURL*       m_curl;
        std::string m_token;
        bool        m_initialized;
        CURLcode    m_res;
        std::string m_config_path;
        // nlohmann::json m_config; // Moved to public for now

        // Helper function to perform GET requests
        nlohmann::json performGetRequest(std::string const& url) {
            if (!m_initialized && !initialize()) {
                std::cerr << "CURL not initialized for performGetRequest" << std::endl;
                return nlohmann::json::object(); // Return empty JSON object on error
            }

            std::string        readBuffer;
            struct curl_slist* headers = nullptr;
            headers = curl_slist_append(headers, "Accept: application/vnd.github.v3+json");
            headers = curl_slist_append(headers, "User-Agent: YumeCard-App"); // Set a User-Agent
            if (!m_token.empty()) {
                std::string authHeader = "Authorization: token " + m_token;
                headers                = curl_slist_append(headers, authHeader.c_str());
            }

            curl_easy_setopt(m_curl, CURLOPT_URL, url.c_str());
            curl_easy_setopt(m_curl, CURLOPT_HTTPHEADER, headers);
            curl_easy_setopt(m_curl, CURLOPT_WRITEFUNCTION,
                             Yume::WriteCallback); // Ensure Yume::WriteCallback is accessible
            curl_easy_setopt(m_curl, CURLOPT_WRITEDATA, &readBuffer);
            curl_easy_setopt(m_curl, CURLOPT_TIMEOUT, 15L);       // 15 seconds timeout
            curl_easy_setopt(m_curl, CURLOPT_SSL_VERIFYPEER, 1L); // Verify SSL peer
            curl_easy_setopt(m_curl, CURLOPT_SSL_VERIFYHOST, 2L); // Verify SSL host
            // curl_easy_setopt(m_curl, CURLOPT_VERBOSE, 1L); // Uncomment for debugging CURL requests

            m_res = curl_easy_perform(m_curl);
            curl_slist_free_all(headers);

            if (m_res != CURLE_OK) {
                std::cerr << "curl_easy_perform() failed: " << curl_easy_strerror(m_res) << std::endl;
                return nlohmann::json::object();
            }

            long http_code = 0;
            curl_easy_getinfo(m_curl, CURLINFO_RESPONSE_CODE, &http_code);
            if (http_code >= 400) {
                std::cerr << "HTTP error " << http_code << " for URL: " << url << std::endl;
                std::cerr << "Response: " << readBuffer << std::endl;
                return nlohmann::json::object(); // Or a JSON object with an error field
            }

            try {
                if (readBuffer.empty()) {
                    std::cerr << "Empty response from server for URL: " << url << std::endl;
                    return nlohmann::json::object(); // Return empty JSON if response is empty
                }
                return nlohmann::json::parse(readBuffer);
            } catch (nlohmann::json::parse_error& e) {
                std::cerr << "JSON parse error: " << e.what() << "\nResponse was: " << readBuffer
                          << std::endl;
                return nlohmann::json::object(); // Return empty JSON object on parse error
            }
        }

        // Load config from file
        void loadConfig() {
            std::ifstream configFile(m_config_path);
            if (configFile.is_open()) {
                try {
                    configFile >> m_config;
                } catch (nlohmann::json::parse_error const& e) {
                    std::cerr << "Error parsing config file: " << m_config_path << " - " << e.what()
                              << std::endl;
                    // Initialize with default structure if parse fails
                    m_config                         = nlohmann::json::object();
                    m_config["GitHub"]               = nlohmann::json::object();
                    m_config["GitHub"]["repository"] = nlohmann::json::array();
                }
                configFile.close();
            } else {
                std::cerr << "Config file not found, creating default: " << m_config_path << std::endl;
                // Initialize with default structure if file not found
                m_config                         = nlohmann::json::object();
                m_config["GitHub"]               = nlohmann::json::object();
                m_config["GitHub"]["repository"] = nlohmann::json::array();
                // saveConfig(); // Optionally save the new default config
            }
        }

        // Save config to file (optional, if changes are made internally)
        void saveConfig() {
            std::ofstream configFile(m_config_path);
            if (configFile.is_open()) {
                configFile << m_config.dump(4); // Pretty print with 4 spaces
                configFile.close();
            } else {
                std::cerr << "Error: Could not open config file for writing: " << m_config_path
                          << std::endl;
            }
        }
    };

} // namespace yume

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
        explicit GitHubAPI(std::string token = "", std::string m_config_path = "./config/config.json"):
            m_curl(nullptr),
            m_token(std::move(token)),
            m_initialized(false),
            m_res(CURLE_OK),
            m_config_path(m_config_path) {}

        ~GitHubAPI() { cleanup(); }

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

        // 执行GET请求
        nlohmann::json performGetRequest(std::string const& url) {
            if (!m_initialized) {
                if (!initialize()) return nlohmann::json::object();
            }

            curl_easy_reset(m_curl);

            // 设置URL
            curl_easy_setopt(m_curl, CURLOPT_URL, url.c_str());

            // 设置回调函数
            std::string response_string;
            curl_easy_setopt(m_curl, CURLOPT_WRITEFUNCTION, WriteCallback);
            curl_easy_setopt(m_curl, CURLOPT_WRITEDATA, &response_string);

            // 设置超时选项
            curl_easy_setopt(m_curl, CURLOPT_TIMEOUT, 30L);        // 整体超时时间设为30秒
            curl_easy_setopt(m_curl, CURLOPT_CONNECTTIMEOUT, 10L); // 连接超时设为10秒

            // 如果需要，可以启用重定向跟随
            curl_easy_setopt(m_curl, CURLOPT_FOLLOWLOCATION, 1L);
            curl_easy_setopt(m_curl, CURLOPT_MAXREDIRS, 5L); // 最多允许5次重定向

            // 设置HTTP头，包括Accept和用户代理
            struct curl_slist* headers = nullptr;
            headers = curl_slist_append(headers, "Accept: application/vnd.github.v3+json");
            headers = curl_slist_append(headers, "User-Agent: YumeCard/1.0");

            // 如果有token，添加授权头
            if (!m_token.empty()) {
                std::string auth_header = "Authorization: token " + m_token;
                headers                 = curl_slist_append(headers, auth_header.c_str());
            }

            curl_easy_setopt(m_curl, CURLOPT_HTTPHEADER, headers);

            // 执行请求
            m_res = curl_easy_perform(m_curl);

            // 清理头部
            curl_slist_free_all(headers);

            // 处理响应
            if (m_res != CURLE_OK) {
                std::cerr << "curl_easy_perform() failed: " << curl_easy_strerror(m_res) << std::endl;
                if (m_res == CURLE_OPERATION_TIMEDOUT)
                    std::cerr << "连接超时，请检查网络连接或者考虑增加超时设置。" << std::endl;
                return nlohmann::json::object();
            }

            // 检查HTTP状态码
            long http_code = 0;
            curl_easy_getinfo(m_curl, CURLINFO_RESPONSE_CODE, &http_code);

            if (http_code >= 400) {
                std::cerr << "HTTP error code: " << http_code << std::endl;
                std::cerr << "Response: " << response_string << std::endl;
                return nlohmann::json::object();
            }

            // 解析JSON
            try {
                return nlohmann::json::parse(response_string);
            } catch (nlohmann::json::parse_error const& e) {
                std::cerr << "JSON parse error: " << e.what() << std::endl;
                return nlohmann::json::object();
            }
        }
    };

} // namespace yume

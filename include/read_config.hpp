//
// Created by YumeYuka on 2025/5/30.
//
#pragma once

#include <head.hpp>

namespace Yume {
    class ReadConfig {
    public:
        explicit ReadConfig(std::string config_path): m_config_path(std::move(config_path)) {
            std::ifstream config_in(m_config_path);
            if (config_in.is_open()) {
                config_in >> m_config;
                config_in.close();
            } else {
                std::cerr << "无法打开配置文件: " << m_config_path << std::endl;
            }
        }

        ~ReadConfig() = default;

        [[nodiscard]] std::string getToken() const {
            if (m_config.contains("GitHub") && m_config["GitHub"].contains("token"))
                return m_config["GitHub"]["token"].get<std::string>();
            return "";
        }

        [[nodiscard]] std::vector<std::string> getRepository() const {
            std::vector<std::string> result;
            auto                     repository = m_config["GitHub"]["repository"];
            for (auto const& repos : repository) {
                std::string owner = repos["owner"].get<std::string>();
                std::string repo  = repos["repo"].get<std::string>();
                result.emplace_back(std::move(owner) + "/" + std::move(repo));
            }
            return result;
        }

        // 获取特定仓库的最后一次提交SHA
        [[nodiscard]] std::string getLastSha(std::string const& owner, std::string const& repo) const {
            if (m_config.contains("GitHub") && m_config["GitHub"].contains("repository")) {
                auto repository = m_config["GitHub"]["repository"];
                for (auto const& repos : repository) {
                    if (repos["owner"].get<std::string>() == owner
                        && repos["repo"].get<std::string>() == repo) {
                        if (repos.contains("lastsha")) return repos["lastsha"].get<std::string>();
                        break;
                    }
                }
            }
            return "";
        }

        // 获取所有仓库的详细信息
        [[nodiscard]] std::vector<nlohmann::json> getAllRepositories() const {
            std::vector<nlohmann::json> result;
            if (m_config.contains("GitHub") && m_config["GitHub"].contains("repository")) {
                auto repository = m_config["GitHub"]["repository"];
                for (auto const& repos : repository) result.push_back(repos);
            }
            return result;
        }

        // 获取特定仓库的分支 (占位符实现)
        [[nodiscard]] std::string getBranch(std::string const& owner, std::string const& repo) const {
            if (m_config.contains("GitHub") && m_config["GitHub"].contains("repository")) {
                for (auto const& r : m_config["GitHub"]["repository"])
                    if (r.value("owner", "") == owner && r.value("repo", "") == repo)
                        return r.value("branch", "main"); // Default to main if not specified
            }
            return "main"; // Default if repo not found
        } // 获取特定仓库的描述 (占位符实现)
        [[nodiscard]] std::string getDescription(std::string const& owner,
                                                 std::string const& repo) const {
            // Placeholder: In a real scenario, you might fetch this from config or elsewhere
            // For now, returning an empty string or a generic description.
            if (m_config.contains("GitHub") && m_config["GitHub"].contains("repository")) {
                for (auto const& r : m_config["GitHub"]["repository"])
                    if (r.value("owner", "") == owner && r.value("repo", "") == repo)
                        return r.value("description", ""); // Assuming description might be in config
            }
            return "";
        } // 获取背景图片配置
        [[nodiscard]] bool getBackgroundsEnabled() const {
            if (m_config.contains("GitHub") && m_config["GitHub"].contains("backgrounds")) {
                auto backgroundsValue = m_config["GitHub"]["backgrounds"];
                if (backgroundsValue.is_string()) {
                    std::string value = backgroundsValue.get<std::string>();
                    return value == "true";
                } else if (backgroundsValue.is_boolean()) {
                    return backgroundsValue.get<bool>();
                }
            }
            return false; // 默认不启用背景图片
        }

    private:
        std::string    m_config_path = "./config/config.json";
        nlohmann::json m_config;
    };
}

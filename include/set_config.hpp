#pragma once

#include <head.hpp>

namespace Yume {
    class Set_config {
    public:
        Set_config(nlohmann::json const& config, std::string config_path = "./config/config.json"):
            m_config(config), m_config_path(std::move(config_path)) {
            writeConfigToFile();
        }

        ~Set_config() = default;

        void setToken(std::string const& token) {
            if (token.empty()) return;
            m_config["GitHub"]["token"] = token;
            writeConfigToFile();
        }

        void setLastSha(const std::string& owner, const std::string& repo, const std::string& sha) {
            if (sha.empty()) return;

            bool found = false;
            if (m_config.contains("GitHub") && m_config["GitHub"].contains("repository")) {
                auto& repository = m_config["GitHub"]["repository"];
                for (auto& repos : repository) {
                    if (repos["owner"].get<std::string>() == owner &&
                        repos["repo"].get<std::string>() == repo) {
                        repos["lastsha"] = sha;
                        found = true;
                        break;
                    }
                }
            }

            if (found) {
                writeConfigToFile();
            }
        }

        // 添加新的仓库
        void addRepository(const std::string& owner, const std::string& repo, const std::string& branch = "main") {
            if (owner.empty() || repo.empty()) return;

            bool exists = false;
            if (m_config.contains("GitHub") && m_config["GitHub"].contains("repository")) {
                auto& repository = m_config["GitHub"]["repository"];
                for (auto& repos : repository) {
                    if (repos["owner"].get<std::string>() == owner &&
                        repos["repo"].get<std::string>() == repo) {
                        exists = true;
                        break;
                    }
                }

                if (!exists) {
                    nlohmann::json newRepo = {
                        {"owner", owner},
                        {"repo", repo},
                        {"branch", branch},
                        {"lastsha", ""}
                    };
                    repository.push_back(newRepo);
                    writeConfigToFile();
                }
            }
        }

    private:
        void openConfigFile(std::ofstream& config_file) const {
            config_file.open(m_config_path, std::ios::trunc);
        }

        void writeConfigToFile() const {
            std::ofstream config_file;
            openConfigFile(config_file);
            if (config_file.is_open()) {
                config_file << m_config.dump(4);
                config_file.close();
            } else {
                std::cerr << "无法打开配置文件进行写入。" << std::endl;
            }
        }

    private:
        std::string    m_config_path = "./config/config.json";
        nlohmann::json m_config;
    };
};


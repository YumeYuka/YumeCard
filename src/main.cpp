#include "github_api.hpp"
#include "github_subscriber.hpp"
#include "head.hpp"
#include "read_config.hpp" // Added for listRepositories
#include "set_config.hpp"
#include "system_info.hpp" // Ensure system_info.hpp is included for Yume::SystemInfoManager
#include "version.hpp"     // 包含版本信息

// 函数声明
void printVersion();
void printHelp();

// 全局变量，用于处理程序终止信号
sig_atomic_t volatile gRunning = 1;

// 配置信息结构体
struct AppConfig {
    std::string configDir = "./config";
    std::string styleDir  = "./Style";
    std::string outputDir = "./Style";

    std::string getConfigPath() const { return configDir + "/config.json"; }
};

// 信号处理函数
void signalHandler(int signal) {
    std::cout << "接收到信号 " << signal << "，准备终止程序..." << std::endl;
    gRunning = 0;
}

// 解析命令行参数
std::pair<AppConfig, std::vector<std::string>> parseArguments(int argc, char* argv[]) {
    AppConfig                config;
    std::vector<std::string> remainingArgs;

    for (int i = 1; i < argc; ++i) {
        std::string arg = argv[i];

        if (arg == "--config" && i + 1 < argc) config.configDir = argv[++i];
        else if (arg == "--style" && i + 1 < argc) config.styleDir = argv[++i];
        else if (arg == "--output" && i + 1 < argc) config.outputDir = argv[++i];
        else if (arg == "--version") {
            printVersion();
            exit(0);
        } else if (arg == "--help") {
            printHelp();
            exit(0);
        } else remainingArgs.push_back(arg);
    }

    return {config, remainingArgs};
}

// 显示版本信息
void printVersion() {
    std::cout << "YumeCard GitHub 订阅工具" << std::endl;
    std::cout << "版本: " << yumecard::version::string << std::endl;
    std::cout << "构建时间: " << yumecard::version::build_date << std::endl;
    std::cout << "Git Commit: " << yumecard::version::build_commit << std::endl;
    std::cout << "目标平台: " << yumecard::version::target_platform << " ("
              << yumecard::version::target_arch << ")" << std::endl;
    std::cout << "编译器: " << yumecard::version::compiler << " " << yumecard::version::compiler_version
              << std::endl;
    std::cout << std::endl;
    std::cout << "完整版本信息: " << yumecard::version::full_string() << std::endl;
}

void printHelp() {
    std::cout << "YumeCard GitHub 订阅工具 v" << yumecard::version::string << " - 使用帮助" << std::endl;
    std::cout << "--------------------------------------" << std::endl;
    std::cout << "用法: YumeCard [选项] <命令> [参数...]" << std::endl;
    std::cout << std::endl;
    std::cout << "全局选项:" << std::endl;
    std::cout << "  --config <路径>              - 指定配置文件目录 (默认: ./config)" << std::endl;
    std::cout << "  --style <路径>               - 指定样式文件目录 (默认: ./Style)" << std::endl;
    std::cout << "  --output <路径>              - 指定输出图像目录 (默认: ./Style)" << std::endl;
    std::cout << "  --version                    - 显示版本信息" << std::endl;
    std::cout << "  --help                       - 显示此帮助信息" << std::endl;
    std::cout << std::endl;
    std::cout << "可用命令:" << std::endl;
    std::cout << "  add <owner> <repo> [branch]  - 添加新的GitHub仓库订阅" << std::endl;
    std::cout << "  check <owner> <repo>         - 检查特定仓库的更新" << std::endl;
    std::cout << "  monitor [interval]           - 开始监控所有仓库 (默认每10分钟)" << std::endl;
    std::cout << "  set-token <token>            - 设置GitHub API访问令牌" << std::endl;
    std::cout << "  list                         - 列出所有已订阅的仓库" << std::endl;
    std::cout << "  test-screenshot              - 测试截图生成功能" << std::endl;
    std::cout << "  system-info                  - 显示系统信息和兼容性检查" << std::endl;
    std::cout << "  diagnostic                   - 生成诊断报告" << std::endl;
    std::cout << "  version                      - 显示版本信息" << std::endl;
    std::cout << "  help                         - 显示此帮助信息" << std::endl;
    std::cout << std::endl;
    std::cout << "示例:" << std::endl;
    std::cout << "  YumeCard add YumeYuka YumeCard main" << std::endl;
    std::cout << "  YumeCard --config ./myconfig check YumeYuka YumeCard" << std::endl;
    std::cout << "  YumeCard --style ./mystyle --output ./images monitor 30" << std::endl;
    std::cout << "  YumeCard set-token ghp_xxxxxxxxxxxx" << std::endl;
    std::cout << "  YumeCard --config ./config --style ./themes test-screenshot" << std::endl;
    std::cout << "  YumeCard --version" << std::endl;
    std::cout << "--------------------------------------" << std::endl;
}

// 设置GitHub API令牌
bool setGitHubToken(std::string const& configPath, std::string const& token) {
    if (token.empty()) {
        std::cerr << "错误: 令牌不能为空!" << std::endl;
        return false;
    }

    // 读取配置文件
    nlohmann::json config;
    std::ifstream  config_in(configPath);
    if (config_in.is_open()) {
        config_in >> config;
        config_in.close();
    } else {
        std::cerr << "无法打开配置文件: " << configPath << std::endl;
        return false;
    }

    // 设置令牌
    Yume::Set_config setConfig(config, configPath);
    setConfig.setToken(token);

    std::cout << "成功设置GitHub API令牌" << std::endl;
    return true;
}

// 列出所有已订阅的仓库
void listRepositories(std::string const& configPath) {
    Yume::ReadConfig readConfig(configPath);
    auto             repositories = readConfig.getAllRepositories();

    if (repositories.empty()) {
        std::cout << "尚未订阅任何仓库" << std::endl;
        return;
    }

    std::cout << "已订阅的仓库列表:" << std::endl;
    std::cout << "--------------------------------------" << std::endl;

    for (auto const& repo : repositories) {
        std::string owner    = repo["owner"].get<std::string>();
        std::string repoName = repo["repo"].get<std::string>();
        std::string branch   = repo["branch"].get<std::string>();
        std::string lastSha  = repo.contains("lastsha") ? repo["lastsha"].get<std::string>() : "无";

        std::cout << "仓库: " << owner << "/" << repoName << std::endl;
        std::cout << "分支: " << branch << std::endl;
        std::cout << "最新SHA: " << lastSha << std::endl;
        std::cout << "--------------------------------------" << std::endl;
    }
}

int main(int argc, char* argv[]) {
    // 设置信号处理
    std::signal(SIGINT, signalHandler);
    std::signal(SIGTERM, signalHandler);

    // 解析命令行参数
    auto [config, args] = parseArguments(argc, argv);

    // 检查参数数量
    if (args.empty()) {
        std::cerr << "错误: 请提供命令" << std::endl;
        printHelp();
        return 1;
    }

    std::string command = args[0];

    // 确保配置目录存在
    if (!std::filesystem::exists(config.configDir)) {
        try {
            std::filesystem::create_directories(config.configDir);
            std::cout << "已创建配置目录: " << config.configDir << std::endl;
        } catch (std::exception const& e) {
            std::cerr << "无法创建配置目录: " << e.what() << std::endl;
            return 1;
        }
    }

    // 确保样式目录存在
    if (!std::filesystem::exists(config.styleDir)) {
        try {
            std::filesystem::create_directories(config.styleDir);
            std::cout << "已创建样式目录: " << config.styleDir << std::endl;
        } catch (std::exception const& e) {
            std::cerr << "无法创建样式目录: " << e.what() << std::endl;
            return 1;
        }
    }

    // 确保输出目录存在
    if (!std::filesystem::exists(config.outputDir)) {
        try {
            std::filesystem::create_directories(config.outputDir);
            std::cout << "已创建输出目录: " << config.outputDir << std::endl;
        } catch (std::exception const& e) {
            std::cerr << "无法创建输出目录: " << e.what() << std::endl;
            return 1;
        }
    }

    // 创建 Yume::GitHubAPI 实例
    Yume::GitHubAPI githubApi(config.getConfigPath()); // Corrected: Class name is GitHubAPI

    // 创建 Yume::ScreenshotManager 实例
    Yume::ScreenshotManager screenshotManager(config.styleDir);

    // 创建 Yume::SystemInfoManager 实例
    Yume::SystemInfoManager systemInfoManager; // Corrected: Use Yume namespace

    // 处理命令
    if (command == "add" && args.size() >= 3) {
        std::string      owner  = args[1];
        std::string      repo   = args[2];
        std::string      branch = (args.size() >= 4) ? args[3] : "main";
        Yume::Set_config set_config(
            githubApi.m_config,
            config.getConfigPath()); // m_config is public in GitHubAPI or has a getter
        set_config.addRepository(owner, repo, branch);
    } else if (command == "check" && args.size() >= 3) {
        if (args.size() < 3) {
            std::cerr << "错误: check命令需要owner和repo参数" << std::endl;
            std::cerr << "用法: YumeCard check <owner> <repo>" << std::endl;
            return 1;
        }

        std::string owner = args[1];
        std::string repo  = args[2];

        Yume::GitHubSubscriber subscriber(config.getConfigPath(), config.styleDir, config.outputDir);
        std::cout << "检查仓库 " << owner << "/" << repo << " 的更新..." << std::endl;
        auto newCommits = subscriber.checkRepositoryUpdates(owner, repo);

        if (newCommits.empty()) {
            std::cout << "没有新的commits。" << std::endl;
        } else {
            std::cout << "找到 " << newCommits.size() << " 个新的commits：" << std::endl;

            // 使用新的打印commits方法
            Yume::GitHubSubscriber::printCommits(newCommits);
        }
        return 0;
    } else if (command == "monitor") {
        unsigned int interval = (args.size() > 1) ? std::stoi(args[1]) : 10;

        Yume::GitHubSubscriber subscriber(config.getConfigPath(), config.styleDir, config.outputDir);
        std::cout << "开始监控所有仓库，间隔 " << interval << " 分钟..." << std::endl;
        std::cout << "使用配置目录: " << config.configDir << std::endl;
        std::cout << "使用样式目录: " << config.styleDir << std::endl;
        std::cout << "输出图像目录: " << config.outputDir << std::endl;
        std::cout << "按Ctrl+C终止监控" << std::endl;

        // 开始定期检查任务
        std::thread monitorThread([&subscriber, interval]() { subscriber.startPeriodicCheck(interval); });

        // 主线程等待直到收到终止信号
        while (gRunning) std::this_thread::sleep_for(std::chrono::seconds(1));

        // 等待监控线程完成（实际上不会完成，因为它是一个无限循环）
        // 这里只是为了正确地分离线程
        monitorThread.detach();

        std::cout << "程序已终止" << std::endl;
        return 0;
    } else if (command == "set-token") {
        if (args.size() < 2) {
            std::cerr << "错误: set-token命令需要token参数" << std::endl;
            std::cerr << "用法: YumeCard set-token <token>" << std::endl;
            return 1;
        }

        std::string token = args[1];
        if (setGitHubToken(config.getConfigPath(), token)) return 0;
        else return 1;
    } else if (command == "list") {
        listRepositories(config.getConfigPath());
        return 0;
    } else if (command == "test-screenshot") { // New command handling
        std::map<std::string, std::string> vars;
        vars["title"]       = "Test Card";
        vars["description"] = "This is a test screenshot from YumeCard.";
        vars["stars"]       = "123";
        vars["forks"]       = "45";
        vars["language"]    = "C++";
        vars["repo_url"]    = "https://github.com/YumeYuka/YumeCard";
        vars["avatar_url"] =
            "https://avatars.githubusercontent.com/u/YOUR_USER_ID?v=4"; // Replace with actual URL or
                                                                        // placeholder
        vars["bg_image"] = screenshotManager.getRandomBackground();

        std::string htmlPath = config.outputDir + "/test_card.html";
        std::string pngPath  = config.outputDir + "/test_card.png";

        if (screenshotManager.generateTemplate(config.styleDir + "/template.html", vars, htmlPath))
            screenshotManager.takeScreenshot(htmlPath, pngPath);
    } else if (command == "system-info") {
        systemInfoManager.displaySystemInfo(); // Corrected: Call method on the instance
    } else if (command == "diagnostic" && args.size() >= 2) {
        systemInfoManager.generateDiagnosticReport(args[1]);
    } else if (command == "version") {
        printVersion();
    } else if (command == "help") {
        printHelp();
    } else {
        std::cerr << "错误: 未知命令或参数不足: " << command << std::endl;
        printHelp();
        return 1;
    }

    return 0;
}

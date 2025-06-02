package main

import (
	"encoding/json"
	"flag"
	"fmt"
	"log"
	"os"
	"os/signal"
	"path/filepath"
	"strconv"
	"syscall"
	"time"
)

// AppConfig 配置信息结构体
type AppConfig struct {
	ConfigDir string
	StyleDir  string
	OutputDir string
}

// GetConfigPath 获取配置文件路径
func (c *AppConfig) GetConfigPath() string {
	return filepath.Join(c.ConfigDir, "config.json")
}

// Config 配置文件结构
type Config struct {
	GitHub GitHubConfig `json:"GitHub"`
}

// GitHubConfig GitHub配置
type GitHubConfig struct {
	Username    string       `json:"username"`
	Backgrounds string       `json:"backgrounds"`
	Token       string       `json:"token"`
	Repository  []Repository `json:"repository"`
}

// Repository 仓库信息
type Repository struct {
	Owner   string `json:"owner"`
	Branch  string `json:"branch"`
	Repo    string `json:"repo"`
	LastSha string `json:"lastsha"`
}

// 全局变量
var (
	running = true
)

func main() {
	// 设置信号处理
	c := make(chan os.Signal, 1)
	signal.Notify(c, os.Interrupt, syscall.SIGTERM)
	go func() {
		<-c
		fmt.Println("接收到信号，准备终止程序...")
		running = false
	}()

	// 解析命令行参数
	config, args := parseArguments()

	// 检查参数数量
	if len(args) == 0 {
		fmt.Fprintf(os.Stderr, "错误: 请提供命令\n")
		printHelp()
		os.Exit(1)
	}

	command := args[0]

	// 确保目录存在
	if err := ensureDirectories(config); err != nil {
		fmt.Fprintf(os.Stderr, "创建目录失败: %v\n", err)
		os.Exit(1)
	}

	// 处理命令
	switch command {
	case "add":
		if len(args) < 3 {
			fmt.Fprintf(os.Stderr, "错误: add命令需要owner和repo参数\n")
			fmt.Fprintf(os.Stderr, "用法: YumeCard add <owner> <repo> [branch]\n")
			os.Exit(1)
		}
		owner := args[1]
		repo := args[2]
		branch := "main"
		if len(args) >= 4 {
			branch = args[3]
		}
		if err := addRepository(config.GetConfigPath(), owner, repo, branch); err != nil {
			fmt.Fprintf(os.Stderr, "添加仓库失败: %v\n", err)
			os.Exit(1)
		}

	case "check":
		if len(args) < 3 {
			fmt.Fprintf(os.Stderr, "错误: check命令需要owner和repo参数\n")
			fmt.Fprintf(os.Stderr, "用法: YumeCard check <owner> <repo>\n")
			os.Exit(1)
		}
		owner := args[1]
		repo := args[2]
		if err := checkRepository(config, owner, repo); err != nil {
			fmt.Fprintf(os.Stderr, "检查仓库失败: %v\n", err)
			os.Exit(1)
		}

	case "monitor":
		interval := 10
		if len(args) > 1 {
			var err error
			interval, err = strconv.Atoi(args[1])
			if err != nil {
				fmt.Fprintf(os.Stderr, "错误: 无效的间隔时间: %v\n", err)
				os.Exit(1)
			}
		}
		monitorRepositories(config, interval)

	case "set-token":
		if len(args) < 2 {
			fmt.Fprintf(os.Stderr, "错误: set-token命令需要token参数\n")
			fmt.Fprintf(os.Stderr, "用法: YumeCard set-token <token>\n")
			os.Exit(1)
		}
		token := args[1]
		if err := setGitHubToken(config.GetConfigPath(), token); err != nil {
			fmt.Fprintf(os.Stderr, "设置token失败: %v\n", err)
			os.Exit(1)
		}

	case "list":
		listRepositories(config.GetConfigPath())

	case "test-screenshot":
		fmt.Println("正在使用测试数据生成截图...")
		fmt.Printf("使用样式目录: %s\n", config.StyleDir)
		fmt.Printf("输出图像目录: %s\n", config.OutputDir)
		if err := testScreenshot(config); err != nil {
			fmt.Fprintf(os.Stderr, "测试截图生成失败: %v\n", err)
			os.Exit(1)
		}
		fmt.Println("测试截图生成成功!")

	case "system-info":
		displaySystemInfo()

	case "diagnostic":
		if len(args) < 2 {
			fmt.Fprintf(os.Stderr, "错误: diagnostic命令需要输出文件参数\n")
			os.Exit(1)
		}
		generateDiagnosticReport(args[1])

	case "version":
		PrintVersion()

	case "help":
		printHelp()

	default:
		fmt.Fprintf(os.Stderr, "错误: 未知命令或参数不足: %s\n", command)
		printHelp()
		os.Exit(1)
	}
}

// parseArguments 解析命令行参数
func parseArguments() (*AppConfig, []string) {
	config := &AppConfig{
		ConfigDir: "./config",
		StyleDir:  "./Style",
		OutputDir: "./Style",
	}

	var showVersion, showHelp bool

	flag.StringVar(&config.ConfigDir, "config", "./config", "指定配置文件目录")
	flag.StringVar(&config.StyleDir, "style", "./Style", "指定样式文件目录")
	flag.StringVar(&config.OutputDir, "output", "./Style", "指定输出图像目录")
	flag.BoolVar(&showVersion, "version", false, "显示版本信息")
	flag.BoolVar(&showHelp, "help", false, "显示帮助信息")

	flag.Parse()

	if showVersion {
		PrintVersion()
		os.Exit(0)
	}

	if showHelp {
		printHelp()
		os.Exit(0)
	}

	return config, flag.Args()
}

// printHelp 显示帮助信息
func printHelp() {
	fmt.Printf("YumeCard GitHub 订阅工具 v%s - 使用帮助\n", AppVersion.String)
	fmt.Println("--------------------------------------")
	fmt.Println("用法: YumeCard [选项] <命令> [参数...]")
	fmt.Println()
	fmt.Println("全局选项:")
	fmt.Println("  --config <路径>              - 指定配置文件目录 (默认: ./config)")
	fmt.Println("  --style <路径>               - 指定样式文件目录 (默认: ./Style)")
	fmt.Println("  --output <路径>              - 指定输出图像目录 (默认: ./Style)")
	fmt.Println("  --version                    - 显示版本信息")
	fmt.Println("  --help                       - 显示此帮助信息")
	fmt.Println()
	fmt.Println("可用命令:")
	fmt.Println("  add <owner> <repo> [branch]  - 添加新的GitHub仓库订阅")
	fmt.Println("  check <owner> <repo>         - 检查特定仓库的更新")
	fmt.Println("  monitor [interval]           - 开始监控所有仓库 (默认每10分钟)")
	fmt.Println("  set-token <token>            - 设置GitHub API访问令牌")
	fmt.Println("  list                         - 列出所有已订阅的仓库")
	fmt.Println("  test-screenshot              - 使用测试数据生成提交卡片截图")
	fmt.Println("  system-info                  - 显示系统信息和兼容性检查")
	fmt.Println("  diagnostic                   - 生成诊断报告")
	fmt.Println("  version                      - 显示版本信息")
	fmt.Println("  help                         - 显示此帮助信息")
	fmt.Println()
	fmt.Println("示例:")
	fmt.Println("  YumeCard add YumeYuka YumeCard main")
	fmt.Println("  YumeCard --config ./myconfig check YumeYuka YumeCard")
	fmt.Println("  YumeCard --style ./mystyle --output ./images monitor 30")
	fmt.Println("  YumeCard set-token ghp_xxxxxxxxxxxx")
	fmt.Println("  YumeCard --config ./config --style ./themes test-screenshot")
	fmt.Println("  YumeCard --version")
	fmt.Println("--------------------------------------")
}

// ensureDirectories 确保目录存在
func ensureDirectories(config *AppConfig) error {
	dirs := []string{config.ConfigDir, config.StyleDir, config.OutputDir}

	for _, dir := range dirs {
		if _, err := os.Stat(dir); os.IsNotExist(err) {
			if err := os.MkdirAll(dir, 0755); err != nil {
				return fmt.Errorf("无法创建目录 %s: %w", dir, err)
			}
			fmt.Printf("已创建目录: %s\n", dir)
		}
	}

	return nil
}

// loadConfig 加载配置文件
func loadConfig(configPath string) (*Config, error) {
	data, err := os.ReadFile(configPath)
	if err != nil {
		return nil, fmt.Errorf("无法读取配置文件: %w", err)
	}

	var config Config
	if err := json.Unmarshal(data, &config); err != nil {
		return nil, fmt.Errorf("无法解析配置文件: %w", err)
	}

	return &config, nil
}

// saveConfig 保存配置文件
func saveConfig(configPath string, config *Config) error {
	data, err := json.MarshalIndent(config, "", "    ")
	if err != nil {
		return fmt.Errorf("无法序列化配置: %w", err)
	}

	if err := os.WriteFile(configPath, data, 0644); err != nil {
		return fmt.Errorf("无法写入配置文件: %w", err)
	}

	return nil
}

// setGitHubToken 设置GitHub API令牌
func setGitHubToken(configPath, token string) error {
	if token == "" {
		return fmt.Errorf("令牌不能为空")
	}

	config, err := loadConfig(configPath)
	if err != nil {
		// 如果配置文件不存在，创建默认配置
		config = &Config{
			GitHub: GitHubConfig{
				Repository: make([]Repository, 0),
			},
		}
	}

	config.GitHub.Token = token

	if err := saveConfig(configPath, config); err != nil {
		return err
	}

	fmt.Println("成功设置GitHub API令牌")
	return nil
}

// addRepository 添加仓库订阅
func addRepository(configPath, owner, repo, branch string) error {
	config, err := loadConfig(configPath)
	if err != nil {
		// 如果配置文件不存在，创建默认配置
		config = &Config{
			GitHub: GitHubConfig{
				Repository: make([]Repository, 0),
			},
		}
	}

	// 检查仓库是否已存在
	for _, r := range config.GitHub.Repository {
		if r.Owner == owner && r.Repo == repo {
			fmt.Printf("仓库 %s/%s 已存在\n", owner, repo)
			return nil
		}
	}

	// 添加新仓库
	newRepo := Repository{
		Owner:   owner,
		Repo:    repo,
		Branch:  branch,
		LastSha: "",
	}

	config.GitHub.Repository = append(config.GitHub.Repository, newRepo)

	if err := saveConfig(configPath, config); err != nil {
		return err
	}

	fmt.Printf("成功添加仓库 %s/%s\n", owner, repo)
	return nil
}

// listRepositories 列出所有已订阅的仓库
func listRepositories(configPath string) {
	config, err := loadConfig(configPath)
	if err != nil {
		fmt.Println("尚未订阅任何仓库")
		return
	}

	if len(config.GitHub.Repository) == 0 {
		fmt.Println("尚未订阅任何仓库")
		return
	}

	fmt.Println("已订阅的仓库列表:")
	fmt.Println("--------------------------------------")

	for _, repo := range config.GitHub.Repository {
		lastSha := repo.LastSha
		if lastSha == "" {
			lastSha = "无"
		}

		fmt.Printf("仓库: %s/%s\n", repo.Owner, repo.Repo)
		fmt.Printf("分支: %s\n", repo.Branch)
		fmt.Printf("最新SHA: %s\n", lastSha)
		fmt.Println("--------------------------------------")
	}
}

// checkRepository 检查特定仓库的更新
func checkRepository(config *AppConfig, owner, repo string) error {
	fmt.Printf("检查仓库 %s/%s 的更新...\n", owner, repo)

	// TODO: 实现GitHub API调用和commit检查逻辑
	// 这里需要实现与GitHub API的交互
	fmt.Printf("仓库 %s/%s 检查完成\n", owner, repo)

	return nil
}

// monitorRepositories 监控所有仓库
func monitorRepositories(config *AppConfig, intervalMinutes int) {
	fmt.Printf("开始监控所有仓库，间隔 %d 分钟...\n", intervalMinutes)
	fmt.Printf("使用配置目录: %s\n", config.ConfigDir)
	fmt.Printf("使用样式目录: %s\n", config.StyleDir)
	fmt.Printf("输出图像目录: %s\n", config.OutputDir)
	fmt.Println("按Ctrl+C终止监控")

	ticker := time.NewTicker(time.Duration(intervalMinutes) * time.Minute)
	defer ticker.Stop()

	// 立即执行一次检查
	checkAllRepositories(config)

	for running {
		select {
		case <-ticker.C:
			if running {
				checkAllRepositories(config)
			}
		}
	}

	fmt.Println("程序已终止")
}

// checkAllRepositories 检查所有仓库
func checkAllRepositories(config *AppConfig) {
	cfg, err := loadConfig(config.GetConfigPath())
	if err != nil {
		log.Printf("加载配置失败: %v", err)
		return
	}

	for _, repo := range cfg.GitHub.Repository {
		if !running {
			break
		}

		fmt.Printf("检查仓库 %s/%s 的更新...\n", repo.Owner, repo.Repo)

		// TODO: 实现具体的检查逻辑
		// 这里需要调用GitHub API，检查新的commits，生成截图等

		time.Sleep(1 * time.Second) // 避免API频率限制
	}
}

// testScreenshot 测试截图功能
func testScreenshot(config *AppConfig) error {
	// TODO: 实现测试截图功能
	// 这里需要生成测试数据并调用截图功能
	fmt.Println("测试截图功能...")

	return nil
}

// displaySystemInfo 显示系统信息
func displaySystemInfo() {
	fmt.Println("系统信息:")
	fmt.Printf("操作系统: %s\n", AppVersion.TargetPlatform)
	fmt.Printf("架构: %s\n", AppVersion.TargetArch)
	fmt.Printf("Go版本: %s\n", AppVersion.CompilerVersion)
	fmt.Printf("编译器: %s\n", AppVersion.Compiler)
}

// generateDiagnosticReport 生成诊断报告
func generateDiagnosticReport(outputPath string) {
	fmt.Printf("正在生成诊断报告到: %s\n", outputPath)

	report := fmt.Sprintf(`YumeCard 诊断报告
===================

版本信息:
%s

系统信息:
操作系统: %s
架构: %s
Go版本: %s
编译器: %s

生成时间: %s
`,
		AppVersion.FullString(),
		AppVersion.TargetPlatform,
		AppVersion.TargetArch,
		AppVersion.CompilerVersion,
		AppVersion.Compiler,
		time.Now().Format("2006-01-02 15:04:05"),
	)

	if err := os.WriteFile(outputPath, []byte(report), 0644); err != nil {
		fmt.Fprintf(os.Stderr, "写入诊断报告失败: %v\n", err)
		return
	}

	fmt.Printf("诊断报告已生成: %s\n", outputPath)
}

package main

import (
	"fmt"
	"runtime"
)

// Version 版本信息结构体
type Version struct {
	ProjectName     string
	String          string
	Major           string
	Minor           string
	Patch           string
	BuildDate       string
	BuildCommit     string
	TargetPlatform  string
	TargetArch      string
	Compiler        string
	CompilerVersion string
}

// 全局版本信息实例
var AppVersion = Version{
	ProjectName:     "YumeCard",
	String:          "1.0.0",
	Major:           "1",
	Minor:           "0",
	Patch:           "0",
	BuildDate:       "2025-06-02", // 可以在构建时通过ldflags设置
	BuildCommit:     "unknown",    // 可以在构建时通过ldflags设置
	TargetPlatform:  runtime.GOOS,
	TargetArch:      runtime.GOARCH,
	Compiler:        runtime.Compiler,
	CompilerVersion: runtime.Version(),
}

// FullString 返回完整的版本信息字符串
func (v *Version) FullString() string {
	return fmt.Sprintf("%s version %s (Build: %s on %s, %s %s, Compiler: %s %s)",
		v.ProjectName,
		v.String,
		v.BuildCommit,
		v.BuildDate,
		v.TargetPlatform,
		v.TargetArch,
		v.Compiler,
		v.CompilerVersion,
	)
}

// PrintVersion 显示版本信息
func PrintVersion() {
	fmt.Println("YumeCard GitHub 订阅工具")
	fmt.Printf("版本: %s\n", AppVersion.String)
	fmt.Printf("构建时间: %s\n", AppVersion.BuildDate)
	fmt.Printf("Git Commit: %s\n", AppVersion.BuildCommit)
	fmt.Printf("目标平台: %s (%s)\n", AppVersion.TargetPlatform, AppVersion.TargetArch)
	fmt.Printf("编译器: %s %s\n", AppVersion.Compiler, AppVersion.CompilerVersion)
	fmt.Println()
	fmt.Printf("完整版本信息: %s\n", AppVersion.FullString())
}

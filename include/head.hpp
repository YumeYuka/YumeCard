//
// Created by YumeYuka on 2025/5/30.
// 所有的头文件都在这里包含
//
#pragma once

// 平台检测宏
#ifdef _WIN32
    #define YUMECARD_PLATFORM_WINDOWS
    #ifdef _WIN64
        #define YUMECARD_PLATFORM_WIN64
    #else
        #define YUMECARD_PLATFORM_WIN32
    #endif
    // Windows架构检测
    #if defined(_M_X64) || defined(__x86_64__)
        #define YUMECARD_PLATFORM_WINDOWS_X64
    #elif defined(_M_IX86) || defined(__i386__)
        #define YUMECARD_PLATFORM_WINDOWS_X86
    #elif defined(_M_ARM64) || defined(__aarch64__)
        #define YUMECARD_PLATFORM_WINDOWS_ARM64
    #elif defined(_M_ARM) || defined(__arm__)
        #define YUMECARD_PLATFORM_WINDOWS_ARM32
    #endif
#elif defined(__linux__)
    #define YUMECARD_PLATFORM_LINUX
    #if defined(__x86_64__) || defined(__amd64__)
        #define YUMECARD_PLATFORM_LINUX_X64
    #elif defined(__i386__) || defined(__i486__) || defined(__i586__) || defined(__i686__)
        #define YUMECARD_PLATFORM_LINUX_X86
    #elif defined(__aarch64__)
        #define YUMECARD_PLATFORM_LINUX_ARM64
    #elif defined(__arm__)
        #define YUMECARD_PLATFORM_LINUX_ARM32
    #elif defined(__riscv) && (__riscv_xlen == 64)
        #define YUMECARD_PLATFORM_LINUX_RISCV64
    #elif defined(__riscv) && (__riscv_xlen == 32)
        #define YUMECARD_PLATFORM_LINUX_RISCV32
    #elif defined(__mips64)
        #define YUMECARD_PLATFORM_LINUX_MIPS64
    #elif defined(__mips__)
        #define YUMECARD_PLATFORM_LINUX_MIPS32
    #elif defined(__powerpc64__)
        #define YUMECARD_PLATFORM_LINUX_PPC64
    #elif defined(__powerpc__)
        #define YUMECARD_PLATFORM_LINUX_PPC32
    #endif
#elif defined(__APPLE__)
    #define YUMECARD_PLATFORM_MACOS
    #include <TargetConditionals.h>
    #if TARGET_OS_MAC
        #define YUMECARD_PLATFORM_MACOS_DESKTOP
        #if defined(__x86_64__)
            #define YUMECARD_PLATFORM_MACOS_X64
        #elif defined(__aarch64__) || defined(__arm64__)
            #define YUMECARD_PLATFORM_MACOS_ARM64
        #elif defined(__i386__)
            #define YUMECARD_PLATFORM_MACOS_X86
        #endif
    #endif
#elif defined(__FreeBSD__)
    #define YUMECARD_PLATFORM_FREEBSD
    #if defined(__x86_64__) || defined(__amd64__)
        #define YUMECARD_PLATFORM_FREEBSD_X64
    #elif defined(__i386__)
        #define YUMECARD_PLATFORM_FREEBSD_X86
    #elif defined(__aarch64__)
        #define YUMECARD_PLATFORM_FREEBSD_ARM64
    #endif
#elif defined(__OpenBSD__)
    #define YUMECARD_PLATFORM_OPENBSD
#elif defined(__NetBSD__)
    #define YUMECARD_PLATFORM_NETBSD
#endif

// 通用架构检测
#if defined(__x86_64__) || defined(__amd64__) || defined(_M_X64)
    #define YUMECARD_ARCH_X64
#elif defined(__i386__) || defined(__i486__) || defined(__i586__) || defined(__i686__) || defined(_M_IX86)
    #define YUMECARD_ARCH_X86
#elif defined(__aarch64__) || defined(__arm64__) || defined(_M_ARM64)
    #define YUMECARD_ARCH_ARM64
#elif defined(__arm__) || defined(_M_ARM)
    #define YUMECARD_ARCH_ARM32
#elif defined(__riscv) && (__riscv_xlen == 64)
    #define YUMECARD_ARCH_RISCV64
#elif defined(__riscv) && (__riscv_xlen == 32)
    #define YUMECARD_ARCH_RISCV32
#elif defined(__mips64)
    #define YUMECARD_ARCH_MIPS64
#elif defined(__mips__)
    #define YUMECARD_ARCH_MIPS32
#elif defined(__powerpc64__)
    #define YUMECARD_ARCH_PPC64
#elif defined(__powerpc__)
    #define YUMECARD_ARCH_PPC32
#endif

// 字节序检测
#if defined(__BYTE_ORDER__) && defined(__ORDER_LITTLE_ENDIAN__) && defined(__ORDER_BIG_ENDIAN__)
    #if __BYTE_ORDER__ == __ORDER_LITTLE_ENDIAN__
        #define YUMECARD_LITTLE_ENDIAN
    #elif __BYTE_ORDER__ == __ORDER_BIG_ENDIAN__
        #define YUMECARD_BIG_ENDIAN
    #endif
#elif defined(_WIN32)
    // Windows通常是小端
    #define YUMECARD_LITTLE_ENDIAN
#endif

// 标准C++头文件
#include <chrono>
#include <cstdlib>
#include <filesystem>
#include <fstream>
#include <iomanip>
#include <iostream>
#include <map>
#include <memory>
#include <random>
#include <regex>
#include <sstream>
#include <string>
#include <thread>
#include <utility>
#include <vector>

// 平台特定的头文件
#ifdef YUMECARD_PLATFORM_WINDOWS
    #include <csignal> // Windows信号处理

    #include <direct.h>
    #include <io.h>
    #include <windows.h>
    // 解决Windows宏冲突
    #ifdef max
        #undef max
    #endif
    #ifdef min
        #undef min
    #endif
#else
    #include <csignal> // POSIX信号处理

    #include <dirent.h>
    #include <unistd.h>

    #include <sys/stat.h>
    #include <sys/types.h>
    #ifdef YUMECARD_PLATFORM_LINUX
        #include <pthread.h>

        #include <sys/utsname.h>
    #endif
#endif

// 第三方库
#include <nlohmann/json.hpp>

#include <curl/curl.h>

// 时间相关（跨平台兼容）
#include <time.h>
#ifdef YUMECARD_PLATFORM_WINDOWS
    #include <sys/timeb.h>
#else
    #include <sys/time.h>
#endif
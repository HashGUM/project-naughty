# GDExtension编译自动化脚本
# 检测环境并提供编译指引

param(
    [switch]$Install,
    [switch]$Build,
    [switch]$Check
)

$ErrorActionPreference = "Continue"

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  GDExtension + llama.cpp 编译助手" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# 检查Python
Write-Host "[1/6] 检查Python..." -ForegroundColor Yellow
$python = Get-Command python -ErrorAction SilentlyContinue
if ($python) {
    $pythonVersion = python --version
    Write-Host "  ✓ $pythonVersion" -ForegroundColor Green
} else {
    Write-Host "  ✗ Python未安装" -ForegroundColor Red
    exit 1
}

# 检查SCons
Write-Host "[2/6] 检查SCons..." -ForegroundColor Yellow
$sconsCheck = python -m SCons --version 2>&1
if ($LASTEXITCODE -eq 0) {
    Write-Host "  ✓ SCons已安装" -ForegroundColor Green
} else {
    Write-Host "  ✗ SCons未安装" -ForegroundColor Red
    if ($Install) {
        Write-Host "  → 正在安装SCons..." -ForegroundColor Cyan
        pip install scons
    } else {
        Write-Host "  运行 ./build.ps1 -Install 自动安装" -ForegroundColor Yellow
        exit 1
    }
}

# 检查Git
Write-Host "[3/6] 检查Git..." -ForegroundColor Yellow
$git = Get-Command git -ErrorAction SilentlyContinue
if ($git) {
    $gitVersion = git --version
    Write-Host "  ✓ $gitVersion" -ForegroundColor Green
} else {
    Write-Host "  ✗ Git未安装" -ForegroundColor Red
    Write-Host "  请从 https://git-scm.com/download/win 下载安装" -ForegroundColor Yellow
    exit 1
}

# 检查C++编译器
Write-Host "[4/6] 检查C++编译器..." -ForegroundColor Yellow
$hasMSVC = Get-Command cl.exe -ErrorAction SilentlyContinue
$hasMinGW = Get-Command g++.exe -ErrorAction SilentlyContinue

if ($hasMSVC) {
    Write-Host "  ✓ 找到MSVC编译器" -ForegroundColor Green
    $compiler = "msvc"
} elseif ($hasMinGW) {
    Write-Host "  ✓ 找到MinGW编译器" -ForegroundColor Green
    $compiler = "mingw"
} else {
    Write-Host "  ✗ 未找到C++编译器" -ForegroundColor Red
    Write-Host ""
    Write-Host "  请选择一个方案：" -ForegroundColor Yellow
    Write-Host "  1. Visual Studio 2022 Community (推荐)" -ForegroundColor Cyan
    Write-Host "     https://visualstudio.microsoft.com/zh-hans/downloads/" -ForegroundColor Cyan
    Write-Host "     选择'使用C++的桌面开发'工作负载" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "  2. w64devkit (轻量级，90MB)" -ForegroundColor Cyan
    Write-Host "     https://github.com/skeeto/w64devkit/releases" -ForegroundColor Cyan
    Write-Host "     下载后解压，在其终端中运行编译命令" -ForegroundColor Cyan
    Write-Host ""
    
    if (-not $Check) {
        exit 1
    }
}

# 检查godot-cpp
Write-Host "[5/6] 检查godot-cpp..." -ForegroundColor Yellow
if (Test-Path "godot-cpp\.git") {
    Write-Host "  ✓ godot-cpp已克隆" -ForegroundColor Green
} else {
    Write-Host "  ✗ godot-cpp未找到" -ForegroundColor Red
    if ($Install) {
        Write-Host "  → 正在克隆godot-cpp..." -ForegroundColor Cyan
        git clone --depth 1 --branch godot-4.3-stable https://github.com/godotengine/godot-cpp
    } else {
        Write-Host "  运行 ./build.ps1 -Install 自动克隆" -ForegroundColor Yellow
        exit 1
    }
}

# 检查godot-cpp是否已编译
Write-Host "[6/6] 检查godot-cpp编译状态..." -ForegroundColor Yellow
if (Test-Path "godot-cpp\bin\libgodot-cpp.windows.template_debug.x86_64.lib") {
    Write-Host "  ✓ godot-cpp已编译" -ForegroundColor Green
} else {
    Write-Host "  ⚠ godot-cpp未编译" -ForegroundColor Yellow
    if ($Build -and $compiler) {
        Write-Host "  → 正在编译godot-cpp（需要5-10分钟）..." -ForegroundColor Cyan
        Push-Location godot-cpp
        scons platform=windows target=template_debug
        Pop-Location
    }
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  环境检查完成" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# 如果请求构建
if ($Build -and $compiler) {
    Write-Host "开始编译GDExtension..." -ForegroundColor Green
    Write-Host ""
    
    scons platform=windows target=template_debug
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host ""
        Write-Host "========================================" -ForegroundColor Green
        Write-Host "  ✓ 编译成功！" -ForegroundColor Green
        Write-Host "========================================" -ForegroundColor Green
        Write-Host ""
        Write-Host "DLL已生成到 bin/ 目录" -ForegroundColor Cyan
        Write-Host "现在可以在Godot中打开项目测试" -ForegroundColor Cyan
    } else {
        Write-Host ""
        Write-Host "✗ 编译失败，请检查错误信息" -ForegroundColor Red
    }
}

# 仅检查模式
if ($Check) {
    Write-Host "使用说明：" -ForegroundColor Cyan
    Write-Host "  .\build.ps1 -Install  # 安装依赖（SCons、godot-cpp）" -ForegroundColor White
    Write-Host "  .\build.ps1 -Build    # 编译GDExtension" -ForegroundColor White
    Write-Host "  .\build.ps1 -Check    # 仅检查环境" -ForegroundColor White
}


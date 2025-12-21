# 下载预编译的llama.cpp脚本
# 这个脚本会从llama.cpp-python的发布中下载预编译的DLL

$ErrorActionPreference = "Stop"

Write-Host "开始下载预编译的llama.cpp..." -ForegroundColor Green

# 使用llama-cpp-python的预编译wheel，它包含了编译好的llama.cpp
$pythonVersion = "cp313"  # Python 3.13
$platform = "win_amd64"

# 临时安装llama-cpp-python来获取编译好的DLL
Write-Host "安装llama-cpp-python（包含预编译DLL）..." -ForegroundColor Yellow
pip install llama-cpp-python --no-deps --force-reinstall

# 查找安装的llama-cpp-python位置
$llamacppPath = python -c "import llama_cpp; import os; print(os.path.dirname(llama_cpp.__file__))"

Write-Host "llama-cpp-python安装在: $llamacppPath" -ForegroundColor Cyan

# 复制DLL文件
if (Test-Path "$llamacppPath\llama_cpp.dll") {
    Write-Host "找到llama_cpp.dll，正在复制..." -ForegroundColor Green
    Copy-Item "$llamacppPath\llama_cpp.dll" "bin\llama.dll" -Force
    Write-Host "✓ 已复制llama.dll到bin目录" -ForegroundColor Green
} else {
    Write-Host "未找到llama_cpp.dll，尝试其他位置..." -ForegroundColor Yellow
    
    # 查找.pyd或.so文件
    $dllFiles = Get-ChildItem -Path $llamacppPath -Filter "*.dll" -Recurse
    if ($dllFiles) {
        Write-Host "找到DLL文件:" -ForegroundColor Green
        foreach ($file in $dllFiles) {
            Write-Host "  - $($file.FullName)" -ForegroundColor Cyan
            Copy-Item $file.FullName "bin\$($file.Name)" -Force
        }
    }
}

# 检查是否成功
if (Test-Path "bin\llama.dll") {
    Write-Host "`n✅ 成功！llama.dll已准备就绪" -ForegroundColor Green
    Write-Host "文件大小: $((Get-Item 'bin\llama.dll').Length / 1MB) MB" -ForegroundColor Cyan
} else {
    Write-Host "`n⚠️ 未找到llama.dll，可能需要手动处理" -ForegroundColor Red
}


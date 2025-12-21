# 重新编译脚本（PowerShell版）
# 用于修复编码问题后重新编译GDExtension

Write-Host "================================================" -ForegroundColor Cyan
Write-Host "  Rebuilding GDExtension with Encoding Fix" -ForegroundColor Cyan
Write-Host "================================================" -ForegroundColor Cyan
Write-Host ""

# 检查Godot进程
Write-Host "[1/3] Checking for Godot processes..." -ForegroundColor Yellow
$godotProcesses = Get-Process -Name "Godot*" -ErrorAction SilentlyContinue

if ($godotProcesses) {
    Write-Host ""
    Write-Host "WARNING: Godot is still running!" -ForegroundColor Red
    Write-Host "Found processes:" -ForegroundColor Yellow
    $godotProcesses | Format-Table -Property Id, ProcessName, CPU
    Write-Host ""
    Write-Host "Please close Godot Editor completely and run this script again." -ForegroundColor Red
    Write-Host ""
    Read-Host "Press Enter to exit"
    exit 1
}

Write-Host "OK - No Godot process found" -ForegroundColor Green
Write-Host ""

# 删除旧DLL
Write-Host "[2/3] Cleaning old DLL..." -ForegroundColor Yellow
$dllPath = "bin\libllama_godot.windows.template_debug.x86_64.dll"

if (Test-Path $dllPath) {
    try {
        Remove-Item $dllPath -Force
        Write-Host "OK - Old DLL removed" -ForegroundColor Green
    } catch {
        Write-Host ""
        Write-Host "ERROR: Cannot delete DLL. File might be locked." -ForegroundColor Red
        Write-Host "Please make sure Godot is completely closed." -ForegroundColor Red
        Write-Host ""
        Read-Host "Press Enter to exit"
        exit 1
    }
} else {
    Write-Host "OK - No old DLL found" -ForegroundColor Green
}
Write-Host ""

# 编译
Write-Host "[3/3] Compiling GDExtension..." -ForegroundColor Yellow
python -m SCons platform=windows target=template_debug

if ($LASTEXITCODE -ne 0) {
    Write-Host ""
    Write-Host "ERROR: Compilation failed!" -ForegroundColor Red
    Write-Host ""
    Read-Host "Press Enter to exit"
    exit 1
}

Write-Host ""
Write-Host "================================================" -ForegroundColor Green
Write-Host "  SUCCESS! DLL rebuilt successfully." -ForegroundColor Green
Write-Host "================================================" -ForegroundColor Green
Write-Host ""
Write-Host "Now you can:" -ForegroundColor Cyan
Write-Host "1. Open Godot Editor" -ForegroundColor White
Write-Host "2. Run the test scene (F6)" -ForegroundColor White
Write-Host "3. All logs should be in English now!" -ForegroundColor White
Write-Host ""
Write-Host "Check the new DLL:" -ForegroundColor Cyan
Get-Item $dllPath | Format-List Name, Length, LastWriteTime
Write-Host ""
Read-Host "Press Enter to exit"


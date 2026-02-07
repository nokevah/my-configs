# setup.ps1
Write-Host "--- Starting Home Base Setup ---" -ForegroundColor Cyan

# 1. Admin Check
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Error "This script must be run as Administrator."
    return
}

# 2. Ensure WinGet DSC Module
if (-not (Get-Module -ListAvailable Microsoft.WinGet.DSC)) {
    Write-Host "Installing Microsoft.WinGet.DSC..." -ForegroundColor Yellow
    Install-Module Microsoft.WinGet.DSC -Force -AllowClobber -Scope CurrentUser -ErrorAction Stop
}
Import-Module Microsoft.WinGet.DSC -ErrorAction SilentlyContinue

# 3. Paths
$rawUrl = "https://raw.githubusercontent.com/nokevah/my-configs/main/home-basics.dsc.yaml"
$tempPath = "$env:TEMP\home-basics.dsc.yaml"

# 4. Download
try {
    Invoke-WebRequest -Uri $rawUrl -OutFile $tempPath -ErrorAction Stop
    Write-Host "Configuration downloaded." -ForegroundColor Gray
} catch {
    Write-Host "ERROR: Could not download configuration from GitHub." -ForegroundColor Red
    return
}

# 5. Execute
Write-Host "Applying configuration. This may take several minutes..." -ForegroundColor White
$logFile = "$env:TEMP\winget_results.txt"

# Run winget configure and capture output
$output = winget configure -f $tempPath --accept-configuration-agreements --disable-interactivity 2>&1 | Tee-Object -FilePath $logFile

# 6. Result Check
if ($LASTEXITCODE -eq 0) {
    Write-Host "`n[SUCCESS] All apps installed correctly." -ForegroundColor Green
} else {
    Write-Host "`n[FAILURE] Errors occurred (Exit Code: $LASTEXITCODE)." -ForegroundColor Red
    Write-Host "Summary of issues:" -ForegroundColor Yellow
    $output | Where-Object { $_ -match "failed" -or $_ -match "error" } | ForEach-Object { Write-Host " -> $_" -ForegroundColor Yellow }
    Write-Host "`nFull log saved to: $logFile" -ForegroundColor Gray
}

# 7. Cleanup
if (Test-Path $tempPath) { Remove-Item $tempPath }

# setup.ps1 - Hardened Version
Write-Host "--- Starting Home Base Setup ---" -ForegroundColor Cyan

# 1. Check for Administrative Privileges
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Error "This script must be run as Administrator."
    return
}

# 2. Ensure the WinGet DSC Module is installed AND loaded
if (-not (Get-Module -ListAvailable Microsoft.WinGet.DSC)) {
    Write-Host "Installing Microsoft.WinGet.DSC module..." -ForegroundColor Yellow
    Install-Module Microsoft.WinGet.DSC -Force -AllowClobber -Scope CurrentUser
}
# Force import to ensure the 'winget configure' provider is recognized in this session
Import-Module Microsoft.WinGet.DSC -ErrorAction SilentlyContinue

# 3. Define paths (Matching your 'nokevah/my-configs' repo)
$rawUrl = "https://raw.githubusercontent.com/nokevah/my-configs/main/home-basics.dsc.yaml"
$tempPath = "$env:TEMP\home-basics.dsc.yaml"

# 4. Download the YAML
Write-Host "Downloading configuration from GitHub..." -ForegroundColor Gray
try {
    Invoke-WebRequest -Uri $rawUrl -OutFile $tempPath -ErrorAction Stop
} catch {
    Write-Error "Failed to download YAML. Check your URL or internet connection."
    return
}

# 5. Run the configuration
Write-Host "Applying WinGet Configuration... this may take a while." -ForegroundColor Green
winget configure -f $tempPath --accept-configuration-agreements --accept-package-agreements

# 6. Cleanup
if (Test-Path $tempPath) { Remove-Item $tempPath }

Write-Host "--- Setup Complete! ---" -ForegroundColor Cyan

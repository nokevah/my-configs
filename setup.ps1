# setup.ps1
# 1. Install the required DSC module if missing
if (-not (Get-Module -ListAvailable Microsoft.WinGet.DSC)) {
    Write-Host "Installing WinGet DSC module..." -ForegroundColor Cyan
    Install-Module Microsoft.WinGet.DSC -Force -AllowClobber
}

# 2. Download and run the config
$rawUrl = "https://raw.githubusercontent.com/YOUR_USER/YOUR_REPO/main/home-basics.dsc.yaml"
$tempPath = "$env:TEMP\home-basics.dsc.yaml"

Invoke-WebRequest -Uri $rawUrl -OutFile $tempPath
winget configure -f $tempPath --accept-configuration-agreements --accept-package-agreements

Write-Host "Setup Complete!" -ForegroundColor Green

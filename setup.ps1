# setup.ps1 - Reporting Version
Write-Host "--- Starting Home Base Setup ---" -ForegroundColor Cyan

# 1. Admin Check
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Error "This script must be run as Administrator."
    return
}

# 2. Module Setup
if (-not (Get-Module -ListAvailable Microsoft.WinGet.DSC)) {
    Write-Host "Installing Microsoft.WinGet.DSC..." -ForegroundColor Yellow
    Install-Module Microsoft.WinGet.DSC -Force -AllowClobber -Scope CurrentUser -ErrorAction Stop
}
Import-Module Microsoft.WinGet.DSC -ErrorAction SilentlyContinue

# 3. Download
$rawUrl = "https://raw.githubusercontent.com/nokevah/my-configs/main/home-basics.dsc.yaml"
$tempPath = "$env:TEMP\home-basics.dsc.yaml"

try {
    Invoke-WebRequest -Uri $rawUrl -OutFile $tempPath -ErrorAction Stop
    Write-Host "Configuration downloaded successfully." -ForegroundColor Gray
} catch {
    Write-Host "ERROR: Could not reach GitHub. Check your URL." -ForegroundColor Red
    return
}

# 4. Execute and Capture
Write-Host "Applying configuration... Please wait." -ForegroundColor White
$process = Start-Process winget -ArgumentList "configure -f `"$tempPath`" --accept-configuration-agreements" -Wait -PassThru -NoNewWindow

# 5. Outcome Logic
if ($process.ExitCode -eq 0) {
    Write-Host "`n[SUCCESS] All configurations applied correctly." -ForegroundColor Green
} else {
    Write-Host "`n[FAILURE] The configuration finished with errors (Exit Code: $($process.ExitCode))." -ForegroundColor Red
    Write-Host "Some apps may have failed to install. Checking logs..." -ForegroundColor Yellow
    
    # Optional: Display the specific winget log path for troubleshooting
    $logPath = Get-ChildItem -Path "$env:TEMP\DiagOutputDir" -ErrorAction SilentlyContinue | Sort-Object LastWriteTime -Descending | Select-Object -First 1
    if ($logPath) {
        Write-Host "Detailed logs can be found at: $($logPath.FullName)" -ForegroundColor Gray
    }
}

# 6. Cleanup
if (Test-Path $tempPath) { Remove-Item $tempPath }

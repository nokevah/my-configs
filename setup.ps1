# setup.ps1 - The "It Just Works" Version
# No extra modules, no PowerShell 7 requirement. Standard Windows 11 compatible.

Write-Host "--- Starting Home Base Setup ---" -ForegroundColor Cyan

# 1. Check for Admin
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Error "Please right-click and 'Run as Administrator'."
    exit
}

# 2. Define the App List (Add/Remove IDs here)
$apps = @(
    "Google.Chrome",
    "Mozilla.Firefox",
    "Microsoft.Office",
    "Adobe.Acrobat.Reader.64-bit",
    "7zip.7zip",
    "Microsoft.PowerToys",
    "AgileBits.1Password",
    "Blizzard.BattleNet",
    "NVIDIA.NVIDIAApp",
    "NZXT.CAM"
)

# 3. The Install Loop
foreach ($app in $apps) {
    Write-Host "`nInstalling $app..." -ForegroundColor Yellow
    
    # We use 'winget install' directly, which is native to Windows 11.
    # --accept-package-agreements: Auto-accepts licenses
    # --accept-source-agreements: Auto-accepts Store agreements
    # --scope machine: Installs for all users (usually better for home PCs)
    $process = Start-Process winget -ArgumentList "install --id $app --accept-package-agreements --accept-source-agreements --scope machine --disable-interactivity" -Wait -PassThru -NoNewWindow
    
    if ($process.ExitCode -eq 0) {
        Write-Host " [OK] $app installed successfully." -ForegroundColor Green
    } elseif ($process.ExitCode -eq -1978335189) {
        Write-Host " [SKIP] $app is already installed." -ForegroundColor Gray
    } else {
        Write-Host " [ERROR] $app failed with code $($process.ExitCode)." -ForegroundColor Red
    }
}

Write-Host "`n--- Setup Complete! ---" -ForegroundColor Cyan

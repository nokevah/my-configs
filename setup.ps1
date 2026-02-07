# setup.ps1 - The "Conflict Killer" Version
Write-Host "--- Starting Home Base Setup ---" -ForegroundColor Cyan

# 1. Admin Check
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Error "This script must be run as Administrator."
    return
}

# 2. CONFLICT FIX: Deep Clean Existing Modules
# The log showed "multiple locations" errors, so we must remove duplicates first.
$moduleName = "Microsoft.WinGet.DSC"
Write-Host "Checking for conflicting DSC modules..." -ForegroundColor Gray

# Unload from memory if active
Remove-Module $moduleName -ErrorAction SilentlyContinue

# Find and Uninstall ALL versions found on disk
$existingModules = Get-Module -ListAvailable -Name $moduleName
if ($existingModules) {
    foreach ($mod in $existingModules) {
        Write-Host " -> Removing conflict at: $($mod.ModuleBase)" -ForegroundColor Yellow
        Uninstall-Module -Name $moduleName -RequiredVersion $mod.Version -Force -ErrorAction SilentlyContinue
        
        # Failsafe: If Uninstall doesn't delete the folder, we force it
        if (Test-Path $mod.ModuleBase) {
            Remove-Item -Path $mod.ModuleBase -Recurse -Force -ErrorAction SilentlyContinue
        }
    }
}

# 3. Clean Install of the Module
Write-Host "Installing fresh Microsoft.WinGet.DSC module..." -ForegroundColor Yellow
Install-Module $moduleName -Force -AllowClobber -Scope CurrentUser -Repository PSGallery -ErrorAction Stop
Import-Module $moduleName -Force

# 4. Download Configuration
$rawUrl = "https://raw.githubusercontent.com/nokevah/my-configs/main/home-basics.dsc.yaml"
$tempPath = "$env:TEMP\home-basics.dsc.yaml"

try {
    Invoke-WebRequest -Uri $rawUrl -OutFile $tempPath -ErrorAction Stop
    Write-Host "Configuration downloaded." -ForegroundColor Gray
} catch {
    Write-Host "ERROR: Could not download configuration from GitHub." -ForegroundColor Red
    return
}

# 5. Execute with Logging
Write-Host "Applying configuration... (Interactivity Disabled)" -ForegroundColor White
$logFile = "$env:TEMP\winget_results.txt"

# Run winget configure
# Note: --disable-interactivity bypasses the 'Y' prompts that caused errors before
$output = winget configure -f $tempPath --accept-configuration-agreements --disable-interactivity 2>&1 | Tee-Object -FilePath $logFile

# 6. Report Results
if ($LASTEXITCODE -eq 0) {
    Write-Host "`n[SUCCESS] All apps installed correctly." -ForegroundColor Green
} else {
    Write-Host "`n[FAILURE] Errors occurred (Exit Code: $LASTEXITCODE)." -ForegroundColor Red
    Write-Host "Summary of failures:" -ForegroundColor Yellow
    # Filter output for readable errors
    $output | Where-Object { $_ -match "failed" -or $_ -match "error" -or $_ -match "available in multiple locations" } | ForEach-Object { Write-Host " -> $_" -ForegroundColor Red }
    Write-Host "`nFull log saved to: $logFile" -ForegroundColor Gray
}

# 7. Cleanup
if (Test-Path $tempPath) { Remove-Item $tempPath }

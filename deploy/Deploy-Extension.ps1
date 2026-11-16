<#
.SYNOPSIS
    Publishes, syncs and installs (or upgrades) the Mini Supermarket POS extension on a BC server.

.DESCRIPTION
    Run on the BC server in PowerShell as administrator, with the .app file built from this project:
        .\deploy\Deploy-Extension.ps1 -AppFile C:\deploy\MiniSupermarketPOS.app
        .\deploy\Deploy-Extension.ps1 -AppFile C:\deploy\MiniSupermarketPOS.app -UnpublishOld

    First time on a server: installs the app. Later: upgrades the installed version, keeping its data.
    Running it again with the same version does nothing harmful.

.PARAMETER UnpublishOld
    Afterwards, unpublish older versions of this app that are no longer installed.
#>
param(
    [Parameter(Mandatory = $true)][string]$AppFile,
    [string]$ServerInstance = 'BC290',
    [string]$Tenant = 'default',
    [string]$AdminTool = 'C:\Program Files\Microsoft Dynamics 365 Business Central\290\Service\NavAdminTool.ps1',
    [switch]$UnpublishOld
)

$ErrorActionPreference = 'Stop'
function Write-Step([string]$Text) { Write-Host "`n==> $Text" -ForegroundColor Cyan }
function Write-Ok([string]$Text) { Write-Host "    $Text" -ForegroundColor Green }

$id = [Security.Principal.WindowsIdentity]::GetCurrent()
if (-not (New-Object Security.Principal.WindowsPrincipal $id).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    throw 'Run this script in PowerShell as administrator.'
}
if (-not (Test-Path $AppFile)) { throw "App file not found: $AppFile" }
if (-not (Test-Path $AdminTool)) { throw "BC admin tool not found: $AdminTool. Pass -AdminTool with the right path." }
Import-Module $AdminTool -WarningAction SilentlyContinue | Out-Null

$app = Get-NAVAppInfo -Path $AppFile
$version = [version]$app.Version
Write-Step "$($app.Name) $version ($($app.Publisher)) on $ServerInstance"

# 1. Publish (skip if this exact version is already published).
$published = Get-NAVAppInfo -ServerInstance $ServerInstance -Id $app.AppId |
    Where-Object { [version]$_.Version -eq $version }
if ($published) {
    Write-Ok 'This version is already published.'
} else {
    Publish-NAVApp -ServerInstance $ServerInstance -Path $AppFile -SkipVerification
    Write-Ok 'Published.'
}

# 2. Sync the database schema for this version.
Sync-NAVApp -ServerInstance $ServerInstance -Name $app.Name -Publisher $app.Publisher -Version $version -Tenant $Tenant
Write-Ok 'Schema synced.'

# 3. Install, or upgrade the installed older version.
$installed = Get-NAVAppInfo -ServerInstance $ServerInstance -Id $app.AppId -Tenant $Tenant -TenantSpecificProperties |
    Where-Object { $_.IsInstalled }
if (-not $installed) {
    Install-NAVApp -ServerInstance $ServerInstance -Name $app.Name -Publisher $app.Publisher -Version $version -Tenant $Tenant
    Write-Ok 'Installed.'
} elseif ([version]$installed.Version -lt $version) {
    Start-NAVAppDataUpgrade -ServerInstance $ServerInstance -Name $app.Name -Publisher $app.Publisher -Version $version -Tenant $Tenant
    Write-Ok "Upgraded from $($installed.Version)."
} elseif ([version]$installed.Version -eq $version) {
    Write-Ok 'This version is already installed.'
} else {
    throw "A newer version ($($installed.Version)) is installed. Build a higher version number than that."
}

# 4. Optionally remove older published versions.
if ($UnpublishOld) {
    Get-NAVAppInfo -ServerInstance $ServerInstance -Id $app.AppId |
        Where-Object { [version]$_.Version -lt $version } |
        ForEach-Object {
            Unpublish-NAVApp -ServerInstance $ServerInstance -Name $_.Name -Publisher $_.Publisher -Version $_.Version
            Write-Ok "Unpublished old version $($_.Version)."
        }
}

Write-Step 'Done'
Get-NAVAppInfo -ServerInstance $ServerInstance -Id $app.AppId -Tenant $Tenant -TenantSpecificProperties |
    Format-Table Name, Version, IsInstalled, SyncState -AutoSize
Write-Host @"
    Check in BC: Web Services lists POSStaffPortal (codeunit 50171) and POSPortalTill (codeunit 50180), Published.
    The portal's service user needs the permission sets POS PORTAL API and POS PORTAL TILL.
"@

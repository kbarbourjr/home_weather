<#
Interactive upload helper (local-only)

Prompts for WiFi SSID and Password (password entered securely), sets them
as session environment variables, builds and uploads the firmware, then
clears the sensitive variables from the session.

Usage:
  .\scripts\upload_with_creds.ps1
  .\scripts\upload_with_creds.ps1 -Port COM4

Note: This file should NOT be committed. It's added to .gitignore by the
repository helper.
#>

param(
    [string]$Port
)

function Get-PlatformIOExecutable {
    if (Get-Command pio -ErrorAction SilentlyContinue) { return 'pio' }
    $localPio = Join-Path $env:USERPROFILE ".platformio\penv\Scripts\platformio.exe"
    if (Test-Path $localPio) { return $localPio }
    Write-Error "PlatformIO CLI ('pio') not found. Install PlatformIO or add to PATH."
    exit 2
}

function Find-CP210xPort {
    try {
        $dev = Get-PnpDevice -PresentOnly | Where-Object { $_.FriendlyName -match 'CP210|Silicon Labs|USB to UART|USB Serial' } | Select-Object -First 1
        if ($dev -and $dev.FriendlyName -match 'COM(\d+)') { return "COM$($Matches[1])" }
    } catch {}
    $ports = [System.IO.Ports.SerialPort]::GetPortNames()
    if ($ports.Length -eq 1) { return $ports[0] }
    return $null
}

$pio = Get-PlatformIOExecutable

# Prompt for credentials
$ssid = Read-Host "WiFi SSID"
$securePass = Read-Host "WiFi Password" -AsSecureString

# Convert secure string to plain for session use
$bstr = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($securePass)
$plainPass = [System.Runtime.InteropServices.Marshal]::PtrToStringBSTR($bstr)
[System.Runtime.InteropServices.Marshal]::ZeroFreeBSTR($bstr)

if (-not $Port) { $Port = Find-CP210xPort }
if (-not $Port) {
    Write-Host 'No COM port detected automatically. Please supply -Port COM# and re-run.' -ForegroundColor Yellow
    exit 1
}

Write-Host "Using port: $Port"

# Set session env vars
$env:WIFI_SSID = $ssid
$env:WIFI_PASS = $plainPass

Write-Host 'Building project...'
& $pio run
if ($LASTEXITCODE -ne 0) { Write-Error 'Build failed.'; Remove-Item Env:WIFI_PASS -ErrorAction SilentlyContinue; Remove-Item Env:WIFI_SSID -ErrorAction SilentlyContinue; exit $LASTEXITCODE }

Write-Host "Uploading to $Port..."
& $pio run -e nodemcu-32s --target upload --upload-port $Port
$exitCode = $LASTEXITCODE

# Clear sensitive variables
Remove-Item Env:WIFI_PASS -ErrorAction SilentlyContinue
Remove-Item Env:WIFI_SSID -ErrorAction SilentlyContinue
$plainPass = ""
$securePass = $null

if ($exitCode -ne 0) { Write-Error "Upload failed (exit $exitCode)"; exit $exitCode }

Write-Host 'Upload complete.'

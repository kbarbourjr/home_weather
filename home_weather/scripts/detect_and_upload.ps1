<#
Detect and upload helper for PlatformIO (Windows PowerShell)

Usage examples:
  # Auto-detect CP210x COM port and upload
  .\scripts\detect_and_upload.ps1

  # Specify an explicit COM port
  .\scripts\detect_and_upload.ps1 -Port COM4

  # Build only
  .\scripts\detect_and_upload.ps1 -BuildOnly

  # Upload and open serial monitor after upload
  .\scripts\detect_and_upload.ps1 -Monitor
#>

param(
    [string]$Port,
    [string]$Env = 'nodemcu-32s',
    [string]$Ssid,
    [string]$Pass,
    [switch]$BuildOnly,
    [switch]$Monitor
)

function Get-PlatformIOExecutable {
    if (Get-Command pio -ErrorAction SilentlyContinue) {
        return 'pio'
    }
    $localPio = Join-Path $env:USERPROFILE ".platformio\penv\Scripts\platformio.exe"
    if (Test-Path $localPio) { return $localPio }
    Write-Error "PlatformIO CLI ('pio') not found in PATH and not at $localPio. Install PlatformIO or update PATH."
    exit 2
}

function Find-CP210xPort {
    Write-Host 'Looking for CP210x / Silicon Labs USB-UART devices...'
    try {
        $dev = Get-PnpDevice -PresentOnly | Where-Object { $_.FriendlyName -match 'CP210|Silicon Labs|USB to UART|USB Serial' } | Select-Object -First 1
        if ($dev -and $dev.FriendlyName) {
            if ($dev.FriendlyName -match 'COM\d+') { return ($Matches[0]) }
        }
    } catch {
        # Get-PnpDevice may require elevated privileges on some systems
    }

    Write-Host 'Fallback: listing system COM ports...'
    try {
        $ports = [System.IO.Ports.SerialPort]::GetPortNames()
        if ($ports.Length -eq 1) { return $ports[0] }
        if ($ports.Length -gt 1) {
            Write-Host "Multiple COM ports found: $($ports -join ', ')"
            Write-Host 'Please re-run with -Port COM# to pick the correct device.'
            return $null
        }
    } catch {
        Write-Host 'Unable to list COM ports.'
    }
    return $null
}

$pio = Get-PlatformIOExecutable

if (-not $Port) { $Port = Find-CP210xPort }

# If SSID/PASS were provided to the script, set them as session env vars
if ($Ssid) {
    Write-Host "Setting WIFI_SSID from parameter"
    $env:WIFI_SSID = $Ssid
}
if ($Pass) {
    Write-Host "Setting WIFI_PASS from parameter"
    $env:WIFI_PASS = $Pass
}

if (-not $Port) {
    Write-Host 'No COM port detected. Provide -Port COM# (e.g. -Port COM4) and rerun.' -ForegroundColor Yellow
    exit 1
}

Write-Host "Using port: $Port"

Write-Host 'Showing PlatformIO device list:'
& $pio device list

Write-Host 'Building project...'
& $pio run
if ($LASTEXITCODE -ne 0) { Write-Error 'Build failed.'; exit $LASTEXITCODE }

if ($BuildOnly) { Write-Host 'Build-only requested; exiting.'; exit 0 }

Write-Host "Uploading to environment '$Env' on port $Port..."
& $pio run -e $Env --target upload --upload-port $Port
if ($LASTEXITCODE -ne 0) { Write-Error "Upload failed (exit $LASTEXITCODE). Try the manual BOOT sequence: hold BOOT (GPIO0), press EN, release BOOT while running upload."; exit $LASTEXITCODE }

if ($Monitor) {
    Write-Host 'Opening serial monitor... (Ctrl+C to quit)'
    & $pio device monitor -p $Port -b 115200
}

Write-Host 'Done.'

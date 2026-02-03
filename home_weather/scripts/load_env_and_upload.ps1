# Loads .env in project root and runs PlatformIO upload for nodemcu-32s
# Usage: Copy .env.example -> .env, fill values, then run this script from PowerShell

$envFile = Join-Path $PSScriptRoot "..\.env" | Resolve-Path -ErrorAction SilentlyContinue
if (-not $envFile) {
    Write-Error "No .env file found in project root. Copy .env.example -> .env and fill in values."
    exit 1
}

# Read .env lines like KEY=VALUE
Get-Content $envFile | ForEach-Object {
    if ($_ -and ($_ -notmatch '^#')) {
        $parts = $_ -split '=', 2
        if ($parts.Length -eq 2) {
            $name = $parts[0].Trim()
            $value = $parts[1].Trim()
            Set-Item -Path Env:\$name -Value $value
        }
    }
}

# Run PlatformIO upload
Write-Host "Environment loaded. Running PlatformIO upload..."
pio run -e nodemcu-32s --target upload

# Clear the env vars from the session
Get-Content $envFile | ForEach-Object {
    if ($_ -and ($_ -notmatch '^#')) {
        $parts = $_ -split '=', 2
        if ($parts.Length -eq 2) {
            $name = $parts[0].Trim()
            Remove-Item -Path Env:\$name -ErrorAction SilentlyContinue
        }
    }
}
Write-Host "Upload finished; environment variables cleared from session."
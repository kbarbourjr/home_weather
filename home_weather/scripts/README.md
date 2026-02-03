# Scripts

This folder contains local helper scripts for development and device upload.

Important: do NOT commit secrets. Use `.env` (ignored) or environment variables.

Files
- `load_env_and_upload.ps1` — Loads a `.env` file from the project root, sets the variables in the current PowerShell session, runs PlatformIO upload for the `nodemcu-32s` environment, then clears the variables from the session.
- `upload_with_creds.ps1` — (interactive) prompts for WiFi credentials and runs an upload; this file may contain sensitive input so it's listed in `.gitignore`.

Quick start

1. Copy the example file:

```powershell
Copy-Item .env.example .env
```

2. Edit `.env` and fill `WIFI_SSID` and `WIFI_PASS`.

3. Run the helper (from project root):

```powershell
.\scripts\load_env_and_upload.ps1
```

This will set the env vars for the session, run `pio run -e nodemcu-32s --target upload`, and then remove the variables from the session.

If you prefer to set variables manually in PowerShell for a single session:

```powershell
$env:WIFI_SSID = "YourSSID"
$env:WIFI_PASS = "YourPass"
pio run -e nodemcu-32s --target upload
Remove-Item Env:\WIFI_SSID, Env:\WIFI_PASS
```

Notes
- The project reads `WIFI_SSID` and `WIFI_PASS` as build flags via PlatformIO; do not commit real credentials.
- `.env` is in `.gitignore`.
# Scripts

This folder contains helper scripts for local development and deployment.

## detect_and_upload.ps1

Purpose: detect the CP210x USB-to-UART adapter (or user-specified COM port), build the project with PlatformIO, upload to the ESP32, and optionally open the serial monitor.

Prerequisites:
- Windows PowerShell
- PlatformIO CLI available as `pio` or via the local PlatformIO penv at `%USERPROFILE%\.platformio\penv\Scripts\platformio.exe`

Usage examples (run from the project root):

```powershell
.\scripts\detect_and_upload.ps1            # auto-detect COM, build, upload
.\scripts\detect_and_upload.ps1 -Port COM4 -Monitor  # use COM4 and open serial monitor after upload
.\scripts\detect_and_upload.ps1 -BuildOnly           # build only
.\scripts\detect_and_upload.ps1 -Ssid "MY_SSID" -Pass "MY_PASS"  # set credentials for this run

Tip: provide `-Ssid` and `-Pass` to the script to set local credentials for the upload session. Alternatively, set `WIFI_SSID` and `WIFI_PASS` environment variables in your shell before running the script.
```

Notes & troubleshooting:
- If multiple COM ports exist, pass `-Port COM#` to avoid ambiguity.
- If upload fails with "Wrong boot mode", perform the manual BOOT sequence:
  - Hold `BOOT` (GPIO0), press-and-release `EN` (Reset), release `BOOT`, then re-run upload.
- Stop any open serial monitor before running upload to avoid port busy errors.

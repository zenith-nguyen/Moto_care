param(
    [ValidatePattern('^emulator-[0-9]+$')]
    [string]$Serial = 'emulator-5554',
    [ValidateRange(2, 60)]
    [int]$IntervalSeconds = 10,
    [ValidateRange(10, 1000)]
    [int]$MaxAccuracyMeters = 250,
    [switch]$Once,
    [switch]$DryRun
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

if ($env:OS -ne 'Windows_NT') {
    throw 'This developer helper requires Windows Location Services.'
}

$adbPath = Join-Path $env:LOCALAPPDATA 'Android\Sdk\platform-tools\adb.exe'
if (-not $DryRun -and -not (Test-Path -LiteralPath $adbPath -PathType Leaf)) {
    throw "ADB was not found at $adbPath. Install Android SDK Platform-Tools first."
}

Add-Type -AssemblyName System.Device
$watcher = [System.Device.Location.GeoCoordinateWatcher]::new(
    [System.Device.Location.GeoPositionAccuracy]::High
)

try {
    if (-not $watcher.TryStart($false, [TimeSpan]::FromSeconds(10))) {
        throw 'Windows Location did not start. Enable Location services and desktop app access in Windows Settings.'
    }

    if (-not $DryRun) {
        $devices = & $adbPath devices
        if ($LASTEXITCODE -ne 0 -or -not ($devices -match "^$([regex]::Escape($Serial))\s+device$")) {
            throw "Emulator $Serial is not online. Start it and wait until adb devices shows 'device'."
        }
    }

    Write-Host 'Syncing Windows location to Android Emulator. Press Ctrl+C to stop.'
    while ($true) {
        $deadline = (Get-Date).AddSeconds(20)
        while ($watcher.Position.Location.IsUnknown -and (Get-Date) -lt $deadline) {
            Start-Sleep -Milliseconds 500
        }

        $position = $watcher.Position
        $point = $position.Location
        if ($point.IsUnknown) {
            throw 'Windows has no current location. Check Location services, Wi-Fi and desktop app access.'
        }
        if ([double]::IsNaN($point.HorizontalAccuracy) -or
            $point.HorizontalAccuracy -gt $MaxAccuracyMeters) {
            throw "Windows location accuracy is too low ($([math]::Round($point.HorizontalAccuracy)) m). No GPS fix was sent."
        }
        if ($position.Timestamp -eq [DateTimeOffset]::MinValue -or
            ([DateTimeOffset]::UtcNow - $position.Timestamp.ToUniversalTime()).TotalSeconds -gt 60) {
            throw 'Windows location is stale. No GPS fix was sent.'
        }

        # Development safety: do not silently replace a Vietnamese test location
        # with a coarse location returned for another country.
        if ($point.Latitude -lt 8 -or $point.Latitude -gt 24 -or
            $point.Longitude -lt 102 -or $point.Longitude -gt 110) {
            throw 'Windows location is outside Vietnam. No GPS fix was sent.'
        }

        if (-not $DryRun) {
            $longitude = $point.Longitude.ToString('F7', [Globalization.CultureInfo]::InvariantCulture)
            $latitude = $point.Latitude.ToString('F7', [Globalization.CultureInfo]::InvariantCulture)
            & $adbPath -s $Serial emu geo fix $longitude $latitude | Out-Null
            if ($LASTEXITCODE -ne 0) {
                throw "Could not set GPS on $Serial. Check that the emulator is still online."
            }
        }

        $action = if ($DryRun) { 'Windows location available' } else { "GPS updated on $Serial" }
        Write-Host "$action (accuracy $([math]::Round($point.HorizontalAccuracy)) m)."
        if ($Once) { break }
        Start-Sleep -Seconds $IntervalSeconds
    }
}
finally {
    $watcher.Stop()
    $watcher.Dispose()
}

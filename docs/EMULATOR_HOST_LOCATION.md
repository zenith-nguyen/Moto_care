# Use the Windows location in Android Emulator (development only)

The emulator has its own simulated GPS. It does not automatically inherit the
Windows location. This helper reads Windows Location Services and sends a GPS
fix to one running emulator every 10 seconds. It does not change the production
Flutter app or grant it background location access.

From PowerShell in the Flutter repository root:

```powershell
Set-Location D:\mobile_app_motocare\mobilecare_1
powershell -NoProfile -File .\tool\sync_emulator_location.ps1 -DryRun -Once
powershell -NoProfile -File .\tool\sync_emulator_location.ps1
```

Start the emulator before the second command. Leave this PowerShell window open
while testing, and press `Ctrl+C` when finished. If `adb devices` reports an ID
other than `emulator-5554`, pass `-Serial emulator-5556` (using the actual ID).

In Windows Settings, enable **Privacy & security → Location → Location
services** and **Let desktop apps access your location**. Windows may estimate
the location from Wi-Fi or the network rather than a GPS chip. Check the
reported accuracy: a result around 100 m is not reliable for an exact house
number. If Windows supplies no position, a stale position, accuracy worse than
250 m, or a position outside Vietnam, the script stops without changing the
emulator. Use the emulator's `… → Location → Set location` for an exact test
address or route.

The script keeps coordinates local to Windows and the emulator. It does not
print or store coordinates and never sends them to the MotoCare backend itself.
Apps running in the emulator may read the simulated location when permission
is granted. A physical Android phone uses its own Location Services instead.

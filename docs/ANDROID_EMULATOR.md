# Android emulator development

The supported local Android toolchain is JDK 21. JDK 25 can start Gradle, but
on memory-constrained Windows machines it has caused Kotlin daemon disconnects
and slow fallback builds.

## One-time setup

```powershell
flutter config --jdk-dir="C:\Program Files\Java\jdk-21"
flutter doctor --android-licenses
```

The `Medium_Phone` AVD uses the Android 34 Google Play image. If Gboard is not
listed under Android **Settings → System → Keyboard → On-screen keyboard**,
open Play Store inside the emulator, install or update **Gboard**, then select:

**Gboard → Languages → Add keyboard → Vietnamese → Telex**.

The Extended Controls window shown by the emulator is not Android Settings;
keyboard languages do not appear there.

## Recover an offline emulator

Close any failed emulator window, then run:

```powershell
$sdk = "$env:LOCALAPPDATA\Android\Sdk"
& "$sdk\platform-tools\adb.exe" kill-server
& "$sdk\platform-tools\adb.exe" start-server
& "$sdk\emulator\emulator.exe" `
  -avd Medium_Phone `
  -no-snapshot-load `
  -gpu swiftshader_indirect `
  -memory 1536 `
  -cores 2
```

Wait until Android reaches its home screen. In a second PowerShell window:

```powershell
adb devices
flutter run -d emulator-5554 `
  --dart-define=API_BASE_URL=https://your-origin.example
```

Do not run Flutter while `adb devices` reports `offline`. Do not wipe AVD data
unless a cold boot also fails; wiping removes installed apps and settings.

## Memory

Before launching the emulator, keep at least 2 GB physical RAM available.
Gradle and Kotlin daemons from unrelated projects can consume several GB. The
project limits Gradle to one worker and compiles Kotlin in-process so a normal
build does not create a second large compiler daemon.

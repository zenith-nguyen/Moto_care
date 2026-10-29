# Android releases

## Release conditions

1. `main` is clean, reviewed, and all required GitHub Actions checks pass.
2. Update `version:` in `pubspec.yaml` using `MAJOR.MINOR.PATCH+BUILD`, then merge that pull request into `main`.
3. Create a tag matching the first three parts of the version. For example, version `1.2.0+15` uses tag `v1.2.0`.

```bash
git switch main
git pull --ff-only origin main
git tag -a v1.2.0 -m "Release v1.2.0"
git push origin v1.2.0
```

Pushing the tag starts the `Release Android` workflow. It validates the tag and version, builds the customer and provider release APKs, uploads an artifact, and creates a GitHub Release with both APKs attached.

## Backend URL

Release builds refuse to start without an HTTPS `API_BASE_URL`, so the workflow reads the `API_BASE_URL` repository variable (Settings > Secrets and variables > Actions > Variables) and fails early when it is missing.

A published APK exposes the backend URL it was built with. On a public repository, only tag a release once that backend is meant to be reachable by anyone who downloads the APK.

## Signing

`android/app/build.gradle.kts` reads `android/key.properties` (git-ignored; see `android/key.properties.example`) and signs release builds with that keystore. When the file or the keystore is missing, the release build falls back to the debug keystore: fine for sideloading, not accepted by Google Play. Never commit a keystore or its password.

Create the upload keystore once, store it outside the repository and back it up, because losing it means the app can no longer be updated on Play:

```bash
keytool -genkeypair -v -keystore ../revo-release.jks -storetype JKS \
  -keyalg RSA -keysize 2048 -validity 10000 -alias revo
```

## Google Play

The repository does not yet contain the Play Console service account needed to publish automatically.

Before the first Play Store release, add the following GitHub Secrets and update the Android release configuration to consume them only in CI:

| Secret | Value |
| --- | --- |
| `ANDROID_KEYSTORE_BASE64` | Base64-encoded upload keystore |
| `ANDROID_KEY_ALIAS` | Key alias |
| `ANDROID_KEY_PASSWORD` | Key password |
| `ANDROID_STORE_PASSWORD` | Keystore password |

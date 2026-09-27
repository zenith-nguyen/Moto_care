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

Pushing the tag starts the `Release Android` workflow. It validates the tag and version, builds the release APK, uploads an artifact, and creates a GitHub Release with the APK attached.

## Google Play signing

The repository does not yet contain the signing configuration or Play Console service account needed to publish to Google Play. Never commit a keystore or its password.

Before the first Play Store release, add the following GitHub Secrets and update the Android release configuration to consume them only in CI:

| Secret | Value |
| --- | --- |
| `ANDROID_KEYSTORE_BASE64` | Base64-encoded upload keystore |
| `ANDROID_KEY_ALIAS` | Key alias |
| `ANDROID_KEY_PASSWORD` | Key password |
| `ANDROID_STORE_PASSWORD` | Keystore password |

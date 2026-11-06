# Contributing to LokeshMusic

Thank you for considering contributing to this project! We welcome and
appreciate all contributions.

## Getting started

1. Fork the repository and clone it locally.
2. Create a new branch for your changes.
3. Install [Flutter](https://docs.flutter.dev/get-started/install) 3.47.7 or
   newer (stable channel) and Java 17.
4. Run `flutter pub get`.
5. Make your changes and test them thoroughly.
6. Run the checks below before opening a pull request.
7. Commit your changes and push them to your fork.
8. Open a pull request and describe your changes.

## Local checks

```bash
flutter analyze --no-fatal-infos
flutter test
flutter build apk --release --flavor github
```

The release APK is written to
`build/app/outputs/flutter-apk/app-github-release.apk`. Release builds need
`android/key.properties` and a keystore to be signed; without them the build
falls back to debug signing for local testing.

## Code of Conduct

All contributors are expected to abide by our code of conduct. Please make sure
to read and understand the
[code of conduct](https://github.com/lokesh12dev/Lokeshmusic/blob/master/CODE_OF_CONDUCT.md)
before making a contribution.

## Code Reviews

All pull requests will be reviewed by at least one project maintainer. Please
be patient and willing to make changes based on feedback.

## Attribution

By contributing to this project, you agree to allow your contributions to be
used and distributed under the project's license (GPL v3).

## Questions

If you have any questions about contributing, please open a discussion on
GitHub.

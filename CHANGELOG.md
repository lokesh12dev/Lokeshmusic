# Changelog

All notable changes to LokeshMusic are documented here. The format is based on
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and this project
follows [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [10.6.0] — 2026-11-05

### Added

- Spotify-inspired dark UI built on Material 3, with an accent-green palette
  and neutral dark surfaces.
- Responsive desktop shell for windows and tablets at widths ≥ 900 px,
  including a sidebar and now-playing bar.
- Pure black theme option for OLED displays.
- Theme mode, accent color, audio quality, and equalizer controls in Settings.
- Arm64 and universal signed APK releases served from GitHub Releases.
- `SHA256SUMS.txt` checksums published with every release.
- In-app update check that reads GitHub Releases and picks the build that
  matches the device architecture.

### Changed

- Fluent icon usage on the main navigation and Settings screens replaced with
  Material icons.
- Dark theme is now the default for new installs.
- Startup work overlaps app-directory resolution with audio-service setup,
  and dynamic color is only queried when the option is enabled.
- Release builds are signed with the LokeshMusic release key; unsigned local
  builds fall back to debug signing for testing only.

### Fixed

- Update checks now point at the correct repository and no longer require the
  legacy `check.json` endpoint.
- Proxy fallback attempts are bounded so a failed stream resolution no longer
  leaves the player stuck for an extended period.

## [10.5.0] and earlier

See the commit history and the GitHub Releases page for notes on earlier
versions.

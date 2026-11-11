# Changelog

All notable changes to this chart are documented here. The format follows
[Keep a Changelog](https://keepachangelog.com) and the chart follows
[Semantic Versioning](https://semver.org/).

## [0.0.39] - 2026-11-11

### Changed

- Bundled app image updated to 0.17.1.

## [0.0.38] - 2026-11-06

### Changed

- Bundled app image updated to 0.17.0 (first image built to run as non-root uid/gid 1000).

### Security

- Pods now run non-root by default (`twigex.pod.securityContext`: `runAsNonRoot: true`, uid/gid 1000, `fsGroup: 1000` with `fsGroupChangePolicy: OnRootMismatch`, RuntimeDefault seccomp; container: no privilege escalation, all capabilities dropped). Override by setting `twigex.pod.securityContext`/`containerSecurityContext` to a non-empty map.

### Added

- Opt-in `twigex.pod.dataInit.enabled` (default `false`): a `data-init` init container that chowns `/app/data` to 1000:1000 when needed. Use once when upgrading from pre-0.0.38 releases whose PVC data was written by root.
- Documentation for the non-root migration added across `README.md` (new DataInit section), `INSTALLATION.md` (upgrade guide with enable/disable commands), and the troubleshooting playbook (Permission denied crashloop after non-root upgrade).
- Documented the LiveKit server compatibility requirement: Twigex app 0.17.0+ needs LiveKit server 1.9.10+; video calls fail to connect on LiveKit 1.9.9 or older.

## [0.0.37] - 2026-10-15

### Changed

- Bundled app image updated to 0.16.0.
- Fixed chart source link (`twigex/helm-charts` → `twigex/twigex-helm-chart`) and documentation link (now `twigex.com/docs`).
- `.helmignore` now excludes local build artifacts (`rendered.yaml`, `packaged/`) from packaged charts.

## [0.0.36] - 2026-10-13

### Changed

- Version-bump release: no chart or values changes; documentation and issue templates updated to reference 0.0.36.

## [0.0.35] - 2026-10-13

### Added

- Initial release.

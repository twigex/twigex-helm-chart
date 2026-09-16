# Changelog

All notable changes to this chart are documented here. The format follows
[Keep a Changelog](https://keepachangelog.com) and the chart follows
[Semantic Versioning](https://semver.org/).

## [Unreleased]

### Added

- **Public-repo community & CI files.** `SECURITY.md` (private
  vulnerability reporting + secret-sanitization rules),
  `CONTRIBUTING.md` (test procedure, chart rules, PR process),
  `CODE_OF_CONDUCT.md`, GitHub issue templates (bug/question/feature),
  PR template, CI workflow (`lint-render.yaml`: lint + render across
  embedded/external MariaDB, ingress/TLS, Gateway API, and Cube paths),
  release workflow (`release.yaml`: tag-guarded `helm push` to
  GHCR), `artifacthub-repo.yml` (repositoryID TODO until the repo is
  registered on Artifact Hub), and `examples/values-prod-example.yaml`
  (secret-free production values: ingress + cert-manager TLS +
  external MariaDB). Fixed `artifacthub.io/license` annotation:
  Apache-2.0 → MIT, matching `LICENSE.txt`.

### Fixed

- **Pre-publish tidy-up.** Replaced stale `<sanitized-domain>` pod-label
  references in `AGENTS.md`, `README.md`, `SKILL.md`, `INSTALLATION.md`
  with `<release>-twigex` (the actual pod label). Removed the dead
  `chart.sanitizedDomain` helper from `templates/_helpers.tpl`. Pruned
  stale `mariadb-operator` and `mariadb-operator-crds` entries from
  `Chart.lock` (they were no longer in `Chart.yaml`'s `dependencies`).
  Removed misleading `Chart.yaml` version comment. Dropped the
  `cube.dbType` knob and the chart's `CUBEJS_DB_TYPE` env override —
  Cube.js's image defaults `CUBEJS_DB_TYPE=postgres` out of the box,
  matching the project's own `cloud-go/deploy/cube/docker-compose.yml`
  pattern (`CUBEJS_DB_TYPE: ${CUBEJS_DB_TYPE:-postgres}`). Mentions of
  `<sanitized-domain>` referring to the cert-manager TLS Secret naming
  convention are kept intact.

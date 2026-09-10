# Changelog

All notable changes to this chart are documented here. The format follows
[Keep a Changelog](https://keepachangelog.com) and the chart follows
[Semantic Versioning](https://semver.org/).

## [Unreleased]

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

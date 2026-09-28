# Contributing to the Twigex Helm Chart

Thanks for contributing! This chart is under active development, and
pragmatic, tested changes are very welcome.

## Before you start

- **Search existing issues first** — your bug or feature may already be tracked.
- For usage questions, please use [GitHub Discussions](../../discussions) or
  [r/twigex](https://www.reddit.com/r/twigex/) instead of opening an issue.

## Development setup

You need:

- **Helm v3.8.0+** (`helm version`)
- **kubectl** access to any test cluster (a single-node k3s is enough)
- A default `StorageClass` in that cluster

The chart is plain YAML + Go templates — no build step.

## Testing your change

Every pull request must pass these locally before review:

```sh
# 1. Lint
helm lint .

# 2. Render with realistic values (the chart validator hard-fails without
#    the required ones)
helm template test . \
  --set domain=example.com \
  --set twigex.admin.password=test-password \
  --set twigex.server.encryptKey=$(openssl rand -hex 16) \
  --set redis.auth.password=test-redis \
  --set mariadb.password=test-db \
  --set mariadb.rootPassword=test-root > /tmp/render.yaml

# Inspect the render for regressions
grep -C3 <thing-you-changed> /tmp/render.yaml

# 3. Dry-run install
helm install test . --dry-run \
  --set domain=example.com \
  --set twigex.admin.password=test-password \
  --set twigex.server.encryptKey=$(openssl rand -hex 16) \
  --set redis.auth.password=test-redis \
  --set mariadb.password=test-db \
  --set mariadb.rootPassword=test-root
```

If your change touches MariaDB modes, ingress, or the Cube stack,
also render those paths (e.g. `--set mariadb.mode=external`,
`--set ingress.enabled=true,ingress.tls.enabled=true`,
`--set cube.enabled=true,cube.apiSecret=x,cube.callbackSecret=y`).
Real `helm install` + `kubectl get all` verification on a test cluster is
expected for anything that changes rendered resources.

## Rules of the chart

These keep the chart usable in GitOps (ArgoCD) environments — violations
will be requested in review:

1. **No secrets in committed values files.** Use `--set`, a git-ignored
   file, or an external secrets manager. Never commit real passwords,
   keys, or API secrets.
2. **No `lookup()` and no random generation** (`randAlphaNum`, ...) in
   templates. They break ArgoCD diff/ServerSideApply. All values must be
   explicit (user-provided or static defaults).
3. **Breaking-change values must be documented.** If you rename, remove,
   or change the semantics of a values key, update `README.md`,
   `INSTALLATION.md`, and `CHANGELOG.md` in the same PR.
4. **High-risk values need maintainer sign-off.** Changes touching
   `domain`, `mariadb.password`, or `twigex.server.encryptKey` semantics
   are flagged as high risk.

## Submitting a pull request

- Keep one logical change per PR.
- Update the `## [Unreleased]` section of `CHANGELOG.md` describing the
  change.
- If you added or changed a values key, document it in the README
  configuration table (and `values.schema.json` if applicable).
- Fill in the PR template checklist.
- CI must be green (lint + render across the main value combinations).

## Releasing (maintainers)

Releases publish the chart as an OCI artifact to
`ghcr.io/twigex/helm-charts/twigex` — see
`.github/workflows/release.yaml`. Bump `version` in `Chart.yaml`, move
`CHANGELOG.md` `[Unreleased]` entries into the new version section, and
tag the release.

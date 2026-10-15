# AGENTS.md — Twigex Helm Chart

This repo manages a Kubernetes deployment of the Twigex app via its Helm chart. This file gives AI coding agents (Claude Code, etc.) the context needed to work safely in this project.

## What this project is

Twigex is deployed with a Helm chart published as an OCI artifact:

```
oci://ghcr.io/twigex/helm-charts/twigex
```

No `helm repo add` is needed — it's pulled directly by OCI reference;

Stack components (all optional except Twigex + one DB mode + Redis):

- **Twigex** — the app itself (required)
- **MariaDB** — one of 2 modes: `embedded` (chart deploys and owns MariaDB) or `external` (user manages MariaDB and points `twigex.db.host` at it)
- **Redis** — required, deployed as a subchart
- **LiveKit** — optional, *deployed separately*; this chart only configures the Twigex app client side (`twigex.channel.*`) for voice/video
- **EuroOffice** or **Collabora** — optional, *deployed separately*; this chart only configures the Twigex app client side (`twigex.office.*`) for office document editing (WOPI)
- **Ingress** — opt-in (`ingress.enabled=true`), off by default

## Repo layout conventions

> ⚠️ **Proposed layout — not yet adopted in this repo.** Current state: single root `values.yaml` + `INSTALLATION.md`. Agents may propose this layout but must confirm with the user before creating any of these directories.

Agents should expect (or create) a layout like:

```
.
├── AGENTS.md
├── values/
│   ├── values-base.yaml        # shared, non-secret config
│   ├── values-prod.yaml        # env-specific overrides
│   └── values-dev.yaml
├── secrets/                    # NEVER commit real secrets here — see below
│   └── .gitkeep
└── scripts/
    ├── install.sh
    ├── upgrade.sh
    └── verify.sh
```

If this layout doesn't exist yet, agents may propose it but should confirm with the user before restructuring existing files.

## Critical rules — read before editing anything

1. **Never commit real passwords, encrypt keys, or API secrets** to values files that get checked into git. Use `--set` at install time, an external secret manager (Vault / External Secrets Operator), or a git-ignored local values file.
2. **`twigex.server.encryptKey` is immutable in practice.** It's exactly 32 hex chars (`openssl rand -hex 16`). Rotating it after go-live invalidates all encrypted data in the DB. Never regenerate it in an upgrade script.
3. **`mariadb.password` cannot be changed after first boot** with embedded MariaDB without reinitializing the DB (data loss). Treat it as a one-time-set value.
4. **Ingress is opt-in.** Don't assume `ingress.enabled=true`; check the values file before assuming the app is externally reachable.
5. **All chart-owned resources are prefixed with `<Release.Name>`.** The app Deployment is `<release>-twigex`, mariadb (in embedded mode) is `<release>-mariadb-deployment`, cube resources are `<release>-cube-api`, `<release>-cube-router`, `<release>-cube-worker-1`, etc. The app Service is bare `<release>` (matches the `Service: {{ .Release.Name }}` convention). The MariaDB mode is selected via `mariadb.mode` (`embedded | external`); the chart renders no MariaDB resources when `mode=external`. To find every resource for one install:
   ```
   kubectl get all -l app.kubernetes.io/instance=<release> -n <namespace>
   ```
   Plus the same-named ConfigMap, Secret, PVC, etc. Do not hardcode different service names — update every reference if the release name changes.
6. **`twigex.db.host`** is only consulted when `mariadb.mode=external` (in any other mode, the host is auto-derived from `<release>-mariadb`). The legacy `twigex.redis.address` and `twigex.redis.password` keys were removed when `redis.*` was collapsed into `redis.auth.password`; don't re-add them — set `redis.auth.password` instead and the chart will derive everything else.
7. **No `lookup()` calls and no random generation (`randAlphaNum`, `randAlpha`, etc.) in chart templates.** Both break ArgoCD's diff/ServerSideApply and cause perpetual "diff detected" syncs. All values must be explicit — user-provided via `--set` or values file, or static defaults in `values.yaml`. No cluster lookups, no in-template password/key generation.

## Common agent tasks

### Install
Use the mode-specific command from INSTALLATION.md. Always require: `domain`, `twigex.admin.password`, `twigex.server.encryptKey`, `redis.auth.password`, `mariadb.password`. Additionally, `mariadb.rootPassword` is required for `mariadb.mode=embedded` (skipped for `mode=external`). For `mode=external` you also need to set `twigex.db.host` to a real endpoint — the default `127.0.0.1` is rejected by the validator. See INSTALLATION.md.

### Upgrade
```sh
helm upgrade twigex oci://ghcr.io/twigex/helm-charts/twigex \
  --namespace twigex -f your-values.yaml
```
Always check the chart's Changelog for breaking changes before upgrading, especially around the database backend.

### Verify health
```sh
kubectl get pods -n twigex
kubectl get svc -n twigex
kubectl logs -n twigex -l app=<release>-twigex -f
```
`<release>-twigex` = the Helm release name plus the `-twigex` suffix (e.g. release `twigex` → `twigex-twigex`).

### Uninstall
```sh
helm uninstall twigex --namespace twigex
kubectl delete namespace twigex
```
Note: PVCs and Secrets have `helm.sh/resource-policy: keep` and survive `helm uninstall` by design — don't "clean these up" automatically unless the user explicitly asks for a full wipe.

## Testing / validation expectations

Before proposing a values-file change, an agent should:
1. Run `helm template` (or `helm install --dry-run`) against the new values to catch template-render failures early (e.g. the chart will hard-fail if `encryptKey` isn't exactly 32 hex chars).
2. Diff against the currently-deployed values where possible.
3. Flag any change to `mariadb.password`, `twigex.server.encryptKey`, or `domain` as high-risk and ask for explicit confirmation.

## Where to look for more detail

Full chart configuration reference (all `values.yaml` keys, defaults, types): see the Twigex chart's INSTALLATION.md → Configuration section, or `templates/twigex-secret.yaml` in the chart for exact secret key names.

Also see `SKILL.md` in this repo for a condensed, agent-oriented operating procedure.

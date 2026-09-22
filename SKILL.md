---
name: twigex-deployment
description: Operate, install, upgrade, configure, or troubleshoot the Twigex Helm chart deployment on Kubernetes. Use this skill whenever the user mentions Twigex, twigex.com, the Twigex Helm chart, or asks about installing/upgrading/configuring Twigex, its MariaDB backend, Redis, LiveKit (Channel/WebRTC), EuroOffice, or Collabora integration for this project — even if they don't say "Twigex" explicitly and just describe symptoms (e.g. "office editing isn't connecting", "chat isn't working", "helm install failed with encryptKey error"). Always consult this skill before running helm commands against this project.
---

# Twigex Deployment Skill

Operating procedure for installing, upgrading, configuring, and troubleshooting the Twigex Helm chart (`oci://ghcr.io/twigex/helm-charts/twigex`).

## Quick facts

- OCI chart — no `helm repo add` needed.
- Required for **every** install: `domain`, `twigex.admin.password`, `twigex.server.encryptKey` (32 hex chars, `openssl rand -hex 16`), `redis.auth.password`, `mariadb.password`.
- Required additionally for modes 1–3: `mariadb.rootPassword` (skip only in mode 4 with `mariadb.externalSecret=true`).
- Ingress is **off by default** — must opt in with `ingress.enabled=true`.
- No CPU/memory requests/limits are set by the chart — add `resources:` blocks yourself for production.

## Step 1 — Identify the DB mode needed

Ask (or infer from context) which of these fits:

| Mode | When to use | Extra prerequisite |
|---|---|---|
| 1. Embedded MariaDB | dev/test, small/medium prod | none |
| 2. External MariaDB | bring-your-own DB (on/off-cluster, RDS, operator-managed Galera) | pre-created service / endpoint, see below |

For mode 2 (external), the user must pre-create:
- Secret `<release>-twigex` (see `templates/twigex-secret.yaml` in the chart for keys)
- If `mariadb.externalSecret=true` is also set, Secret `<release>-mariadb` with keys `mariadb-password`, `mariadb-root-password` (otherwise the chart creates it from `mariadb.password` / `mariadb.rootPassword`)
- Service `<release>-mariadb` pointing at the external DB on port 3306

## Step 2 — Run the install

**`mariadb.mode=embedded`** (default):
```sh
helm install twigex oci://ghcr.io/twigex/helm-charts/twigex --version 0.0.35 \
  --namespace twigex --create-namespace \
  --set domain=example.com \
  --set twigex.admin.password=your_password \
  --set twigex.server.encryptKey=$(openssl rand -hex 16) \
  --set mariadb.password=your_mariadb_password \
  --set mariadb.rootPassword=your_mariadb_root_password \
  --set redis.auth.password=your_redis_password
```

**`mariadb.mode=external`:** `mariadb.mode=external` and `--set twigex.db.host=...`. `mariadb.rootPassword` is not needed. If your external DB credentials live in a user-managed Secret, also set `mariadb.externalSecret=true` and `mariadb.existingSecret.{name,keys}` so the chart skips the chart-managed Secret and reads from yours.

Add ingress if the app needs to be externally reachable:
```sh
--set ingress.enabled=true \
--set ingress.ingressClassName=traefik   # or nginx
```
Add TLS via cert-manager (requires an existing `ClusterIssuer`):
```sh
--set ingress.tls.enabled=true \
--set ingress.certManagerIssuer=letsencrypt-prod
```

## Step 3 — Verify

```sh
kubectl get pods -n twigex
kubectl get svc -n twigex
kubectl get pods -n twigex --show-labels   # find exact app= label
kubectl logs -n twigex -l app=<release>-twigex -f
# If you used mode=external with a mariadb-operator-managed cluster:
kubectl get mariadb -n twigex
```
Healthy state: twigex pod `Running` and listening on port 3000 (or `twigex.server.port`); `<release>-mariadb-0` and `<release>-redis-master-0` `Running`.
Healthy state — pod names differ by MariaDB mode:
- **`mariadb.mode=embedded`:** `<release>-mariadb-deployment-<hash>` and `<release>-redis-master-0` `Running`
- **`mariadb.mode=external`:** no chart-managed MariaDB pods; verify your external DB is reachable. `<release>-redis-master-0` and `<release>-twigex-<hash>` should be `Running`.
The twigex pod label is `app=<release>-twigex`; the Twigex app Service is always `<release>`. The MariaDB Service is `<release>-mariadb` only in `embedded` mode — `external` mode has no chart-managed MariaDB Service.

## Optional dependencies — when the user asks about them

- **LiveKit (Channel/voice-video):** chart only configures Twigex's client side (`twigex.channel.*`). LiveKit server itself must be installed separately via `helm.livekit.io`. Needs an API key/secret from `lk api create-key` and a Redis address (reuse `<release>-redis-master:6379`).
- **EuroOffice / Collabora (office editing):** set `twigex.office.enabled=true`, `twigex.office.type` to `"eurooffice"` or `"collabora"` (same WOPI API for both), `twigex.office.host`. The office server's WOPI allow-list (`aliasgroup1` or equivalent) must include the Twigex domain, and that domain must be reachable from end-user browsers — this is the #1 cause of "office editing won't load" issues.

## Troubleshooting playbook

| Symptom | Likely cause | Fix |
|---|---|---|
| `helm install` fails at template render, encryptKey error | `twigex.server.encryptKey` missing, wrong length, or non-hex | Must be exactly 32 hex chars: `openssl rand -hex 16` |
| App can't reach DB/Redis after changing release name | Service addresses are auto-derived from release name | Use `--name twigex` (default) or update all downstream refs to match new `<release>-*` names |
| Office editing fails to load / WOPI errors | Office server's alias/allow-list doesn't include the Twigex domain, or domain unreachable from browsers | Check `aliasgroup1` (or equivalent) on EuroOffice/Collabora side |
| Voice/video (Channel) not connecting | LiveKit not installed, or `twigex.channel.host`/key/secret misconfigured | Verify LiveKit server is up and reachable at the configured `ws://` URL |
| Upgrade breaks DB connectivity | Breaking change in DB backend defaults between chart versions | Read the chart Changelog before bumping `--version` |
| Want to rotate `mariadb.password` or `encryptKey` | Not supported live with embedded MariaDB (password) or safely at all (encryptKey — invalidates encrypted data) | Treat both as fixed at install time; changing requires reinit/data migration |
| PVCs/Secrets still exist after `helm uninstall` | Intentional — `helm.sh/resource-policy: keep` on PVCs and Secrets | Delete manually if a full wipe is wanted: `kubectl delete pvc -n twigex --all` etc. |

## Full configuration reference

For any `values.yaml` key not covered above (SMTP, LDAP, S3 storage, external secret management via `<release>-twigex`/`<release>-mariadb` secrets, persistence sizing, etc.), consult the Twigex chart's INSTALLATION.md Configuration section directly — don't guess at key names or defaults.

# Twigex Helm Chart — Installation Guide

This guide covers installing the Twigex Helm chart and its optional dependencies (LiveKit, EuroOffice/Collabora).

## Table of Contents

- [Prerequisites](#prerequisites)
- [Repository](#repository)
- [System Requirements](#system-requirements)
- [Install Twigex](#install-twigex)
  - [1. Default — Embedded MariaDB](#1-default--embedded-mariadb)
  - [2. External MariaDB](#2-external-mariadb)
  - [Ingress & TLS](#ingress--tls)
- [Install Optional Dependencies](#install-optional-dependencies)
  - [LiveKit (Channel / WebRTC)](#livekit-channel--webrtc)
  - [EuroOffice (Office Document Editing)](#eurooffice-office-document-editing)
  - [Collabora (Office Document Editing — alternative)](#collabora-office-document-editing--alternative)
- [Post-Install Verification](#post-install-verification)
- [Upgrading](#upgrading)
- [Uninstalling](#uninstalling)
- [Configuration](#configuration)

---

## Prerequisites

- **Helm v3.8.0+**
- **Kubernetes 1.24+** cluster with a default StorageClass (or create PVs manually)
- **kubectl** configured to access your cluster

- **cert-manager** with a ClusterIssuer (recommended for TLS)

> **Note:** Service addresses (Redis, MariaDB) are auto-derived from the Helm release name — `<release>-redis-master:6379` for Redis and `<release>-mariadb` for MariaDB. If you install with `--name twigex`, addresses become `twigex-redis-master:6379` and `twigex-mariadb`. Any release name works — Twigex derives them automatically. If you use a different release name, the app's env vars are auto-derived and should resolve correctly without any extra configuration.

---

## Repository

The chart is published as an OCI artifact to GitHub Container Registry:

```
oci://ghcr.io/twigex/helm-charts/twigex
```

No `helm repo add` is required for OCI charts.

---

## System Requirements

Rough sizing estimates for the full stack (Twigex + MariaDB + Redis + EuroOffice + LiveKit). Actual usage depends on document size, concurrent office edits, and concurrent video streams — validate with your own load tests.

| Deployment size       | Users  | vCPU      | RAM          | Storage   | Notes                                                                                        |
|-----------------------|--------|-----------|--------------|-----------|----------------------------------------------------------------------------------------------|
| **Minimum / testing** | 1–3    | 2         | 4 GiB        | 20 GiB    | Single-node k3s. Tests, dev, demo. Office editing usable but slow under load.         |
| **Small (light prod)**| ~10    | 4–6       | 8–12 GiB     | 100 GiB   | 1–2 node cluster. Single replica of each component. EuroOffice/LiveKit single node.         |
| **Medium (prod)**     | ~100   | 8–16      | 16–32 GiB    | 500 GiB   | 3+ worker nodes. Twigex + EuroOffice + LiveKit multi-replica. External MariaDB (Galera) or chart-managed embedded. |
| **Large (prod)**      | 500+   | 16–32+    | 32–64+ GiB   | 1+ TiB    | External MariaDB Galera cluster. EuroOffice horizontally scaled. LiveKit multi-node with dedicated RTC.    |


> ⚠️ **Default resource requests/limits are conservative** (`twigex.resources`: 100m/256Mi requests, 1 CPU/1Gi limits; cube workloads get their own defaults when enabled). The numbers above are **node sizing guides**, not what Kubernetes will reserve or throttle. For production, review and raise the explicit `resources:` blocks so the scheduler can binpack and prevent noisy-neighbor OOM kills.

---

## Install Twigex

Twigex supports two MariaDB deployment modes. Pick the one that matches your environment.

**Required values for ALL modes:**

These are required regardless of which MariaDB backend you pick:

- `domain` — FQDN for the Twigex application
- `twigex.admin.password` — initial admin password (change for production)
- `twigex.server.encryptKey` — exactly 32 hex characters. Generate with `openssl rand -hex 16`
- `redis.auth.password` — Redis password (change for production)
- `mariadb.password` — MariaDB user password (change for production). In external mode, this is the password Twigex uses to connect to your external DB.

**Required only for embedded mode** (skip with `mariadb.mode=external`):

- `mariadb.rootPassword` — MariaDB root password (change for production)

> Generate the encrypt key once and keep it stable across upgrades — rotating it invalidates all encrypted data in the database.

> ⚠️ **The Ingress is opt-in.** By default the chart creates only the Twigex app Pod and Service. To expose it via your ingress controller, add `--set ingress.enabled=true` to your install command. See [Ingress & TLS](#ingress--tls) for HTTP-only, TLS, and cert-manager examples.

### 1. Default — Embedded MariaDB

A bundled MariaDB instance is deployed as a single Pod inside the chart. Simplest option, suitable for small/medium deployments.

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

### 2. External MariaDB

Connect to a pre-existing MariaDB (on-cluster, off-cluster, or cloud-managed RDS) without the chart creating or managing any MariaDB resources. The chart does **not** deploy a MariaDB Deployment, Service, Secret, or operator CRs — you point it at your existing endpoint.

**When to use this:** you already operate MariaDB elsewhere and want a single source of truth (your existing DB) instead of the chart provisioning one.

Requirements:
- A reachable MariaDB endpoint (DNS name or IP) listening on port 3306
- A user that can authenticate (the password is supplied via `mariadb.password`). The user name must match `twigex.db.user` (default `twigex`) — either create that user in your external DB, or set `twigex.db.user` to match an existing user.
- An existing `twigex` database (the MySQL identifier — the app expects this DB name) (the chart does **not** create it — create it ahead of time, e.g. `CREATE DATABASE twigex CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;`)

```sh
helm install twigex oci://ghcr.io/twigex/helm-charts/twigex --version 0.0.35 \
  --namespace twigex --create-namespace \
  --set domain=example.com \
  --set twigex.admin.password=your_password \
  --set twigex.server.encryptKey=$(openssl rand -hex 16) \
  --set mariadb.mode=external \
  --set twigex.db.host=mariadb.prod.internal \
  --set mariadb.password=your_external_db_password \
  --set redis.auth.password=your_redis_password
```

`mariadb.mode=external` selects external mode. The chart deploys no MariaDB resources in this mode. `twigex.db.host` must be set to your external endpoint (the default `127.0.0.1` is rejected as obviously wrong). `mariadb.rootPassword` is **not required** — there is no MariaDB to initialize. `mariadb.externalSecret` has **no effect** here (it only skips the chart-managed Secret in embedded mode); the app reads its DB password from the `<release>-twigex` Secret (`TWIGEX_DB_PASSWORD`, sourced from `mariadb.password`), so keep that value in sync with your external DB.

### Ingress & TLS

The Ingress is **disabled by default** — the chart only creates the Twigex app Pod, Service, and (optionally) MariaDB / Redis. To expose the app via your ingress controller, opt in explicitly with `ingress.enabled=true`.

**HTTP-only (no TLS):**

```sh
helm install twigex oci://ghcr.io/twigex/helm-charts/twigex --version 0.0.35 \
  --namespace twigex --create-namespace \
  --set domain=example.com \
  --set twigex.admin.password=your_password \
  --set twigex.server.encryptKey=$(openssl rand -hex 16) \
  --set mariadb.password=your_mariadb_password \
  --set mariadb.rootPassword=your_mariadb_root_password \
  --set redis.auth.password=your_redis_password \
  --set ingress.enabled=true \
  --set ingress.ingressClassName=traefik   # or nginx, etc.
```

**TLS with cert-manager (recommended for production):**

Requires a `ClusterIssuer` named `letsencrypt-prod` to already exist in the cluster (create it once per cluster per the cert-manager docs). The chart only adds the annotation — cert-manager creates the Secret on first request to the Ingress.

```sh
helm install twigex oci://ghcr.io/twigex/helm-charts/twigex --version 0.0.35 \
  --namespace twigex --create-namespace \
  --set domain=example.com \
  --set twigex.admin.password=your_password \
  --set twigex.server.encryptKey=$(openssl rand -hex 16) \
  --set mariadb.password=your_mariadb_password \
  --set mariadb.rootPassword=your_mariadb_root_password \
  --set redis.auth.password=your_redis_password \
  --set ingress.enabled=true \
  --set ingress.ingressClassName=traefik \
  --set ingress.tls.enabled=true \
  --set ingress.certManagerIssuer=letsencrypt-prod
```

**TLS with a manually-created Secret:**

If you don't use cert-manager, create the Secret yourself (e.g. with `kubectl create secret tls example-com --cert=... --key=...`) and use:

```sh
  --set ingress.enabled=true \
  --set ingress.ingressClassName=traefik \
  --set ingress.tls.enabled=true
```

By default the chart references a TLS Secret named `<sanitized-domain>` (e.g. `example-com` for `domain: example.com`, or `twigex-example-com` for `domain: twigex.example.com`) — either create it manually under that name, or set `ingress.tlsExistingSecret` to use a Secret with any name you choose (mutually exclusive with `ingress.certManagerIssuer`).

---

## Install Optional Dependencies

### LiveKit (Channel / WebRTC)

LiveKit powers Twigex's real-time voice/video channel. The chart only configures the Twigex app to talk to LiveKit — you must install the LiveKit server separately.

**Official documentation:** https://docs.livekit.io/home/self-hosting/helm/
**Helm chart:** https://github.com/livekit/livekit-helm

Quick install:

```sh
# 1. Add the LiveKit Helm repo
helm repo add livekit https://helm.livekit.io
helm repo update

# 2. Generate API key/secret (you'll need these for the Twigex chart's Channel config)
lk api create-key
#   → API Key:    APIxxxxxxxxxxxx
#   → API Secret: xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx

# 3. Create a values file for LiveKit
cat > livekit-values.yaml <<EOF
livekit:
  rtc:
    tcpPort: 7881
    udpPort: 7882
  turn:
    enabled: true
  redis:
    address: twigex-redis-master:6379
    password: "redispassword"
  apiKey: APIxxxxxxxxxxxx
  apiSecret: xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
EOF

# 4. Install
helm install livekit livekit/livekit-server \
  --namespace livekit --create-namespace \
  --values livekit-values.yaml
```

Configure Twigex to use it:

```yaml
twigex:
  channel:
    enabled: true
    host: "ws://livekit.livekit.svc.cluster.local:7880"  # or your public hostname
    key: "APIxxxxxxxxxxxx"
    secret: "your-api-secret"
    linkPreviews: true
```

### EuroOffice (Office Document Editing)

EuroOffice is Twigex's office document editor (alternative to Collabora).

**Official project:** https://github.com/Euro-Office
**Container image:** `ghcr.io/euro-office/documentserver:latest`

#### Install with Helm

```sh
# 1. Create a values file
cat > eurooffice-values.yaml <<EOF
image:
  repository: ghcr.io/euro-office/documentserver
  tag: latest

service:
  type: ClusterIP
  port: 80

ingress:
  enabled: true
  className: nginx
  annotations:
    nginx.ingress.kubernetes.io/proxy-body-size: "100m"
  hosts:
    - host: eurooffice.example.com
      paths:
        - path: /
  tls:
    - hosts:
        - eurooffice.example.com
      secretName: eurooffice-tls

# Allow Twigex to connect from its domain
env:
  WOPI_ENABLED: "true"
  aliasgroup1: "https://twigex.example.com"
EOF

# 2. Install using the community-maintained chart, or deploy a custom
#    Helm chart wrapping the image. If you don't have one yet, you can
#    run it as a plain Deployment:
kubectl create namespace eurooffice
kubectl create deployment eurooffice \
  --image=ghcr.io/euro-office/documentserver:latest \
  -n eurooffice
kubectl expose deployment eurooffice --port=80 --target-port=80 -n eurooffice
```

> **Note:** The `aliasgroup1` (or equivalent WOPI allow-list) env var must contain the Twigex domain so EuroOffice accepts WOPI requests from it. The Twigex domain must be reachable from end-user browsers.

#### Configure Twigex

```yaml
twigex:
  office:
    enabled: true
    type: "eurooffice"   # or "collabora" — both use the same WOPI API
    host: "https://eurooffice.example.com"
    secret: ""           # JWT secret if configured
```

### Collabora (Office Document Editing — alternative)

Collabora Online is a popular open-source office editor. Twigex supports it as an alternative to EuroOffice.

**Official documentation:** https://sdk.collaboraoffice.com/Collabora-Online-Development-Edition.html
**Helm chart:** https://github.com/CollaboraOnline/online (Docker images available on Docker Hub)

Quick install using the official Docker image:

```sh
# 1. Create a values file
cat > collabora-values.yaml <<EOF
image:
  repository: collabora/code
  tag: latest
ingress:
  enabled: true
  className: nginx
  hosts:
    - host: collabora.example.com
      paths:
        - path: /
  tls:
    - hosts:
        - collabora.example.com
      secretName: collabora-tls

env:
  aliasgroup1: "https://twigex.example.com:443"
  extra_params: "--o:ssl.enable=false --o:ssl.termination=true"
  server_name: "Collabora"
EOF

# 2. Use the Collabora chart from the community, or deploy manually:
helm repo add collabora https://collaboraonline.github.io/online/
helm install collabora collabora/collabora-online \
  --namespace collabora --create-namespace \
  --values collabora-values.yaml
```

Configure Twigex:

```yaml
twigex:
  office:
    enabled: true
    type: "collabora"
    host: "https://collabora.example.com"
    secret: ""
```

> **Note:** The `aliasgroup1` env var must contain the Twigex domain so Collabora accepts WOPI requests from it. The Twigex domain must be reachable from end-user browsers.

---

## Post-Install Verification

After installation, verify that everything is healthy:

```sh
# Check pods
kubectl get pods -n twigex

# Check services
kubectl get svc -n twigex

# Tail application logs.
# The twigex pod label is `app: <release>-twigex`, where <release>-twigex is your
# `domain` value with dots replaced by dashes (e.g. domain: twigex.example.com → app=twigex-example-com).
# To find the exact label value, run: kubectl get pods -n twigex --show-labels
kubectl logs -n twigex -l app=<release>-twigex -f
# Example: kubectl logs -n twigex -l app=example-com -f
# Or, more robustly, by pod name:
#   POD=$(kubectl get pod -n twigex -l app=<release>-twigex -o jsonpath='{.items[0].metadata.name}')
#   kubectl logs -n twigex "$POD" -f

```

Expected healthy state:
- `<release>-twigex-...` pod: `Running`, logs show the app is listening on the configured port (`TWIGEX_SERVER_PORT`, default 3000)
- `<release>-mariadb-deployment-<hash>` (mode=embedded) or your external DB reachable: `Running`/`Ready`
- `<release>-redis-master-0`: `Running`

---

## Upgrading

```sh
helm upgrade twigex oci://ghcr.io/twigex/helm-charts/twigex --version 0.0.35 \
  --namespace twigex \
  -f your-values.yaml
```

⚠️ **Breaking changes** — read the [Changelog](CHANGELOG.md) and the [Upgrading](README.md#upgrading) section of the README before upgrading, especially around the default database backend.

---

## Uninstalling

```sh
helm uninstall twigex --namespace twigex
kubectl delete namespace twigex
```

> **Note:** PVCs (`<release>-twigex-pvc`, `<release>-mariadb-pvc`) and Secrets (`<release>-twigex`, `<release>-mariadb`) have `helm.sh/resource-policy: keep` and are NOT deleted by `helm uninstall`. Delete them manually if you want a full cleanup.

For a complete wipe:

```sh
helm uninstall twigex -n twigex
kubectl delete pvc -n twigex --all
kubectl delete secret -n twigex -l app.kubernetes.io/instance=<release>
kubectl delete namespace twigex
```

---

## Configuration

Reference of all values exposed by `values.yaml`. See [Install Twigex](#install-twigex) for the install commands; this section documents what each value does and its default.

### Global

| Name | Description | Type | Default |
|------|-------------|------|---------|
| `domain` | FQDN for the Twigex application | string | `"example.com"` |
| `fullnameOverride` | Full resource name override | string | `""` |
| `nameOverride` | Name portion override | string | `""` |

### Ingress

| Name | Description | Type | Default |
|------|-------------|------|---------|
| `ingress.enabled` | Enable Ingress resource (opt-in; chart creates only the Pod + Service by default) | bool | `false` |
| `ingress.ingressClassName` | IngressClass (e.g. `nginx`, `traefik`) | string | `"nginx"` |
| `ingress.annotations` | Default Ingress annotations | object | See values.yaml |
| `ingress.customAnnotations` | Additional/overriding annotations | object | `{}` |
| `ingress.tls.enabled` | Render the TLS block in the Ingress. When false, the Ingress is HTTP-only. | bool | `false` |
| `ingress.certManagerIssuer` | Name of an existing cert-manager ClusterIssuer. When set, the chart adds the `cert-manager.io/cluster-issuer` annotation so cert-manager creates the TLS Secret named `<sanitized-domain>`. | string | `""` |
| `ingress.tlsExistingSecret` | Use an existing Secret for Ingress TLS instead of cert-manager (overrides the `<sanitized-domain>` default name; mutually exclusive with `certManagerIssuer`). | string | `""` |

### Twigex Image

| Name | Description | Type | Default |
|------|-------------|------|---------|
| `twigex.image.repository` | Container image repository | string | `ghcr.io/twigex/twigex` |
| `twigex.image.tag` | Container image tag. Set to `""` (default) to use `Chart.AppVersion` (currently `v0.14.0-rc2`). | string | `""` |

### Server

| Name | Description | Type | Default |
|------|-------------|------|---------|
| `twigex.server.port` | Server listen port (used for the container, Service, and Ingress backend) | int | `3000` |
| `twigex.server.defaultLocale` | Default UI locale | string | `"en"` |
| `twigex.server.sessionLengthDays` | Session lifetime in days | int | `30` |
| `twigex.server.encryptKey` | **Exactly 32 hex characters (16 bytes).** Generate with `openssl rand -hex 16`. The chart fails the install at template-render time if this is missing, the wrong length, or contains non-hex characters. No default — required. ⚠️ Change per-install; immutable in practice once data exists. | string | `""` (required) |
| `twigex.server.tlsCertFile` | Path to TLS cert file (optional) | string | `""` |
| `twigex.server.tlsKeyFile` | Path to TLS key file (optional) | string | `""` |
| `twigex.server.trustedProxies` | Trusted proxy CIDRs (comma-joined into `TWIGEX_TRUSTED_PROXIES`) | list | `[]` |
| `twigex.server.trustedProxyHeaders` | Headers trusted for client IP (comma-joined into `TWIGEX_TRUSTED_PROXY_HEADERS`) | list | `[]` |
| `twigex.server.maxPublicUploadSize` | Max public share-link upload size in MB (app default 2048) | string | `""` |

### Database

| Name | Description | Type | Default |
|------|-------------|------|---------|
| `twigex.db.host` | MariaDB host. Auto-derived from the release name (`<release>-mariadb`) unless `mariadb.mode=external` — in external mode this is the external endpoint the Twigex app connects to (required; the default `127.0.0.1` is rejected). | string | `"127.0.0.1"` |
| `twigex.db.port` | MariaDB port | int | `3306` |
| `twigex.db.user` | Database username | string | `"twigex"` |
| `twigex.db.name` | Database name | string | `"twigex"` |
| `twigex.db.driver` | Database driver | string | `"mysql"` |
| `twigex.db.readTimeout` | Read timeout | string | `"30s"` |
| `twigex.db.writeTimeout` | Write timeout | string | `"30s"` |
| `twigex.db.maxOpenConns` | Max open connections | int | `25` |
| `twigex.db.maxIdleConns` | Max idle connections | int | `10` |
| `twigex.db.connMaxLifetimeMinutes` | Connection max lifetime (minutes) | int | `60` |
| `twigex.db.connMaxIdleTimeMinutes` | Connection max idle time (minutes) | int | `30` |
| `twigex.db.queryTimeout` | Query timeout (seconds) | int | `30` |

> **Note:** The database password is controlled by `mariadb.password` (see [MariaDB Configuration](#mariadb-configuration)). Both the MariaDB instance and the Twigex app use the same password via a single source of truth.

### Redis

See [Redis Subchart](#redis-subchart) below — Redis is deployed as the Bitnami subchart; its values live under `redis.*`.

### Storage

| Name | Description | Type | Default |
|------|-------------|------|---------|
| `twigex.storage.type` | Storage type: `local`, `s3`, or `s3compat` | string | `"local"` |
| `twigex.storage.local.name` | Human-readable name for local storage | string | `"Local storage"` |
| `twigex.storage.s3.name` | Human-readable name for S3 storage (used when type is `s3`/`s3compat`) | string | `"S3 storage"` |
| `twigex.storage.s3.endpoint` | S3 endpoint (required if type=s3/s3compat) | string | `""` |
| `twigex.storage.s3.accessKey` | S3 access key (required if type=s3/s3compat) | string | `""` |
| `twigex.storage.s3.secretKey` | S3 secret key (required if type=s3/s3compat) | string | `""` |
| `twigex.storage.s3.bucket` | S3 bucket name | string | `""` |
| `twigex.storage.s3.ssl` | Use SSL for S3 | bool | `true` |

> **Note:** S3 sub-keys are only passed to the app when `twigex.storage.type` is `s3` or `s3compat`. The access/secret keys are read from the `<release>-twigex` Secret (`TWIGEX_STORAGE_ACCESS_KEY` / `TWIGEX_STORAGE_SECRET_KEY`).

### SMTP

| Name | Description | Type | Default |
|------|-------------|------|---------|
| `twigex.smtp.host` | SMTP server host. Empty (default) = all `TWIGEX_SMTP_*` env vars are omitted from the pod, leaving the admin GUI email settings editable; setting it locks the GUI. | string | `""` |
| `twigex.smtp.port` | SMTP server port | string | `""` |
| `twigex.smtp.username` | SMTP username | string | `""` |
| `twigex.smtp.password` | SMTP password (rendered into the `<release>-twigex` Secret as `TWIGEX_SMTP_PASSWORD`) | string | `""` |
| `twigex.smtp.security` | SMTP security (e.g. `tls`, `starttls`) | string | `""` |
| `twigex.smtp.authEnabled` | Enable SMTP authentication | bool | `false` |
| `twigex.smtp.fromAddress` | From address for outgoing mail | string | `""` |
| `twigex.smtp.fromName` | From display name | string | `""` |
| `twigex.smtp.replyTo` | Reply-To address | string | `""` |

### Office (Collabora or EuroOffice)

| Name | Description | Type | Default |
|------|-------------|------|---------|
| `twigex.office.enabled` | Enable office document editing. Pick the editor via `twigex.office.type`. | bool | `false` |
| `twigex.office.type` | Office editor type. Valid values: `collabora` or `eurooffice`. Both expose the WOPI API. | string | `""` |
| `twigex.office.host` | Office editor URL. Empty (default) = `TWIGEX_OFFICE_*` env vars omitted (admin GUI editable); setting it configures office editing and locks the GUI. | string | `""` |
| `twigex.office.secret` | JWT secret if configured on the office editor (rendered into the `<release>-twigex` Secret as `TWIGEX_OFFICE_SECRET`). | string | `""` |

### Channel (LiveKit / WebRTC)

The chart configures the Twigex app client side only; the LiveKit server itself is deployed separately. Env vars are gated: `TWIGEX_CHANNEL_{ENABLED,HOST,KEY,SECRET}` are emitted only when `twigex.channel.host` is set; `TWIGEX_CHANNEL_LINK_PREVIEWS` only when `linkPreviews` is true; `TWIGEX_CHANNEL_GIF_*` only when `gif.enabled` is true. Unset = the admin GUI fields stay editable.

| Name | Description | Type | Default |
|------|-------------|------|---------|
| `twigex.channel.enabled` | Enable Channel (LiveKit). Only rendered when `channel.host` is set. | bool | `false` |
| `twigex.channel.host` | LiveKit WebSocket URL | string | `""` |
| `twigex.channel.key` | LiveKit API key | string | `""` |
| `twigex.channel.secret` | LiveKit API secret (rendered into the `<release>-twigex` Secret as `TWIGEX_CHANNEL_SECRET`) | string | `""` |
| `twigex.channel.linkPreviews` | Enable link previews in chat (emits `TWIGEX_CHANNEL_LINK_PREVIEWS` when true) | bool | `false` |
| `twigex.channel.gif.enabled` | Enable GIF picker | bool | `false` |
| `twigex.channel.gif.apiKey` | GIF provider API key | string | `""` |

### LDAP

| Name | Description | Type | Default |
|------|-------------|------|---------|
| `twigex.ldap.host` | LDAP server hostname | string | `""` |
| `twigex.ldap.port` | LDAP server port | int | `389` |
| `twigex.ldap.baseDN` | LDAP base DN | string | `""` |
| `twigex.ldap.bindDN` | LDAP bind DN | string | `""` |
| `twigex.ldap.bindPassword` | LDAP bind password | string | `""` |
| `twigex.ldap.connectionSecurity` | Connection security: `""`/`none`, `tls`, `starttls` | string | `""` |
| `twigex.ldap.caCert` | CA certificate (PEM) for TLS verification | string | `""` |
| `twigex.ldap.insecureSkipVerify` | Skip TLS verification | bool | `false` |
| `twigex.ldap.timeoutSeconds` | LDAP operation timeout (app default 10) | string | `""` |
| `twigex.ldap.userFilter` | LDAP user filter | string | `"(uid={0})"` |
| `twigex.ldap.usernameAttr` | Username attribute | string | `""` |
| `twigex.ldap.idAttr` | Unique ID attribute | string | `"uid"` |
| `twigex.ldap.firstNameAttr` | First name attribute | string | `"givenName"` |
| `twigex.ldap.lastNameAttr` | Last name attribute | string | `"sn"` |
| `twigex.ldap.emailAttr` | Email attribute | string | `"mail"` |
| `twigex.ldap.syncEnabled` | Enable LDAP user sync | bool | `false` |
| `twigex.ldap.syncIntervalMinutes` | Sync interval in minutes (app default 60) | string | `""` |
| `twigex.ldap.syncMaxDeactivatePercent` | Max % of users a sync may deactivate (app default 20) | string | `""` |
| `twigex.ldap.allowedGroups` | Pipe-separated allowed LDAP groups | string | `""` |

### Admin (First Boot)

The admin user is created only on first boot when no users exist in the database.

| Name | Description | Type | Default |
|------|-------------|------|---------|
| `twigex.admin.name` | Admin first name | string | `"Admin"` |
| `twigex.admin.lastName` | Admin last name | string | `"User"` |
| `twigex.admin.username` | Admin username | string | `"admin"` |
| `twigex.admin.email` | Admin email | string | `"admin@example.com"` |
| `twigex.admin.password` | Admin password. ⚠️ Change for production. | string | `"admin"` |

### License

| Name | Description | Type | Default |
|------|-------------|------|---------|
| `twigex.license` | License key | string | `""` |

### Persistence

| Name | Description | Type | Default |
|------|-------------|------|---------|
| `twigex.persistence.size` | PVC size | string | `"2Gi"` |
| `twigex.persistence.storageClass` | StorageClass (`""` = cluster default) | string | `""` |
| `twigex.persistence.accessModes` | PVC access modes | list | `[ReadWriteOnce]` |
| `twigex.persistence.annotations` | Additional PVC annotations | object | `{}` |
| `twigex.persistence.labels` | Additional PVC labels | object | `{}` |

### Redis Subchart

| Name | Description | Type | Default |
|------|-------------|------|---------|
| `redis.architecture` | Redis architecture: `standalone` or `replication` | string | `"standalone"` |
| `redis.auth.enabled` | Enable Redis authentication | bool | `true` |
| `redis.auth.password` | Redis password. Single source of truth — used by both the Bitnami Redis subchart and the Twigex app (`<release>-twigex` Secret). | string | `"supersecretpassword"` |
| `redis.master.persistence.enabled` | Enable Redis persistence | bool | `true` |
| `redis.master.persistence.size` | Redis PVC size | string | `"1Gi"` |

### MariaDB Configuration

| Name | Description | Type | Default |
|------|-------------|------|---------|
| `mariadb.password` | MariaDB user password. Also used by the Twigex app to connect. ⚠️ Change for production. **Do NOT change after initial install** with embedded MariaDB — the password is set in the database on first boot and cannot be changed without reinitializing (data loss). | string | `"mariadb"` |
| `mariadb.rootPassword` | MariaDB root password. ⚠️ Change for production. | string | `"mariadbroot"` |
| `mariadb.externalSecret` | When `true` (and `mariadb.mode=embedded`), the chart-managed `<release>-mariadb` Secret is skipped and credentials come from `mariadb.existingSecret.{name,keys}`. Classic External Secrets Operator pattern. | bool | `false` |

### External Secret Management

For production deployments using external secret management (e.g. [External Secrets Operator](https://external-secrets.io/), Vault, AWS Secrets Manager), you have two options:

**Option A — Let the chart create secrets, populate from external source:**

Set the password values in your ArgoCD Application or values file. The chart creates the secrets with those values. Your external secret manager syncs to the same secret names.

**Option B — Fully external secrets:**

Set `twigex.externalSecret: true` and/or `mariadb.externalSecret: true`. The chart will **not** create the corresponding secret. You must provide secrets with the expected names and keys:

- `<release>-twigex` — keys: `TWIGEX_ADMIN_PASSWORD`, `TWIGEX_SERVER_ENCRYPT_KEY`, `TWIGEX_DB_PASSWORD`, `TWIGEX_REDIS_PASSWORD`, `TWIGEX_STORAGE_ACCESS_KEY`, `TWIGEX_STORAGE_SECRET_KEY`, `TWIGEX_SMTP_PASSWORD`, `TWIGEX_OFFICE_SECRET`, `TWIGEX_CHANNEL_SECRET`, `TWIGEX_LDAP_BIND_PASSWORD`
- `<release>-mariadb` — keys: `mariadb-password`, `mariadb-root-password`

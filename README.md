<div align="center">

<h1>Twigex Helm Chart</h1>

<p><strong>Deploy Twigex on Kubernetes.</strong><br/>
The official Helm chart: files, chat and video, projects, and a BI tool, with embedded or external MariaDB, Redis, LiveKit and office editing.</p>

<p>
<a href="LICENSE"><img height="20" alt="License: MIT" src="https://img.shields.io/badge/license-MIT-blue?style=flat" /></a>
<a href="https://artifacthub.io/packages/helm/twigex/twigex"><img height="20" alt="Helm chart" src="https://img.shields.io/badge/helm-Artifact%20Hub-417598?style=flat&logo=helm&logoColor=white" /></a>
<a href="#"><img height="20" alt="Status: pre-1.0" src="https://img.shields.io/badge/status-pre--1.0-orange?style=flat" /></a>
<a href="https://www.twigex.com"><img height="20" alt="Made by Twigex" src="https://img.shields.io/badge/made%20by-Twigex-6f42c1?style=flat" /></a>
</p>

<p>
<a href="#installing"><strong>Quick start</strong></a> ·
<a href="https://demo.twigex.com/"><strong>Live demo</strong></a> ·
<a href="https://twigex.com/"><strong>Docs</strong></a>
</p>

</div>

---

> [!NOTE]
> Try it right now, with no signup and no setup: **[demo.twigex.com](https://demo.twigex.com/)**,
> username `twigex`, password `twigex`. The demo resets every 30 minutes, so don't put anything real in it.

More info about the project:

- [https://twigex.com](https://twigex.com)
- [https://www.reddit.com/r/twigex/](https://reddit.com/r/twigex)

> [!IMPORTANT]
> This Helm chart is in active development and has **not reached 1.0**. It is used in production, but features and configuration may still change between releases.

## Table of contents

- [Prerequisites](#prerequisites)
- [Installing](#installing)
  - [Default (embedded MariaDB)](#default-embedded-mariadb)
- [Configuration](#configuration)
- [ArgoCD Deployment](#argocd-deployment)
- [License](#license)
- [Upgrading](#upgrading)

## Prerequisites

- Helm v3.8.0 or later
- Kubernetes cluster with a default StorageClass (or create PVs manually)

|> **Note:** Default values are set for a typical Kubernetes installation with the example release name `twigex` (any release name works; addresses are auto-derived). The chart auto-derives Redis (`<release>-redis-master:6379`) and MariaDB (`<release>-mariadb`) addresses from the release name, so a non-default release name works without any extra configuration.

## Installing

### Default (embedded MariaDB)

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

The chart validator fails the install if `twigex.server.encryptKey` (exactly 32 hex chars) is unset, if `twigex.admin.password` is empty (when admin bootstrap is enabled), or if `mariadb.password`, `mariadb.rootPassword` (embedded mode), or `redis.auth.password` is emptied — these three have insecure defaults, so always override them. It also enforces a valid `domain`, a valid `mariadb.mode`, a non-`127.0.0.1` `twigex.db.host` in external mode, and enum/range checks on strategy, service type, and ports. See [INSTALLATION.md](INSTALLATION.md) for the external-MariaDB, Ingress/TLS, and optional-dependency walkthroughs.

When upgrading, please refer to the [Upgrading](#upgrading) section at the bottom of this document for major and breaking changes.

<p align="right"><a href="#twigex-helm-chart">Back to top</a></p>

## Configuration

### Global

| Name | Description | Type | Default |
|------|-------------|------|---------|
| `domain` | FQDN for the Twigex application | string | `"example.com"` |

### Ingress

| Name | Description | Type | Default |
|------|-------------|------|---------|
| `ingress.enabled` | Enable Ingress resource (opt-in; without it, no Ingress is created and the app is reachable only via the `<release>` Service) | bool | `false` |
| `ingress.ingressClassName` | IngressClass (e.g. `nginx`, `traefik`) | string | `"nginx"` |
| `ingress.annotations` | Default Ingress annotations | object | See values.yaml |
| `ingress.customAnnotations` | Additional annotations, merged **over** `annotations` (user values win) | object | `{}` |
| `ingress.tls.enabled` | Render the TLS block in the Ingress. When false, the Ingress is HTTP-only. | bool | `false` |
| `ingress.certManagerIssuer` | Name of an existing cert-manager ClusterIssuer. When set, the chart adds the `cert-manager.io/cluster-issuer` annotation so cert-manager creates the TLS Secret named `<sanitized-domain>`. | string | `""` |
| `ingress.tlsExistingSecret` | Use an existing Secret for Ingress TLS instead of cert-manager (overrides the `<sanitized-domain>` default name; mutually exclusive with `certManagerIssuer`). | string | `""` |

### Twigex Image

| Name | Description | Type | Default |
|------|-------------|------|---------|
| `twigex.image.repository` | Container image repository. Default is the pre-built EE image with enterprise features; for the fully open-source build, build the container from source, push it to your own registry, and set this value. | string | `ghcr.io/twigex/twigex-ee` |
| `twigex.image.tag` | Container image tag. Set to `""` (default) to use `Chart.AppVersion` (currently `0.15.0`). | string | `""` |
| `twigex.image.pullPolicy` | Container image pullPolicy | string | `IfNotPresent` |

### Deployment & Workload

| Name | Description | Type | Default |
|------|-------------|------|---------|
| `twigex.replicas` | Twigex Deployment replicas | int | `1` |
| `twigex.strategy` | Deployment strategy: `Recreate` or `RollingUpdate` | string | `Recreate` |
| `twigex.resources` | CPU/memory requests and limits for the Twigex container | object | `{requests: {cpu: 100m, memory: 256Mi}, limits: {cpu: "1", memory: 1Gi}}` |
| `twigex.service.type` | Service type: `ClusterIP`, `NodePort`, or `LoadBalancer` | string | `ClusterIP` |
| `twigex.service.port` | Service port | int | `3000` |
| `twigex.service.targetPort` | Container port targeted by the Service | int | `3000` |
| `twigex.service.nodePort` | NodePort (required if `type=NodePort`, range 30000–32767) | string | `""` |
| `twigex.service.loadBalancerIP` | Static LB IP (LoadBalancer only; deprecated upstream since Kubernetes 1.24) | string | `""` |
| `twigex.service.annotations` | Service annotations | object | `{}` |
| `twigex.pod.{annotations,labels,nodeSelector, affinity,tolerations,priorityClassName, terminationGracePeriodSeconds,topologySpreadConstraints, securityContext,containerSecurityContext}` | Pod-template customization for the Twigex Deployment | object | see `values.yaml` |
| `twigex.probes.enabled` | Render liveness/readiness probes (TCP socket on `twigex.server.port`) | bool | `true` |
| `twigex.probes.{liveness,readiness}.*` | Probe tuning (`initialDelaySeconds`, `periodSeconds`, `timeoutSeconds`, `failureThreshold`) | object | see `values.yaml` |
| `twigex.pdb.enabled` | Create a PodDisruptionBudget for the Twigex Deployment. Default `false`: with `replicas: 1` and `minAvailable: 1` the PDB has zero allowed disruptions and blocks node drains. | bool | `false` |
| `twigex.pdb.minAvailable` | PDB `minAvailable` | int | `1` |
| `twigex.pdb.maxUnavailable` | PDB `maxUnavailable` (mutually exclusive with `minAvailable`) | string | `""` |
| `twigex.serviceAccount.create` | Create a ServiceAccount (`<release>-twigex`). When `false`, `twigex.serviceAccount.name` (if set) is still used as the pod's ServiceAccount. | bool | `true` |
| `twigex.serviceAccount.name` | Override the ServiceAccount name | string | `""` |
| `twigex.serviceAccount.annotations` | ServiceAccount annotations | object | `{}` |
| `twigex.serviceAccount.imagePullSecrets` | Image pull secrets for private registries | list | `[]` |
| `twigex.config` | Arbitrary `TWIGEX_<KEY>=value` env passthrough (hyphens become underscores) | object | `{}` |
| `twigex.configFromSecrets` | Same shape, but each value is a `{name, key}` Secret reference | object | `{}` |

### Cube.js Analytics (optional)

When `cube.enabled=true`, the chart deploys cube-api / cube-router / cube-worker (Deployments + Services), a `cube-config` ConfigMap, and a `cube-secret` Secret, and injects `TWIGEX_COLLIMATO_CUBE_*` env vars into the Twigex app. Required values when enabling (the chart validator hard-fails without them, unless `cube.existingSecret.name` points at a user-managed Secret): `cube.apiSecret` and `cube.callbackSecret` — generate fresh ones per install with `openssl rand -hex 32`.

| Name | Description | Type | Default |
|------|-------------|------|---------|
| `cube.enabled` | Deploy the Cube.js analytics backend | bool | `false` |
| `cube.image.api.{repository,tag,pullPolicy}` | cube-api image | object | `cubejs/cube:latest` |
| `cube.image.store.{repository,tag,pullPolicy}` | cubestore image (router + workers) | object | `cubejs/cubestore:latest` |
| `cube.apiSecret` | Shared secret Cube verifies the Twigex JWT against (required unless `cube.existingSecret.name`) | string | `""` |
| `cube.callbackSecret` | Secret sent back to Twigex on every Cube callback (required unless `cube.existingSecret.name`) | string | `""` |
| `cube.existingSecret.name` | Use a user-managed Secret instead of a chart-managed one: the chart renders no cube Secret at all. cube-api reads it via `envFrom`, so it **must contain the literal key names** `CUBEJS_API_SECRET` and `CUBE_CALLBACK_SECRET` (the `cube.existingSecret.keys` remap applies only to the Twigex `secretKeyRef`s) | string | `""` |
| `cube.api.replicas` | cube-api replicas | int | `1` |
| `cube.api.service.port` | Port for the cube-api Service, container, and probes. Used by Twigex to build `TWIGEX_COLLIMATO_CUBE_API_URL` | int | `4000` |
| `cube.api/storeRouter/storeWorker.resources` | Per-workload CPU/memory requests and limits | object | see `values.yaml` |
| `cube.storeWorker.replicas` | cubestore worker replicas | int | `1` |
| `cube.pdb.{enabled,minAvailable}` | PodDisruptionBudget for Cube workloads (minAvailable applies to all three). Default `enabled: false` — all cube workloads are single-replica, so a `minAvailable: 1` PDB blocks drains. | object | `enabled: false, minAvailable: 1` |
| `cube.internalUrl` | Address Cube uses to call back into Twigex (`TWIGEX_INTERNAL_URL` on the cube-api pod). Default `http://<release>:<service.port>/api/internal/cube`; an override replaces the whole URL and **must** end in `/api/internal/cube`. | string | `""` |
| `cube.devMode` | Cube.js dev mode | bool | `false` |

### Server

| Name | Description | Type | Default |
|------|-------------|------|---------|
| `twigex.server.port` | Server listen port. Rendered as `TWIGEX_SERVER_PORT` and used by the probes — **not** the Service/Ingress port; traffic ports come from `twigex.service.port`/`targetPort`. Changing this alone will break traffic. | int | `3000` |
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
| `twigex.db.host` | MariaDB host. Auto-derived from the release name (`<release>-mariadb`) **unless** `mariadb.mode=external` — see [External MariaDB](#external-mariadb). In external mode, this is the external endpoint the Twigex app connects to (required; the default `127.0.0.1` is rejected). | string | `"127.0.0.1"` |
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

> **Note:** The database password is controlled by `mariadb.password` (see [MariaDB Configuration](#mariadb-configuration)). Both the MariaDB instance and the Twigex app use the same password via a single source of truth — unless `mariadb.externalSecret=true`, in which case your `<release>-mariadb` Secret feeds MariaDB while the app still reads `mariadb.password` from values (they must match; see [External Secret Management](#external-secret-management)).

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
| `twigex.smtp.enabled` | SMTP feature flag, rendered as `TWIGEX_SMTP_ENABLED` when `smtp.host` is set | bool | `true` |
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
| `twigex.ldap.host` | LDAP server hostname. Empty (default) = all `TWIGEX_LDAP_*` env vars are omitted (admin GUI editable); setting it locks the GUI. | string | `""` |
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
| `twigex.ldap.enabled` | LDAP feature flag (rendered as `TWIGEX_LDAP_ENABLED` when `ldap.host` is set) | bool | `false` |

### Admin (First Boot)

The admin user is created only on first boot when no users exist in the database.

| Name | Description | Type | Default |
|------|-------------|------|---------|
| `twigex.admin.enabled` | Create the bootstrap admin user on first boot (when `false`, no `TWIGEX_ADMIN_PASSWORD` env is rendered) | bool | `true` |
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
| `redis.enabled` | Enable the Redis subchart entirely | bool | `true` |
| `redis.architecture` | Redis architecture: `standalone` or `replication` | string | `"standalone"` |
| `redis.auth.enabled` | Enable Redis authentication | bool | `true` |
| `redis.auth.password` | Redis password. **Used by both the Bitnami Redis subchart and the Twigex app** (via the chart's `twigex-secret.yaml`). | string | `"supersecretpassword"` |
| `redis.master.persistence.enabled` | Enable Redis persistence | bool | `false` |
| `redis.master.persistence.size` | Redis PVC size (only used when persistence is enabled) | string | `"1Gi"` |

### MariaDB Backend Options

Twigex supports different MariaDB deployment modes.

#### Embedded MariaDB (default)

A bundled MariaDB instance deployed by the chart. Persistent (PVC always created; size from `mariadb.persistence.size`).

```sh
# Default — mariadb.mode is embedded; nothing to set.
```

#### External MariaDB

Connect to a pre-existing MariaDB without the chart creating or managing any MariaDB resources. The chart does **not** deploy a MariaDB StatefulSet, Service, Secret, or operator CRs — you point it at your existing endpoint. This includes MariaDB clusters you manage yourself, whether standalone, Galera, or operator-managed.

**When to use this:** you already operate MariaDB elsewhere and want a single source of truth (your existing DB) instead of the chart provisioning one.

Requirements:
- A reachable MariaDB endpoint (DNS name or IP) on port 3306
- A user that can authenticate (password supplied via `mariadb.password`). The user name must match `twigex.db.user` (default `twigex`) — either create that user in your external DB, or set `twigex.db.user` to match an existing user.
- An existing `twigex` database (the MySQL identifier — the app expects this DB name) (create it ahead of time: `CREATE DATABASE twigex CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;`)

```sh
--set mariadb.mode=external \
--set twigex.db.host=mariadb.prod.internal \
--set mariadb.password=$YOUR_EXTERNAL_DB_PASSWORD
```

`mariadb.mode=external` selects external mode. The chart deploys no MariaDB resources in this mode. `twigex.db.host` must be set (the default `127.0.0.1` is rejected). `mariadb.rootPassword` is **not required**. `mariadb.externalSecret` has **no effect** in external mode — there is no chart-managed Secret to skip; the Twigex app reads its DB password from the `<release>-twigex` Secret (`TWIGEX_DB_PASSWORD`, sourced from `mariadb.password`), so keep that value in sync with your external DB.

---

### MariaDB Configuration

| Name | Description | Type | Default |
|------|-------------|------|---------|
| `mariadb.image.repository` | MariaDB image repository | string | `"mariadb"` |
| `mariadb.mode` | MariaDB topology: `embedded` (default, chart deploys + owns MariaDB + Secret + PVC) / `external` (chart deploys nothing DB-side, point at your pre-existing DB). | string | `"embedded"` |
| `mariadb.password` | MariaDB user password. Also used by the Twigex app to connect. ⚠️ Change for production. **`mariadb.mode=embedded`**: cannot be changed after first boot without reinitializing (data loss). **`mariadb.mode=external`**: rotatable freely. | string | `"mariadb"` |
| `mariadb.rootPassword` | MariaDB root password. Required for `mariadb.mode=embedded`. Skipped for `mariadb.mode=external`. ⚠️ Change for production. | string | `"mariadbroot"` |
| `mariadb.image.tag` | Container image tag (embedded mode only; upstream supports the 10/11 series). Keep the default `"11"` — an empty tag falls back to `Chart.AppVersion` (the Twigex version), which is not a valid MariaDB tag. | string | `"11"` |
| `mariadb.image.pullPolicy` | Container image pullPolicy. | string | `"IfNotPresent"` |
| `mariadb.persistence.{size,storageClass,accessModes}` | Embedded MariaDB only. The MariaDB Deployment's PVC sizing (`<release>-mariadb-pvc`). | object | see `values.yaml` |
| `mariadb.externalSecret` | When `true` (and `mariadb.mode=embedded`), the chart-managed `<release>-mariadb` Secret is skipped. The Deployment always reads credentials from the Secret named `<release>-mariadb` (keys `mariadb-password`, `mariadb-root-password`) — with this on, create that Secret yourself (External Secrets Operator pattern). No effect in `external` mode (there is no chart-managed Secret to skip). | bool | `false` |
| `mariadb.resources` | CPU/memory requests and limits for the MariaDB container | object | `{requests: {cpu: 100m, memory: 256Mi}, limits: {cpu: "1", memory: 1Gi}}` |

### External Secret Management

For production deployments using external secret management (e.g. [External Secrets Operator](https://external-secrets.io/), Vault, AWS Secrets Manager), you have two options:

**Option A — Let the chart create secrets, populate from external source:**

Set the password values in your ArgoCD Application or values file. The chart creates the secrets with those values. Your external secret manager syncs to the same secret names.

**Option B — Fully external secrets:**

Set `twigex.externalSecret: true` and/or `mariadb.externalSecret: true`. The chart will **not** create the corresponding secret. You must provide secrets with the expected names and keys:

- `<release>-twigex` — keys: `TWIGEX_ADMIN_PASSWORD`, `TWIGEX_SERVER_ENCRYPT_KEY`, `TWIGEX_DB_PASSWORD`, `TWIGEX_REDIS_PASSWORD`, `TWIGEX_STORAGE_ACCESS_KEY`, `TWIGEX_STORAGE_SECRET_KEY`, `TWIGEX_SMTP_PASSWORD`, `TWIGEX_OFFICE_SECRET`, `TWIGEX_CHANNEL_SECRET`, `TWIGEX_LDAP_BIND_PASSWORD`
- `<release>-mariadb` — keys: `mariadb-password`, `mariadb-root-password`

Alternatively, `twigex.existingSecret.name` fully replaces the chart-managed Secret: no `<release>-twigex` Secret is rendered at all, every `secretKeyRef` in the app Deployment points at **your** Secret, and `twigex.existingSecret.keys` remaps the key names (any subset; defaults match the chart's own key names). When this is set, `twigex.server.encryptKey` and `twigex.admin.password` values are not required by the validator — provide them in your Secret instead.

> **⚠️ Mode `embedded` + ESO:** when you set `mariadb.externalSecret: true` alongside `mariadb.mode=embedded`, the chart skips its own `<release>-mariadb` Secret. You must provide that Secret externally. Its `mariadb-password` key MUST match the `mariadb.password` value, because the Twigex app uses `mariadb.password` (via `twigex-secret.TWIGEX_DB_PASSWORD`) to authenticate. If they drift, the app will fail to connect. In practice, source both from the same ESO Secret.

---

<p align="right"><a href="#twigex-helm-chart">Back to top</a></p>

## ArgoCD Deployment

This chart is compatible with ArgoCD. It does **not** use `lookup()` or random password generation — all passwords must be explicitly set in values.

### Required Values

Set all passwords and secrets in your ArgoCD Application or values file:

```yaml
twigex:
  admin:
    password: "your-secure-admin-password"
  server:
    encryptKey: "your-32-char-hex-key"            # Generate: openssl rand -hex 16

mariadb:
  rootPassword: "your-secure-root-password"
  password: "your-secure-mariadb-password"        # Also used by the Twigex app to connect to DB

redis:
  auth:
    password: "your-redis-password"               # Also used by the Twigex app to connect to Redis
```

### Resource Policy

The following resources have `helm.sh/resource-policy: keep`, so `helm uninstall` leaves them in place:
- `<release>-twigex` Secret — contains all application secrets
- `<release>-mariadb` Secret — contains MariaDB credentials (embedded mode)
- `<release>-twigex-pvc` — application data
- `<release>-mariadb-pvc` — database data (embedded mode)

The cube Secret and the Bitnami Redis Secret have **no** keep annotation and are deleted on uninstall.

> **⚠️ ArgoCD users:** Argo CD honors `helm.sh/resource-policy: keep` only like `Delete=false` (protection when the **Application is deleted**). It does **not** protect resources from pruning. With `syncPolicy.automated.prune: true`, a values change that stops rendering a kept resource — e.g. switching `mariadb.mode` from `embedded` to `external` — will cause Argo CD to **prune the `<release>-mariadb` PVC, deleting your database**. To keep such resources under Argo CD, add `argocd.argoproj.io/sync-options: Prune=false` to them (e.g. via a post-render patch) or set `prune: false` before changing the mode.

### Example ArgoCD Application

Pulls the chart from the public OCI registry `oci://ghcr.io/twigex/helm-charts/twigex` and deploys it to the `twigex` namespace with cert-manager-issued TLS.

```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: twigex
  namespace: argocd
spec:
  project: default
  source:
    repoURL: oci://ghcr.io/twigex/helm-charts
    chart: twigex
    targetRevision: 0.0.35
    helm:
      releaseName: twigex
      valuesObject:
        domain: twigex.example.com
        ingress:
          enabled: true
          ingressClassName: traefik
          tls:
            enabled: true
          certManagerIssuer: letsencrypt-prod   # cert-manager creates <sanitized-domain>
        twigex:
          admin:
            password: "your-secure-admin-password"
          server:
            encryptKey: "a1b2c3d4e5f6a1b2c3d4e5f6a1b2c3d4"   # openssl rand -hex 16
          office:
            enabled: true
            type: collabora   # or eurooffice
            host: https://office.example.com   # required: TWIGEX_OFFICE_* envs are gated on office.host
        mariadb:
          rootPassword: "your-secure-root-password"
          password: "your-secure-mariadb-password"
        redis:
          auth:
            password: "your-redis-password"
  destination:
    server: https://kubernetes.default.svc
    namespace: twigex
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
    syncOptions:
      - CreateNamespace=true
      - ServerSideApply=true
```

**Notes:**
- The chart is published publicly on GHCR — no `imagePullSecrets` or repo credentials required. ArgoCD pulls `oci://ghcr.io/twigex/helm-charts/twigex` anonymously.
- Pin `targetRevision` to a specific chart version (e.g. `0.0.35`) for reproducible deployments. Avoid floating tags like `latest`.
- `domain` is the FQDN used for the app's Site URL, the Ingress host, and the TLS Secret name (resource names like the `<release>-twigex` Deployment derive from the release name). Change it to match your host (e.g. `twigex.example.com`).
- `ingress.certManagerIssuer` triggers the chart to add the `cert-manager.io/cluster-issuer` annotation. The TLS Secret is created automatically by cert-manager, named after the sanitized `domain` (dots replaced by dashes, e.g. `twigex.example.com` → `twigex-example-com`). Replace `letsencrypt-prod` with your actual ClusterIssuer name (use `letsencrypt-staging` for dev to avoid rate limits).
- To use your own TLS Secret with any name instead, set `ingress.tlsExistingSecret` (mutually exclusive with `ingress.certManagerIssuer`).
- `mariadb.password` and `mariadb.rootPassword` are baked into the database on first boot — pick once and don't rotate, or use `mariadb.externalSecret: true` + an external secret manager.
- The chart ships one nginx annotation by default: `nginx.ingress.kubernetes.io/proxy-body-size: "2048m"`, matching the app's 2048 MB public-upload limit (without it, ingress-nginx defaults to 1 MB and large uploads get 413). Override or remove it via `ingress.annotations` in your values file (set the key to `null` to remove); `ingress.customAnnotations` can add or override keys, but null-removal does not work through it. On non-nginx controllers the annotation is cosmetic noise (Traefik ignores it).

### Encrypt Key Generation

```sh
openssl rand -hex 16
```

This produces a 32-character hex string suitable for `twigex.server.encryptKey`.

---

<p align="right"><a href="#twigex-helm-chart">Back to top</a></p>

## License

This Helm chart is licensed under [MIT](LICENSE). The Twigex
application deployed by this chart is licensed separately under
[AGPL-3.0](https://github.com/twigex/twigex/blob/main/LICENSE).

---

## Upgrading

Breaking changes are documented per chart version in [CHANGELOG.md](CHANGELOG.md).
Please read them carefully before upgrading, especially the change of the **default database backend**!
If you miss this, blindly upgrading may delete your MariaDB instance and you may lose your data!
Always backup the `<release>-twigex` and `<release>-mariadb` Secrets.


<p align="right"><a href="#twigex-helm-chart">Back to top</a></p>

For the full per-version history, see [CHANGELOG.md](CHANGELOG.md).

---

Copyright (c) 2026 Twigex. This Helm chart is licensed under [MIT](LICENSE); the Twigex application deployed by it is licensed separately under the [GNU Affero General Public License v3.0 only](https://github.com/twigex/twigex/blob/main/LICENSE).

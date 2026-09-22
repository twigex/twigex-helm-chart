# Twigex Helm Chart

See the [official documentation](https://twigex.com/en/Installation) for setup details.

More info about the project:

- [https://twigex.com](https://twigex.com)
- [https://www.reddit.com/r/twigex/](https://reddit.com/r/twigex)

**Demo:** [Try Twigex in your browser!](https://demo.twigex.com) (Don't post personal stuff. Resets every 30 minutes.)

Username: `twigex`

Password: `twigex`

## ⚠️ Note: This Helm Chart is under active development.
Features and configurations may change as we continue to improve it.
Feel free to try it out, but please use it with care.

## Prerequisites

- Helm v3.8.0 or later
- Kubernetes cluster with a default StorageClass (or create PVs manually)

|> **Note:** Default values are set for a typical Kubernetes installation with the example release name `twigex` (any release name works; addresses are auto-derived). The chart auto-derives Redis (`<release>-redis-master:6379`) and MariaDB (`<release>-mariadb`) addresses from the release name, so a non-default release name works without any extra configuration.

## Installing

### Default (embedded MariaDB)

```sh
helm install twigex oci://ghcr.io/twigex/helm-charts/twigex --version 0.0.35 \
  --namespace twigex \
  --set domain=example.com \
  --set twigex.admin.password=your_password
```

When upgrading, please refer to the [Upgrading](#upgrading) section at the bottom of this document for major and breaking changes.

## Configuration

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

### Twigex Image

| Name | Description | Type | Default |
|------|-------------|------|---------|
| `twigex.image.repository` | Container image repository | string | `ghcr.io/twigex/twigex` |
| `twigex.image.tag` | Container image tag | string | `"latest"` |

### Server

| Name | Description | Type | Default |
|------|-------------|------|---------|
| `twigex.server.port` | Server listen port (used for the container, Service, and Ingress backend) | int | `3000` |
| `twigex.server.defaultLocale` | Default UI locale | string | `"en"` |
| `twigex.server.sessionLengthDays` | Session lifetime in days | int | `30` |
| `twigex.server.encryptKey` | **Exactly 32 hex characters (16 bytes).** Generate with `openssl rand -hex 16`. The chart fails the install at template-render time if this is missing, the wrong length, or contains non-hex characters. ⚠️ Change for production. | string | `"a1b2c3d4e5f6a1b2c3d4e5f6a1b2c3d4"` |
| `twigex.server.tlsCertFile` | Path to TLS cert file (optional) | string | `""` |
| `twigex.server.tlsKeyFile` | Path to TLS key file (optional) | string | `""` |
| `twigex.server.trustedProxies` | Trusted proxy CIDRs (comma-joined into `TWIGEX_TRUSTED_PROXIES`) | list | `[]` |
| `twigex.server.trustedProxyHeaders` | Headers trusted for client IP (comma-joined into `TWIGEX_TRUSTED_PROXY_HEADERS`) | list | `[]` |
| `twigex.server.maxPublicUploadSize` | Max public share-link upload size in MB (app default 2048) | string | `""` |

### Database

| Name | Description | Type | Default |
|------|-------------|------|---------|
| `twigex.db.host` | MariaDB host. Ignored by the chart **unless** mode 2 (External MariaDB) is active — see [External MariaDB](#external-mariadb). In mode 2, this is the external endpoint the Twigex app connects to (required). | string | `"127.0.0.1"` |
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

### Storage

| Name | Description | Type | Default |
|------|-------------|------|---------|
| `twigex.storage.type` | Storage type: `local` or `s3` | string | `"local"` |
| `twigex.storage.name` | Human-readable storage name | string | `"Local storage"` |
| `twigex.storage.endpoint` | S3 endpoint (required if type=s3) | string | `""` |
| `twigex.storage.accessKey` | S3 access key (required if type=s3) | string | `""` |
| `twigex.storage.secretKey` | S3 secret key (required if type=s3) | string | `""` |
| `twigex.storage.bucket` | S3 bucket name | string | `""` |
| `twigex.storage.ssl` | Use SSL for S3 | bool | `true` |

### SMTP

| Name | Description | Type | Default |
|------|-------------|------|---------|
| `twigex.smtp.host` | SMTP server host | string | `"smtp.example.com"` |
| `twigex.smtp.port` | SMTP server port | int | `1025` |
| `twigex.smtp.username` | SMTP username | string | `""` |
| `twigex.smtp.password` | SMTP password | string | `""` |
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
| `twigex.office.host` | Office editor URL. Required when `office.enabled=true`. | string | `"http://localhost:9980"` |
| `twigex.office.secret` | JWT secret if configured on the office editor. | string | `""` |

### Channel (LiveKit / WebRTC)

| Name | Description | Type | Default |
|------|-------------|------|---------|
| `twigex.channel.enabled` | Enable Channel (LiveKit) | bool | `false` |
| `twigex.channel.host` | LiveKit WebSocket URL. Required when `channel.enabled=true`. | string | `"ws://localhost:7880"` |
| `twigex.channel.key` | LiveKit API key | string | `""` |
| `twigex.channel.secret` | LiveKit API secret | string | `""` |
| `twigex.channel.linkPreviews` | Enable link previews in chat | bool | `true` |
| `twigex.channel.gif.enabled` | Enable GIF picker | bool | `false` |
| `twigex.channel.gif.apiKey` | GIF provider API key | string | `""` |


| Name | Description | Type | Default |
|------|-------------|------|---------|

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
| `redis.auth.password` | Redis password. **Used by both the Bitnami Redis subchart and the Twigex app** (via the chart's `twigex-secret.yaml`). | string | `"supersecretpassword"` |
| `redis.master.persistence.enabled` | Enable Redis persistence | bool | `true` |
| `redis.master.persistence.size` | Redis PVC size | string | `"1Gi"` |

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

`mariadb.mode=external` selects external mode. The chart deploys no MariaDB resources in this mode. `twigex.db.host` must be set (the default `127.0.0.1` is rejected). `mariadb.rootPassword` is **not required**. If your credentials live in a user-managed Secret, set `mariadb.externalSecret=true` (which only matters for `mode=embedded` — in `external` mode there's no chart-managed Secret) and `mariadb.existingSecret.{name,keys}` so the chart reads from yours.

---

### MariaDB Configuration

| Name | Description | Type | Default |
|------|-------------|------|---------|
| `mariadb.image.repository` | MariaDB image repository | string | `"mariadb"` |
| `mariadb.mode` | MariaDB topology: `embedded` (default, chart deploys + owns MariaDB + Secret + PVC) / `external` (chart deploys nothing DB-side, point at your pre-existing DB). | string | `"embedded"` |
| `mariadb.password` | MariaDB user password. Also used by the Twigex app to connect. ⚠️ Change for production. **`mariadb.mode=embedded`**: cannot be changed after first boot without reinitializing (data loss). **`mariadb.mode=external`**: rotatable freely. | string | `"mariadb"` |
| `mariadb.rootPassword` | MariaDB root password. Required for `mariadb.mode=embedded`. Skipped for `mariadb.mode=external`. ⚠️ Change for production. | string | `"mariadbroot"` |
| `mariadb.image.tag` | Container image tag. Set to `""` (default) to use `Chart.AppVersion`. | string | `"11"` |
| `mariadb.image.pullPolicy` | Container image pullPolicy. | string | `"IfNotPresent"` |
| `mariadb.persistence.{size,storageClass,accessModes}` | Embedded MariaDB only. The MariaDB StatefulSet's PVC sizing. | object | see `values.yaml` |
| `mariadb.externalSecret` | When `true` (and `mariadb.mode=embedded`), the chart-managed `<release>-mariadb` Secret is skipped and the chart reads credentials from `mariadb.existingSecret.{name,keys}`. Classic External Secrets Operator pattern. | bool | `false` |
| `mariadb.existingSecret.name` | Name of the user-managed Secret (or ref) holding `mariadb-password` and `mariadb-root-password`. | string | `""` |

### External Secret Management

For production deployments using external secret management (e.g. [External Secrets Operator](https://external-secrets.io/), Vault, AWS Secrets Manager), you have two options:

**Option A — Let the chart create secrets, populate from external source:**

Set the password values in your ArgoCD Application or values file. The chart creates the secrets with those values. Your external secret manager syncs to the same secret names.

**Option B — Fully external secrets:**

Set `twigex.externalSecret: true` and/or `mariadb.externalSecret: true`. The chart will **not** create the corresponding secret. You must provide secrets with the expected names and keys:

- `<release>-twigex` — keys: `TWIGEX_ADMIN_PASSWORD`, `TWIGEX_SERVER_ENCRYPT_KEY`, `TWIGEX_DB_PASSWORD`, `TWIGEX_REDIS_PASSWORD`, `TWIGEX_STORAGE_ACCESS_KEY`, `TWIGEX_STORAGE_SECRET_KEY`, `TWIGEX_SMTP_PASSWORD`, `TWIGEX_OFFICE_SECRET`, `TWIGEX_CHANNEL_SECRET`, `TWIGEX_LDAP_BIND_PASSWORD`
- `<release>-mariadb` — keys: `mariadb-password`, `mariadb-root-password`

> **⚠️ Mode `embedded` + ESO:** when you set `mariadb.externalSecret: true` alongside `mariadb.mode=embedded`, the chart skips its own `<release>-mariadb` Secret. You must provide that Secret externally. Its `mariadb-password` key MUST match the `mariadb.password` value, because the Twigex app uses `mariadb.password` (via `twigex-secret.TWIGEX_DB_PASSWORD`) to authenticate. If they drift, the app will fail to connect. In practice, source both from the same ESO Secret.

---

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

> **Note:** The Twigex app's Redis password is sourced from `redis.auth.password` (single source of truth). The `twigex.redis.password` value is deprecated and ignored.

### Resource Policy

The following resources have `helm.sh/resource-policy: keep` to prevent ArgoCD from deleting them during prune/sync:
- `<release>-twigex` Secret — contains all application secrets
- `<release>-mariadb` Secret — contains MariaDB credentials
- `twigex-pvc` — application data
- `mariadb-pvc` — database data
- RBAC Role and RoleBinding

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
            type: collabora   # or eurooffice
        mariadb:
          enabled: true
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
- `domain` is the FQDN used for the Twigex app Deployment and TLS Secret name and the cert-manager TLS secret name. Change it to match your host (e.g. `twigex.example.com`).
- `ingress.certManagerIssuer` triggers the chart to add the `cert-manager.io/cluster-issuer` annotation. The TLS Secret is created automatically by cert-manager, named after the sanitized `domain` (dots replaced by dashes, e.g. `twigex.example.com` → `twigex-example-com`). You do **not** need to set `ingress.tls[].secretName`. Replace `letsencrypt-prod` with your actual ClusterIssuer name (use `letsencrypt-staging` for dev to avoid rate limits).
- `mariadb.password` and `mariadb.rootPassword` are baked into the database on first boot — pick once and don't rotate, or use `mariadb.externalSecret: true` + an external secret manager.
- The chart bakes nginx-specific annotations into its `values.yaml` defaults (`nginx.ingress.kubernetes.io/proxy-body-size`, `nginx.ingress.kubernetes.io/enable-cors`). They cannot be cleared from a user values file — `ingress.annotations: {}` is rejected by Helm as "cannot overwrite table with non table", and `customAnnotations` only **adds** keys, it does not remove or override existing ones. The annotations are cosmetic noise on non-nginx controllers (Traefik ignores them). To get rid of them, patch the chart or add a post-render hook in ArgoCD (`kubectl patch ingress <name> --type=json -p '[{"op":"remove","path":"/metadata/annotations/nginx.ingress.kubernetes.io~1proxy-body-size"}, ...]'`).

### Encrypt Key Generation

```sh
openssl rand -hex 16
```

This produces a 32-character hex string suitable for `twigex.server.encryptKey`.

---

## License

This Helm chart is licensed under [MIT](LICENSE.txt). The Twigex
application deployed by this chart is licensed separately under
[AGPL-3.0](https://github.com/twigex/twigex/blob/main/LICENSE).

---

## Upgrading

This section lists major and breaking changes of each Helm Chart version.
Please read them carefully to upgrade successfully, especially the change of the **default database backend**!
If you miss this, blindly upgrading may delete your MariaDB instance and you may lose your data!
Always backup `twigex-secret` and `mariadb-secret`.

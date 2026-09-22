# Security Policy

## Supported versions

Only the latest released chart version is supported with security fixes.
Older chart versions may receive fixes at the maintainers' discretion —
upgrade to the newest version before reporting an issue.

| Chart version | Supported |
|---------------|-----------|
| latest `0.0.x` on `oci://ghcr.io/twigex/helm-charts/twigex` | ✅ |
| older versions | ❌ |

## Reporting a vulnerability

**Please do not report security vulnerabilities through public GitHub issues.**

Use GitHub's private vulnerability reporting on this repository
(**Security → Report a vulnerability**), or contact the maintainers via
[https://twigex.com](https://twigex.com).

Include as much of the following as you can:

- Chart version (`Chart.yaml` → `version`) and app version (`appVersion`)
- The affected values (see **Never include secrets** below)
- `helm template` output demonstrating the issue
- Kubernetes version and distribution (k3s, RKE2, Talos, EKS, ...)

We will acknowledge reports within a few business days and keep you informed
of progress toward a fix and release.

## Never include secrets in issues or reports

Public issue reports must be sanitized. This chart manages several
security-sensitive values — if any of these leak, treat them as compromised
and rotate:

- `twigex.server.encryptKey` — the data-at-rest encryption key
  (32 hex chars). Rotating it invalidates all encrypted data in the
  database, so protect it accordingly.
- `twigex.admin.password`, `mariadb.password`, `mariadb.rootPassword`
- `redis.auth.password`
- `cube.apiSecret`, `cube.callbackSecret`
- Storage / SMTP / LDAP / OAuth credentials (`twigex.storage.*`,
  `twigex.smtp.*`, `twigex.ldap.*`)

Replace them with obvious placeholders (`CHANGE_ME`, `REDACTED`) before
posting. When redacting `helm template` output, remember the rendered
Secret manifests contain the same values.

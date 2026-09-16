## Summary

<!-- What does this PR change and why? One or two sentences. -->

## Type of change

- [ ] Bug fix (non-breaking)
- [ ] New values key / feature
- [ ] Breaking change (fix or feature that changes existing values semantics)
- [ ] Documentation only

## Checklist

- [ ] `helm lint .` passes
- [ ] `helm template` renders with required values (domain, admin password, encryptKey, redis/mariadb passwords) — and with the feature flags this PR touches (`mariadb.mode=external`, `ingress.*`, `gateway.*`, `cube.enabled=true`) where relevant
- [ ] Real cluster install/upgrade verified for changes to rendered resources
- [ ] No secrets committed; no `lookup()` or `rand*` functions added to templates
- [ ] `README.md` / `INSTALLATION.md` / `CHANGELOG.md` updated for any values change (breaking changes noted in Changelog)

## Render evidence

<!-- Paste the relevant `helm template` excerpt (no Secret payloads) or a
short kubectl get output demonstrating the change works. -->

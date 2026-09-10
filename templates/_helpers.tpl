{{- define "chart.fullname" -}}
{{- if .Values.fullnameOverride -}}
{{- .Values.fullnameOverride -}}
{{- else -}}
{{- printf "%s-%s" .Release.Name .Chart.Name -}}
{{- end -}}
{{- end -}}

{{- define "ingress.annotations" -}}
{{- toYaml (merge .Values.ingress.annotations .Values.ingress.customAnnotations) -}}
{{- end -}}

{{- define "twigex.mariadbRootPassword" -}}
{{- .Values.mariadb.rootPassword | b64enc -}}
{{- end -}}

{{- define "twigex.mariadbPassword" -}}
{{- .Values.mariadb.password | b64enc -}}
{{- end -}}

{{- define "twigex.mariadbPasswordPlain" -}}
{{- .Values.mariadb.password -}}
{{- end -}}

{{- define "twigex.validate" -}}

{{/* 1. domain must be a non-empty DNS-1035-compatible hostname */}}
{{- if not .Values.domain -}}
{{- fail "domain is required (FQDN where the app will be served)" -}}
{{- end -}}
{{- if not (regexMatch "^[a-z0-9]([-a-z0-9]{0,61}[a-z0-9])?([.][a-z0-9]([-a-z0-9]{0,61}[a-z0-9])?)+$" .Values.domain) -}}
{{- fail (printf "domain %q must be a valid lowercase DNS-1035 / DNS-1123 hostname (RFC 1123)" .Values.domain) -}}
{{- end -}}

{{/* 2. encryptKey must be 32 hex chars */}}
{{- $key := .Values.twigex.server.encryptKey -}}
{{- if eq (len $key) 0 -}}
{{- fail "twigex.server.encryptKey is required. Generate one with: openssl rand -hex 16" -}}
{{- end -}}
{{- if ne (len $key) 32 -}}
{{- fail (printf "twigex.server.encryptKey must be exactly 32 hex characters (got %d). Generate with: openssl rand -hex 16" (len $key)) -}}
{{- end -}}
{{- if not (regexMatch "^[0-9a-fA-F]{32}$" $key) -}}
{{- fail (printf "twigex.server.encryptKey must contain only hex characters [0-9a-fA-F] (got %d chars). Generate with: openssl rand -hex 16" (len $key)) -}}
{{- end -}}

{{/* 3. admin password required when admin.enabled and not externalSecret */}}
{{- if and .Values.twigex.admin.enabled (not .Values.twigex.externalSecret) -}}
{{- if not .Values.twigex.admin.password -}}
{{- fail "twigex.admin.password is required when twigex.admin.enabled=true and twigex.externalSecret=false" -}}
{{- end -}}
{{- end -}}

{{/* 4. mariadb.password/rootPassword required when mode=embedded */}}
{{- if eq .Values.mariadb.mode "embedded" -}}
{{- if not .Values.mariadb.password -}}
{{- fail "mariadb.password is required when mariadb.mode=embedded" -}}
{{- end -}}
{{- if not .Values.mariadb.rootPassword -}}
{{- fail "mariadb.rootPassword is required when mariadb.mode=embedded" -}}
{{- end -}}
{{- end -}}



{{/* 5. mariadb.mode must be one of the supported values */}}
{{- if not (or (eq .Values.mariadb.mode "embedded") (eq .Values.mariadb.mode "external")) -}}
{{- fail (printf "mariadb.mode must be one of embedded|external; got %q" .Values.mariadb.mode) -}}
{{- end -}}

{{/* 6. mode=external requires twigex.db.host */}}
{{- if eq .Values.mariadb.mode "external" -}}
{{- if not .Values.twigex.db.host -}}
{{- fail "twigex.db.host is required when mariadb.mode=external" -}}
{{- end -}}
{{- if eq .Values.twigex.db.host "127.0.0.1" -}}
{{- fail "twigex.db.host must be a real external endpoint (got the default 127.0.0.1)" -}}
{{- end -}}
{{- end -}}

{{/* 8. Redis password required */}}
{{- if not .Values.redis.auth.password -}}
{{- fail "redis.auth.password is required" -}}
{{- end -}}

{{/* 9. MySQL identifiers */}}
{{- if not .Values.twigex.db.user -}}
{{- fail "twigex.db.user is required (MySQL user identifier)" -}}
{{- end -}}
{{- if not .Values.twigex.db.name -}}
{{- fail "twigex.db.name is required (MySQL database identifier)" -}}
{{- end -}}

{{/* 10. cube: apiSecret / callbackSecret OR existingSecret.name */}}
{{- if .Values.cube.enabled -}}
{{- if not .Values.cube.existingSecret.name -}}
{{- if not .Values.cube.apiSecret -}}
{{- fail "cube.apiSecret is required when cube.enabled=true and cube.existingSecret.name is not set" -}}
{{- end -}}
{{- if not .Values.cube.callbackSecret -}}
{{- fail "cube.callbackSecret is required when cube.enabled=true and cube.existingSecret.name is not set" -}}
{{- end -}}
{{- end -}}
{{- if .Values.cube.internalUrl -}}
{{- if not (regexMatch "^https?://[^ ]+$" .Values.cube.internalUrl) -}}
{{- fail (printf "cube.internalUrl %q must be a valid http(s):// URL" .Values.cube.internalUrl) -}}
{{- end -}}
{{- end -}}
{{- end -}}

{{/* 11. strategy enum */}}
{{- if not (or (eq .Values.twigex.strategy "Recreate") (eq .Values.twigex.strategy "RollingUpdate")) -}}
{{- fail (printf "twigex.strategy must be Recreate|RollingUpdate; got %q" .Values.twigex.strategy) -}}
{{- end -}}

{{/* 12. service.type enum */}}
{{- if not (or (eq .Values.twigex.service.type "ClusterIP") (eq .Values.twigex.service.type "NodePort") (eq .Values.twigex.service.type "LoadBalancer")) -}}
{{- fail (printf "twigex.service.type must be ClusterIP|NodePort|LoadBalancer; got %q" .Values.twigex.service.type) -}}
{{- end -}}
{{- if and (eq .Values.twigex.service.type "NodePort") (not .Values.twigex.service.nodePort) -}}
{{- fail "twigex.service.nodePort is required when twigex.service.type=NodePort" -}}
{{- end -}}

{{/* 13. Service port sanity */}}
{{- if or (lt (int .Values.twigex.service.port) 1) (gt (int .Values.twigex.service.port) 65535) -}}
{{- fail (printf "twigex.service.port %d out of range" (int .Values.twigex.service.port)) -}}
{{- end -}}
{{- if or (lt (int .Values.twigex.service.targetPort) 1) (gt (int .Values.twigex.service.targetPort) 65535) -}}
{{- fail (printf "twigex.service.targetPort %d out of range" (int .Values.twigex.service.targetPort)) -}}
{{- end -}}

{{/* 14. pdb: only one of minAvailable / maxUnavailable */}}
{{- $a := .Values.twigex.pdb.minAvailable -}}
{{- $b := .Values.twigex.pdb.maxUnavailable -}}
{{- if and (and $a $a | toString) (and $b $b | toString) -}}
{{- fail "twigex.pdb: only one of minAvailable or maxUnavailable may be set, not both" -}}
{{- end -}}

{{- end -}}

{{- define "twigex.commonLabels" -}}
app.kubernetes.io/name: twigex
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/managed-by: Helm
helm.sh/chart: {{ printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" | quote }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end -}}

{{- define "cube.fullSecretName" -}}
{{- if .Values.cube.existingSecret.name -}}
{{- .Values.cube.existingSecret.name -}}
{{- else -}}
{{- printf "%s-cube-secret" .Release.Name -}}
{{- end -}}
{{- end -}}


{{- define "twigex.secretName" -}}
{{- if .Values.twigex.existingSecret.name -}}
{{- .Values.twigex.existingSecret.name -}}
{{- else -}}
{{- printf "%s-twigex" .Release.Name -}}
{{- end -}}
{{- end -}}

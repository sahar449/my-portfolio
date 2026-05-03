{{/*
Returns the app name
*/}}
{{- define "backend.name" -}}
{{ .Values.app.name }}
{{- end }}

{{/*
Common labels applied to all resources
*/}}
{{- define "backend.labels" -}}
app: {{ include "backend.name" . }}
helm.sh/chart: {{ .Chart.Name }}-{{ .Chart.Version }}
app.kubernetes.io/name: {{ include "backend.name" . }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels — used in matchLabels and topologySpreadConstraints
*/}}
{{- define "backend.selectorLabels" -}}
app: {{ include "backend.name" . }}
{{- end }}

{{/*
Full image reference: repository:tag
*/}}
{{- define "backend.image" -}}
{{ .Values.app.image.repository }}:{{ .Values.app.image.tag }}
{{- end }}

{{/*
Pod-level security context
*/}}
{{- define "backend.podSecurityContext" -}}
runAsNonRoot: true
runAsUser: {{ .Values.app.securityContext.runAsUser }}
runAsGroup: {{ .Values.app.securityContext.runAsGroup }}
fsGroup: {{ .Values.app.securityContext.fsGroup }}
seccompProfile:
  type: {{ .Values.app.securityContext.seccompProfile.type }}
{{- end }}

{{/*
Container-level security context
*/}}
{{- define "backend.containerSecurityContext" -}}
allowPrivilegeEscalation: {{ .Values.app.containerSecurityContext.allowPrivilegeEscalation }}
capabilities:
  drop: {{ toYaml .Values.app.containerSecurityContext.capabilities.drop | nindent 2 }}
{{- end }}

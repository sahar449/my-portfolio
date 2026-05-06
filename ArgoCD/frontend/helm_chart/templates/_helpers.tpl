{{/*
Returns the app name
*/}}
{{- define "frontend.name" -}}
{{ .Values.app.name }}
{{- end }}

{{/*
Common labels applied to all resources
*/}}
{{- define "frontend.labels" -}}
app: {{ include "frontend.name" . }}
helm.sh/chart: {{ .Chart.Name }}-{{ .Chart.Version }}
app.kubernetes.io/name: {{ include "frontend.name" . }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels — used in matchLabels and topologySpreadConstraints
*/}}
{{- define "frontend.selectorLabels" -}}
app: {{ include "frontend.name" . }}
{{- end }}

{{/*
Full image reference: repository:tag
*/}}
{{- define "frontend.image" -}}
{{- required "app.image.repository must be set by CD" .Values.app.image.repository }}:{{- required "app.image.tag must be set by CD" .Values.app.image.tag }}
{{- end }}

{{/*
Pod-level security context
*/}}
{{- define "frontend.podSecurityContext" -}}
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
{{- define "frontend.containerSecurityContext" -}}
allowPrivilegeEscalation: {{ .Values.app.containerSecurityContext.allowPrivilegeEscalation }}
capabilities:
  drop: {{ toYaml .Values.app.containerSecurityContext.capabilities.drop | nindent 2 }}
{{- end }}

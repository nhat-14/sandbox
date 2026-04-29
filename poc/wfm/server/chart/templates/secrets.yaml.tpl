{{- if .Values.secrets.create }}
apiVersion: v1
kind: Secret
metadata:
  name: {{ include "wfmchart.certsecretname" . }}
  namespace: {{ include "wfmchart.namespace" . }}
  labels:
    {{- include "wfmchart.labels" . | nindent 4 }}
type: Opaque
data:
  registry-ca.pem: {{ .Values.secrets.registryCA | b64enc }}
  registry-cert.pem: {{ .Values.secrets.registryCert | b64enc }}
  registry-key.pem: {{ .Values.secrets.registryKey | b64enc }}
  server-ca.pem: {{ .Values.secrets.symphonyCA | b64enc }}
  server-cert.pem: {{ .Values.secrets.symphonyCert | b64enc }}
  server-key.pem: {{ .Values.secrets.symphonyKey | b64enc }}
{{- end }}

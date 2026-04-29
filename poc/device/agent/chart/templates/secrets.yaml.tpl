{{- if .Values.secrets.create }}
apiVersion: v1
kind: Secret
metadata:
  name: {{ include "agentchart.certsecretname" . }}
  namespace: {{ include "agentchart.namespace" . }}
type: Opaque
data:
  device-ca.pem: {{ .Values.secrets.deviceCA | b64enc }}
  device-cert.pem: {{ .Values.secrets.deviceCert | b64enc }}
  device-key.pem: {{ .Values.secrets.deviceKey | b64enc }}
{{- end }}

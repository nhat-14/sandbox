{{- if not .Values.config.existingConfigMap }}
apiVersion: v1
kind: ConfigMap
metadata:
  name: {{ include "device-agent.fullname" . }}-config
  labels:
    {{- include "device-agent.labels" . | nindent 4 }}
data:
  config.yaml: |
    {{- .Values.config.configYaml | nindent 4 }}
{{- end }}

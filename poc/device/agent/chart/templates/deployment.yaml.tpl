apiVersion: apps/v1
kind: Deployment
metadata:
  name: {{ include "device-agent.fullname" . }}
  labels:
    {{- include "device-agent.labels" . | nindent 4 }}
spec:
  replicas: 1
  selector:
    matchLabels:
      {{- include "device-agent.selectorLabels" . | nindent 6 }}
  template:
    metadata:
      labels:
        {{- include "device-agent.selectorLabels" . | nindent 8 }}
    spec:
      {{- if .Values.serviceAccount.create }}
      serviceAccountName: {{ include "device-agent.serviceAccountName" . }}
      {{- end }}
      securityContext:
        {{- toYaml .Values.podSecurityContext | nindent 8 }}
      containers:
      - name: device-agent
        image: "{{ .Values.image.repository }}:{{ .Values.image.tag }}"
        imagePullPolicy: {{ .Values.image.pullPolicy }}
        command:
        - /app/device-agent
        args:
        - -config
        - /app/config/config.yaml
        securityContext:
          {{- toYaml .Values.securityContext | nindent 10 }}
        resources:
          {{- toYaml .Values.resources | nindent 10 }}
        volumeMounts:
        - name: agent-data
          mountPath: /app/data
        {{- if .Values.kubeconfigPath }}
        - name: kubeconfig
          mountPath: {{.Values.kubeconfigPath}}
        {{- end }}
        - name: config
          mountPath: /app/config
          readOnly: true
        - name: certs
          mountPath: /app/certs/device-private.key
          subPath: device-private.key
          readOnly: true
        - name: certs
          mountPath: /app/certs/device-public.crt
          subPath: device-public.crt
          readOnly: true
        - name: certs
          mountPath: /app/certs/ca.crt
          subPath: ca.crt
          readOnly: true
        {{- if .Values.certFiles.wfmCaCrt }}
        - name: certs
          mountPath: /app/certs/wfm-ca.crt
          subPath: wfm-ca.crt
          readOnly: true
        {{- end }}
        {{- if .Values.certFiles.registryCaCrt }}
        - name: certs
          mountPath: /app/certs/registry-ca.crt
          subPath: registry-ca.crt
          readOnly: true
        {{- end }}
      volumes:
      - name: agent-data
        {{- if .Values.persistence.enabled }}
        persistentVolumeClaim:
          claimName: {{ .Values.persistence.existingClaim | default (printf "%s-data" (include "device-agent.fullname" .)) }}
        {{- else }}
        emptyDir: {}
        {{- end }}
      {{- if .Values.kubeconfigPath }}
      - name: kubeconfig
        hostPath:
          path: {{ .Values.kubeconfigPath }}
      {{- end }}
      - name: config
        configMap:
          name: {{ .Values.config.existingConfigMap | default (printf "%s-config" (include "device-agent.fullname" .)) }}
      - name: certs
        secret:
          secretName: {{ include "device-agent.certSecretName" . }}
          defaultMode: 0600
      {{- with .Values.nodeSelector }}
      nodeSelector:
        {{- toYaml . | nindent 8 }}
      {{- end }}
      {{- with .Values.affinity }}
      affinity:
        {{- toYaml . | nindent 8 }}
      {{- end }}
      {{- with .Values.tolerations }}
      tolerations:
        {{- toYaml . | nindent 8 }}
      {{- end }}

{{- if .Values.registry.persistence.size }}
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: registry-data
  namespace: {{ include "wfmchart.namespace" . }}
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: {{ .Values.registry.persistence.size }}
{{- end }}
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: registry
  namespace: {{ include "wfmchart.namespace" . }}
spec:
  selector:
    matchLabels:
      app: registry
  template:
    metadata:
      labels:
        app: registry
    spec:
      containers:
      - name: registry
        image: {{ .Values.registry.image }} # Fixed: points to registry block
        imagePullPolicy: {{ .Values.registry.imagePullPolicy }}
        ports:
        - containerPort: 5000
        env:
        # Registry expects the path to the actual file, not just the directory
        - name: REGISTRY_HTTP_TLS_CERTIFICATE
          value: /run/secrets/tls.crt
        - name: REGISTRY_HTTP_TLS_KEY
          value: /run/secrets/tls.key
        volumeMounts:
        - name: registry-storage
          mountPath: /var/lib/registry
        # Mount the specific keys from the secret to the expected paths
        - name: certs
          mountPath: /run/secrets/tls.crt
          subPath: registry-cert.pem
        - name: certs
          mountPath: /run/secrets/tls.key
          subPath: registry-key.pem
      volumes:
      - name: registry-storage
        {{- if .Values.registry.persistence.size }}
        persistentVolumeClaim:
          claimName: registry-data
        {{- else }}
          emptyDir: {}
        {{- end }}
      - name: certs
        secret:
          secretName: {{ include "wfmchart.certsecretname" . }}
---
apiVersion: v1
kind: Service
metadata:
  name: registry
spec:
  type: NodePort
  selector:
    app: registry
  ports:
    - protocol: TCP
      port: 5000
      targetPort: 5000 # Port the registry container is listening on
      nodePort: 30500  # Port accessible from your host/external IP (30000-32767)
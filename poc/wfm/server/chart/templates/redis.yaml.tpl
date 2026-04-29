{{- if .Values.redis.persistence.size }}
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: redis-data
  namespace: {{ include "wfmchart.namespace" . }}
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: {{ .Values.redis.persistence.size }}
{{- end }}
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: redis
spec:
  selector:
    matchLabels:
      app: redis
  template:
    metadata:
      labels:
        app: redis
    spec:
      containers:
      - name: redis
        image: {{ .Values.redis.image }} # Fixed path
        imagePullPolicy: {{ .Values.redis.imagePullPolicy }}
        ports:
        - containerPort: {{ .Values.redis.port }}
        livenessProbe:
          exec:
            command: ["redis-cli", "ping"]
          initialDelaySeconds: 5
          periodSeconds: 5
        volumeMounts:
        - name: redis-data
          mountPath: /data
      volumes:
      - name: redis-data
      {{- if .Values.redis.persistence.size }}
        persistentVolumeClaim:
          claimName: redis-data
      {{- else }}
        emptyDir: {}
      {{- end }}
---
apiVersion: v1
kind: Service
metadata:
  name: redis
spec:
  selector:
    app: redis
  ports:
    - protocol: TCP
      port: 6379
      targetPort: 6379

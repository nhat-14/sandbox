apiVersion: apps/v1
kind: Deployment
metadata:
  name: symphony-api
  namespace: {{ include "wfmchart.namespace" . }}
spec:
  replicas: 1
  selector:
    matchLabels:
      app: symphony-api
  template:
    metadata:
      labels:
        app: symphony-api
    spec:
      containers:
        - name: symphony-api
          image: {{ .Values.symphonyApi.image }}
          imagePullPolicy: {{ .Values.symphonyApi.imagePullPolicy }}
          ports:
            - containerPort: 8082
          env:
            - name: LOG_LEVEL
              value: {{ .Values.symphonyApi.logLevel | quote }}
            - name: CONFIG
              value: {{ .Values.symphonyApi.configName | quote }}
          volumeMounts:
            - name: certs
              mountPath: /usr/local/share/ca-certificates/ca-cert.pem
              subPath: registry-ca.pem
            - name: certs
              mountPath: /certificates/
              readOnly: true
          command: ["sh", "-c"]
          args:
            - |
              update-ca-certificates 2>/dev/null || true;
              # Replace localhost with the Kubernetes service name in the config file
              # NOTE: a quick shortcut for now to fix the redis connectiong string
              sed -i 's/localhost:6379/redis:6379/g' {{ .Values.symphonyApi.configName }};
              exec /symphony-api -c {{ .Values.symphonyApi.configName }}
      volumes:
        - name: certs
          secret:
            secretName: {{ include "wfmchart.fullname" . }}-certs
---
apiVersion: v1
kind: Service
metadata:
  name: symphony
spec:
  type: NodePort
  selector:
    app: symphony-api
  ports:
    - protocol: TCP
      port: 8082
      targetPort: 8082 # Port the symphony container is listening on
      nodePort: 30501  # Port accessible from your host/external IP (30000-32767)
{{- if and .Values.certificates.generate (not .Values.certificates.existingSecret) }}
apiVersion: batch/v1
kind: Job
metadata:
  name: {{ include "device-agent.fullname" . }}-init-certs
  labels:
    {{- include "device-agent.labels" . | nindent 4 }}
  annotations:
    "helm.sh/hook": pre-install,pre-upgrade
    "helm.sh/hook-weight": "-5"
    "helm.sh/hook-delete-policy": before-hook-creation
spec:
  template:
    metadata:
      name: {{ include "device-agent.fullname" . }}-init-certs
    spec:
      restartPolicy: Never
      containers:
      - name: init-certs
        image: alpine/openssl:latest
        imagePullPolicy: IfNotPresent
        env:
        - name: CERT_VALIDITY_DAYS
          value: {{ .Values.certificates.validityDays | quote }}
        - name: CLIENT_NAME
          value: {{ .Values.certificates.clientName | quote }}
        command:
        - /bin/sh
        - -c
        - |
          # Check if certificates already exist in secret
          if [ -f /certs/device-private.key ] && [ -f /certs/ca.key ]; then
            echo "✅ Certificates already exist"
            exit 0
          fi

          echo "🔐 Generating device certificates..."

          # Generate CA
          openssl genrsa -out /certs/ca.key 4096
          openssl req -new -x509 -days $CERT_VALIDITY_DAYS \
            -key /certs/ca.key -out /certs/ca.crt \
            -subj "/C=IN/ST=GGN/L=Sector 48/O=Margo/CN=Margo Root CA"

          # Generate Device Certificate
          cat > /tmp/client-cert.conf <<EOF
          [req]
          default_bits = 4096
          prompt = no
          default_md = sha256
          distinguished_name = dn
          req_extensions = v3_req

          [dn]
          C=IN
          ST=GGN
          L=Sector 48
          O=Margo
          CN=$CLIENT_NAME

          [v3_req]
          basicConstraints = CA:FALSE
          keyUsage = keyEncipherment, digitalSignature
          extendedKeyUsage = clientAuth
          EOF

          openssl genrsa -out /certs/device-private.key 4096
          openssl req -new -key /certs/device-private.key \
            -out /tmp/client.csr -config /tmp/client-cert.conf
          openssl x509 -req -in /tmp/client.csr \
            -CA /certs/ca.crt -CAkey /certs/ca.key \
            -CAcreateserial -out /certs/device-public.crt \
            -days $CERT_VALIDITY_DAYS \
            -extensions v3_req -extfile /tmp/client-cert.conf

          # Set restrictive permissions
          chmod 600 /certs/ca.key /certs/device-private.key
          chmod 644 /certs/ca.crt /certs/device-public.crt

          echo "✅ Device certificates generated"
        volumeMounts:
        - name: certs
          mountPath: /certs
      volumes:
      - name: certs
        emptyDir: {}
{{- end }}

1. Install K3s/Docker(good, if you already have them)

2. Install Symphony Stack/HELM
  {WFM_IP: ..., WFM_PORT: ..., REGISTRY_IP: ..., REGISTRY_PORT: ...}

3. Copy the certs to a directory using command:
  ....

4. Install Observability Backend Stack
  {SCRAPE_IP: ..., SCRAPE_PORT: ...}

---

5. Copy the WFM and Registry CA to device/certs

6. Modify the config file as per the need.

7. Then run the device agent:

# Modify the config file, then run the following

helm install device-agent ./device-agent \
  --set certificates.generate=true \
  --set kubeconfigPath=/root/.kube/config \
  --set image.repository= \
  --set image.tag=latest \
  --set-file externalCertFiles.wfmCaCrt=$(cat wfmcapath) \
  --set-file externalCertFiles.registryCaCrt=$(cat registrycapath) \
  --set-file config.configYAML=$(cat config) \
  --debug \
  --wait

8. Install Observability Collector Stack


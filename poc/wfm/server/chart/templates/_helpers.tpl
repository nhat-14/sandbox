{{- define "wfmchart.fullname" -}}
{{- .Release.Name | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "wfmchart.namespace" -}}
{{- .Release.Namespace -}}
{{- end -}}

{{- define "wfmchart.deploymentname" -}}
{{- printf "%s-deploy" (include "wfmchart.fullname" .) | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "wfmchart.podname" -}}
{{- printf "%s-pod" (include "wfmchart.fullname" .) | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "wfmchart.configmapname" -}}
{{- printf "%s-cm" (include "wfmchart.fullname" .) | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "wfmchart.certsecretname" -}}
{{- printf "%s-certs" (include "wfmchart.fullname" .) | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "wfmchart.pvcname" -}}
{{- printf "%s-data" (include "wfmchart.fullname" .) | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "wfmchart.serviceaccountname" -}}
{{- printf "%s-sa" (include "wfmchart.fullname" .) | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "wfmchart.rolename" -}}
{{- printf "%s-role" (include "wfmchart.fullname" .) | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "wfmchart.rolebindingname" -}}
{{- printf "%s-binding" (include "wfmchart.fullname" .) | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "wfmchart.k8ssecret" -}}
{{- .Values.kubeconfig.secretName -}}
{{- end -}}

{{/* Common labels */}}
{{- define "wfmchart.labels" -}}
app.kubernetes.io/name: {{ .Chart.Name }}
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
helm.sh/chart: {{ printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end -}}

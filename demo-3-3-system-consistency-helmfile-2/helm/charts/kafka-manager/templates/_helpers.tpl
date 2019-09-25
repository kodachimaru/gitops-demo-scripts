{{/*
Expand the name of the chart.
*/}}
{{- define "kafka-manager.app-name" -}}
{{- .Values.app | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "kafka-manager.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Create the kafka-manager zookeeper hosts url.
*/}}
{{- define "kafka-manager.zkHosts" -}}
{{- tpl .Values.zkHosts . -}}
{{- end -}}


{{/*
Kube resource names according to naming conventions
*/}}

{{- define "kafka-manager.kube-resource-suffix" -}}
{{- printf "%s-%s" .Release.Namespace .Values.app }}
{{- end -}}

{{- define "kafka-manager.secret-name" -}}
{{- printf "sec-%s" (include "kafka-manager.kube-resource-suffix" .) | replace "+" "_" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "kafka-manager.service-name" -}}
{{- printf "svc-%s" (include "kafka-manager.kube-resource-suffix" .) | replace "+" "_" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "kafka-manager.deployment-name" -}}
{{- printf "dpl-%s" (include "kafka-manager.kube-resource-suffix" .) | replace "+" "_" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "kafka-manager.ingress-name" -}}
{{- printf "ing-%s" (include "kafka-manager.kube-resource-suffix" .) | replace "+" "_" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "kafka-manager.bootstrap-job-name" -}}
{{- printf "job-%s-bootstrap" (include "kafka-manager.kube-resource-suffix" .) | replace "+" "_" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "kafka-manager.bootstrap-configmap-name" -}}
{{- printf "cfg-%s" (include "kafka-manager.kube-resource-suffix" .) | replace "+" "_" | trunc 63 | trimSuffix "-" -}}
{{- end -}}


{{/*
    Convenience global templates
*/}}

{{- define "kafka-manager.service-base-url" -}}
{{- printf "http://%s:%.0f" (include "kafka-manager.service-name" .) (.Values.service.port) -}}
{{- end -}}

{{- define "kafka-manager.test-pod-name" -}}
{{- $test_template_file_name_no_ext := (.Template.Name | regexFind "[^/]+$" | regexFind "^[^.]+") -}}
{{- printf "test-%s-r%d-%s" (include "kafka-manager.kube-resource-suffix" .) (.Release.Revision) $test_template_file_name_no_ext | replace "+" "-" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

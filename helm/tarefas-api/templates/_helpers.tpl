{{- define "tarefas-api.labels" -}}
app.kubernetes.io/name: {{ .Chart.Name }}
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/version: {{ .Values.appVersion | quote }}
{{- end }}

{{- define "tarefas-api.image" -}}
{{- if .Values.image.digest -}}
{{ .Values.image.repository }}@{{ .Values.image.digest }}
{{- else -}}
{{ fail "image.digest é obrigatório: produção roda o digest testado, nunca uma tag móvel" }}
{{- end -}}
{{- end }}

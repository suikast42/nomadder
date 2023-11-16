{{range services -}}
{{ $serviceName := .Name -}}
{{range service $serviceName -}}
{{ if contains "traefik.enable=true" .Tags -}}
{{ .Address }} {{ .Name }}.cloud.private
{{ end -}}
{{ if eq "keycloak-sidecar-proxy" .Name -}}
{{ .Address }} security.cloud.private
{{ end -}}
{{ end -}}
{{end -}}
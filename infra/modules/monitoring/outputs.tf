output "amp_endpoint" {
  value = aws_prometheus_workspace.main.prometheus_endpoint
}

output "amp_ingest_role_arn" {
  value = aws_iam_role.amp_ingest.arn
}

output "grafana_endpoint" {
  value = aws_grafana_workspace.main.endpoint
}

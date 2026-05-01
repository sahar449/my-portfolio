output "log_group_application" {
  value = aws_cloudwatch_log_group.application.name
}

output "log_group_performance" {
  value = aws_cloudwatch_log_group.performance.name
}

output "cloudwatch_url" {
  value = "https://${var.region}.console.aws.amazon.com/cloudwatch/home?region=${var.region}#container-insights:infrastructure"
}

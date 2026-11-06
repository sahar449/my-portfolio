resource "aws_cloudwatch_log_group" "application" {
  name              = "/aws/containerinsights/${var.cluster_name}/application"
  retention_in_days = 7
  tags              = { Name = "${var.name_prefix}-app-logs" }
}

resource "aws_cloudwatch_log_group" "performance" {
  name              = "/aws/containerinsights/${var.cluster_name}/performance"
  retention_in_days = 7
  tags              = { Name = "${var.name_prefix}-perf-logs" }
}

resource "aws_eks_addon" "cloudwatch_observability" {
  cluster_name             = var.cluster_name
  addon_name               = "amazon-cloudwatch-observability"
  service_account_role_arn = var.cloudwatch_agent_role_arn
  depends_on               = [aws_cloudwatch_log_group.application, aws_cloudwatch_log_group.performance]
}


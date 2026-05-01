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

resource "aws_iam_role" "cloudwatch_agent" {
  name = "${var.name_prefix}-cloudwatch-agent-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Federated = var.oidc_provider_arn }
      Action    = "sts:AssumeRoleWithWebIdentity"
      Condition = {
        StringEquals = {
          "${var.oidc_provider_url}:sub" = "system:serviceaccount:amazon-cloudwatch:cloudwatch-agent"
        }
      }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "cloudwatch_agent" {
  role       = aws_iam_role.cloudwatch_agent.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
}

resource "aws_eks_addon" "cloudwatch_observability" {
  cluster_name             = var.cluster_name
  addon_name               = "amazon-cloudwatch-observability"
  service_account_role_arn = aws_iam_role.cloudwatch_agent.arn
  depends_on               = [aws_cloudwatch_log_group.application, aws_cloudwatch_log_group.performance]
}

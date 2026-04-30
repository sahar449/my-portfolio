terraform {
  required_providers {
    aws = {
      source                = "hashicorp/aws"
      version               = ">= 5.100.0"
      configuration_aliases = [aws.sso]
    }
  }
}

data "aws_ssoadmin_instances" "main" {
  provider = aws.sso
}

resource "aws_identitystore_user" "grafana_admin" {
  provider          = aws.sso
  identity_store_id = tolist(data.aws_ssoadmin_instances.main.identity_store_ids)[0]

  user_name    = var.grafana_admin_username
  display_name = var.grafana_admin_username

  name {
    given_name  = var.grafana_admin_username
    family_name = "Admin"
  }

  emails {
    value   = var.grafana_admin_email
    primary = true
  }
}

resource "aws_grafana_role_association" "admin" {
  workspace_id = aws_grafana_workspace.main.id
  role         = "ADMIN"
  user_ids     = [aws_identitystore_user.grafana_admin.user_id]
}

resource "aws_prometheus_workspace" "main" {
  alias = "${var.name_prefix}-amp"
  tags  = { Name = "${var.name_prefix}-amp" }
}

resource "aws_grafana_workspace" "main" {
  name                     = "${var.name_prefix}-grafana"
  account_access_type      = "CURRENT_ACCOUNT"
  authentication_providers = ["AWS_SSO"]
  permission_type          = "SERVICE_MANAGED"
  role_arn                 = aws_iam_role.grafana.arn
  data_sources             = ["PROMETHEUS"]
  tags                     = { Name = "${var.name_prefix}-grafana" }
}

resource "aws_iam_role" "grafana" {
  name = "${var.name_prefix}-grafana-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "grafana.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "grafana_amp" {
  role       = aws_iam_role.grafana.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonPrometheusQueryAccess"
}

resource "aws_iam_role" "amp_ingest" {
  name = "${var.name_prefix}-amp-ingest-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Federated = var.oidc_provider_arn
      }
      Action = "sts:AssumeRoleWithWebIdentity"
      Condition = {
        StringEquals = {
          "${var.oidc_provider_url}:sub" = "system:serviceaccount:monitoring:amp-iamproxy-ingest-service-account"
        }
      }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "amp_ingest" {
  role       = aws_iam_role.amp_ingest.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonPrometheusRemoteWriteAccess"
}

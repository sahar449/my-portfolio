###################################
# helm Outputs
###################################

output "alb_controller_role_name" {
  description = "The name of the IAM role for AWS Load Balancer Controller"
  value       = aws_iam_role.lb_controller_role.name
}

output "alb_controller_role_arn" {
  description = "The ARN of the IAM role for AWS Load Balancer Controller"
  value       = aws_iam_role.lb_controller_role.arn
}

output "external_dns_role_name" {
  description = "The name of the IAM role for External DNS"
  value       = aws_iam_role.external_dns_role.name
}

output "external_dns_role_arn" {
  description = "The ARN of the IAM role for External DNS"
  value       = aws_iam_role.external_dns_role.arn
}

output "flask_app_role_arn" {
  description = "The ARN of the IRSA role for the Flask backend service account"
  value       = aws_iam_role.flask_app_role.arn
}

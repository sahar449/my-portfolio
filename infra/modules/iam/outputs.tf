###################################
# EKS roles
###################################

# depends_on: the cluster/nodes must be created after (and destroyed before) the policy
# attachments, otherwise destroy can detach policies while nodes are still draining.
output "eks_cluster_role_arn" {
  value      = aws_iam_role.eks_cluster_role.arn
  depends_on = [aws_iam_role_policy_attachment.eks_cluster_AmazonEKSClusterPolicy]
}

output "node_group_role_arn" {
  value = aws_iam_role.node_group_role.arn
  depends_on = [
    aws_iam_role_policy_attachment.worker_node_AmazonEKSWorkerNodePolicy,
    aws_iam_role_policy_attachment.worker_node_AmazonEC2ContainerRegistryReadOnly,
    aws_iam_role_policy_attachment.worker_node_AmazonEKS_CNI_Policy,
  ]
}

###################################
# IRSA roles
###################################

output "alb_controller_role_arn" {
  description = "The ARN of the IAM role for AWS Load Balancer Controller"
  value       = aws_iam_role.lb_controller_role.arn
}

output "external_dns_role_arn" {
  description = "The ARN of the IAM role for external-dns (installed by Argo CD)"
  value       = aws_iam_role.external_dns.arn
  depends_on  = [aws_iam_role_policy.external_dns]
}

output "cloudwatch_agent_role_arn" {
  description = "The ARN of the IAM role for the CloudWatch observability addon"
  value       = aws_iam_role.cloudwatch_agent.arn
  depends_on = [
    aws_iam_role_policy_attachment.cloudwatch_agent,
    aws_iam_role_policy_attachment.xray_daemon,
  ]
}

output "flask_app_role_arn" {
  description = "The ARN of the IRSA role for the Flask backend service account"
  value       = aws_iam_role.flask_app_role.arn
}

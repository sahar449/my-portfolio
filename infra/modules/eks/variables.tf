### variables eks ###

variable "cluster_name" {}

variable "cluster_version" {
  type = string
}

variable "private_subnet_ids" {
  type = list(string)
}

variable "public_subnet_ids" {
  type = list(string)
}

variable "cluster_role_arn" {
  description = "IAM role ARN for the EKS control plane (from the iam module)"
  type        = string
}

variable "node_role_arn" {
  description = "IAM role ARN for the EKS node groups (from the iam module)"
  type        = string
}

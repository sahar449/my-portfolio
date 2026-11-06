variable "cluster_name" {
  description = "The name of the EKS cluster (used as IAM role name prefix)"
  type        = string
}

variable "name_prefix" {
  description = "Prefix for resource names"
  type        = string
}

variable "oidc_provider_arn" {
  description = "ARN of the EKS cluster OIDC provider"
  type        = string
}

variable "oidc_provider_url" {
  description = "URL of the EKS cluster OIDC provider"
  type        = string
}

variable "app_secret_arns" {
  description = "Secrets Manager ARNs the Flask backend is allowed to read"
  type        = list(string)
}

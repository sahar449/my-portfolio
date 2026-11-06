# region / cluster_name / name_prefix are set by the workflows from GitHub Actions
# Variables (AWS_REGION, CLUSTER_NAME, NAME_PREFIX) via TF_VAR_*. Defaults are fallbacks.
variable "region" {
  type    = string
  default = "us-west-2"
}

variable "cluster_name" {
  type    = string
  default = "eksdemo-cluster"
}

variable "name_prefix" {
  type    = string
  default = "eksdemo"
}

variable "cluster_version" {
  description = "EKS Kubernetes version; core add-on versions are resolved to match it"
  type        = string
  default     = "1.34"
}

variable "vpc_cidr" {}
variable "public_subnet_cidrs" { type = list(string) }
variable "private_subnet_cidrs" { type = list(string) }
variable "DB_NAME" {}
variable "DB_USER" {}
variable "secret_name" {}

### variables eks ###

variable "vpc_id" {}

variable "private_subnet_ids" {
  type = list(string)
}

variable "public_subnet_ids" {
  type = list(string)
}

variable "cluster_name" {}

variable "acm_cert_arn" {}
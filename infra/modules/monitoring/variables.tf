variable "name_prefix"       { type = string }
variable "region"            { type = string }
variable "oidc_provider_arn" { type = string }
variable "oidc_provider_url" { type = string }
variable "grafana_admin_email"    { type = string }
variable "grafana_admin_username" { type = string }
variable "cluster_arn"           { type = string }
variable "private_subnet_ids"    { type = list(string) }

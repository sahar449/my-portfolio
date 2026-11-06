### variables rds ###
variable "DB_NAME" {}
variable "DB_USER" {}
variable "vpc_id" {}
variable "secret_name" {}
variable "DB_HOST" {}
variable "cidr_blocks" {}
variable "private_subnets" {
  type = list(string)
}
variable "mysql_major_version" {
  description = "Optional MySQL version prefix (e.g. \"8.4\"). null = AWS default version in the region"
  type        = string
  default     = null
}

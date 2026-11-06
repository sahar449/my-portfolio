output "rds_endpoint" {
  value = aws_db_instance.mysql.address
}

output "secret_arn" {
  value = aws_secretsmanager_secret.rds_credentials.arn
}

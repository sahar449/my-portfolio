output "redis_endpoint" {
  description = "Redis primary endpoint address"
  value       = aws_elasticache_replication_group.this.primary_endpoint_address
}

output "redis_port" {
  description = "Redis port"
  value       = aws_elasticache_replication_group.this.port
}

output "redis_security_group_id" {
  description = "Security group ID attached to the Redis cluster"
  value       = aws_security_group.redis.id
}

output "redis_secret_name" {
  description = "Secrets Manager secret name for Redis credentials"
  value       = aws_secretsmanager_secret.redis.name
}

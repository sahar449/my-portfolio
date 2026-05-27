###################################
# ElastiCache (Redis) Module
###################################

# Subnet group — private subnets only
resource "aws_elasticache_subnet_group" "this" {
  name       = "${var.name_prefix}-redis-subnet-group"
  subnet_ids = var.private_subnet_ids

  tags = {
    Name = "${var.name_prefix}-redis-subnet-group"
  }
}

# Security group
resource "aws_security_group" "redis" {
  name   = "${var.name_prefix}-redis-sg"
  vpc_id = var.vpc_id

  tags = {
    Name = "${var.name_prefix}-redis-sg"
  }
}

resource "aws_security_group_rule" "redis_ingress" {
  type              = "ingress"
  from_port         = 6379
  to_port           = 6379
  protocol          = "tcp"
  cidr_blocks       = [var.cidr_blocks]
  security_group_id = aws_security_group.redis.id
}

resource "aws_security_group_rule" "redis_egress" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.redis.id
}

###################################
# Auth Token + Secrets Manager
###################################

resource "random_password" "redis_auth" {
  length  = 32
  special = false
}

resource "aws_secretsmanager_secret" "redis" {
  name = var.redis_secret_name
}

resource "aws_secretsmanager_secret_version" "redis" {
  secret_id = aws_secretsmanager_secret.redis.id
  secret_string = jsonencode({
    host     = aws_elasticache_replication_group.this.primary_endpoint_address
    password = random_password.redis_auth.result
    port     = "6379"
  })
}

###################################
# CloudWatch — Slow Logs
###################################

resource "aws_cloudwatch_log_group" "redis_slow_logs" {
  name              = "/elasticache/${var.name_prefix}/slow-logs"
  retention_in_days = 7

  tags = {
    Name = "${var.name_prefix}-redis-slow-logs"
  }
}

###################################
# ElastiCache Cluster
###################################

resource "aws_elasticache_replication_group" "this" {
  replication_group_id = "${var.name_prefix}-redis"
  description          = "Redis cluster for ${var.name_prefix}"
  engine               = "redis"
  engine_version       = "7.1"
  node_type            = var.node_type
  num_cache_clusters   = 1
  parameter_group_name = "default.redis7"
  port                 = 6379
  subnet_group_name    = aws_elasticache_subnet_group.this.name
  security_group_ids   = [aws_security_group.redis.id]

  auth_token                 = random_password.redis_auth.result
  transit_encryption_enabled = true

  log_delivery_configuration {
    destination      = aws_cloudwatch_log_group.redis_slow_logs.name
    destination_type = "cloudwatch-logs"
    log_format       = "text"
    log_type         = "slow-log"
  }

  tags = {
    Name = "${var.name_prefix}-redis"
  }
}

###################################
# CloudWatch Alarms
###################################

resource "aws_cloudwatch_metric_alarm" "evictions" {
  alarm_name          = "${var.name_prefix}-redis-evictions"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "Evictions"
  namespace           = "AWS/ElastiCache"
  period              = 300
  statistic           = "Sum"
  threshold           = 100
  alarm_description   = "Redis is evicting keys — memory may be insufficient"

  dimensions = {
    CacheClusterId = "${aws_elasticache_replication_group.this.replication_group_id}-0001"
  }
}

resource "aws_cloudwatch_metric_alarm" "cpu" {
  alarm_name          = "${var.name_prefix}-redis-high-cpu"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "EngineCPUUtilization"
  namespace           = "AWS/ElastiCache"
  period              = 300
  statistic           = "Average"
  threshold           = 80
  alarm_description   = "Redis CPU utilization is above 80%"

  dimensions = {
    CacheClusterId = "${aws_elasticache_replication_group.this.replication_group_id}-0001"
  }
}

resource "aws_cloudwatch_metric_alarm" "cache_misses" {
  alarm_name          = "${var.name_prefix}-redis-high-misses"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 3
  metric_name         = "CacheMisses"
  namespace           = "AWS/ElastiCache"
  period              = 300
  statistic           = "Sum"
  threshold           = 1000
  alarm_description   = "Redis cache miss rate is high"

  dimensions = {
    CacheClusterId = "${aws_elasticache_replication_group.this.replication_group_id}-0001"
  }
}

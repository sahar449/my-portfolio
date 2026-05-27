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

resource "aws_elasticache_cluster" "this" {
  cluster_id           = "${var.name_prefix}-redis"
  engine               = "redis"
  engine_version       = "7.1"
  node_type            = var.node_type
  num_cache_nodes      = 1
  parameter_group_name = "default.redis7"
  port                 = 6379
  subnet_group_name    = aws_elasticache_subnet_group.this.name
  security_group_ids   = [aws_security_group.redis.id]

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

# Alert when Redis is evicting keys — means memory is full
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
    CacheClusterId = aws_elasticache_cluster.this.cluster_id
  }

  tags = {
    Name = "${var.name_prefix}-redis-evictions-alarm"
  }
}

# Alert when CPU is too high
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
    CacheClusterId = aws_elasticache_cluster.this.cluster_id
  }

  tags = {
    Name = "${var.name_prefix}-redis-cpu-alarm"
  }
}

# Alert when cache miss rate is high (CacheMisses > CacheHits)
resource "aws_cloudwatch_metric_alarm" "cache_misses" {
  alarm_name          = "${var.name_prefix}-redis-high-misses"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 3
  metric_name         = "CacheMisses"
  namespace           = "AWS/ElastiCache"
  period              = 300
  statistic           = "Sum"
  threshold           = 1000
  alarm_description   = "Redis cache miss rate is high — TTL may be too short or cache is cold"

  dimensions = {
    CacheClusterId = aws_elasticache_cluster.this.cluster_id
  }

  tags = {
    Name = "${var.name_prefix}-redis-misses-alarm"
  }
}

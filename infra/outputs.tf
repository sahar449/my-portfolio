output "cluster_name" {
  value = module.eks.cluster_name
}

output "ecr_frontend_url" {
  value = module.ecr_frontend.repository_url
}

output "ecr_backend_url" {
  value = module.ecr_backend.repository_url
}

output "rds_endpoint" {
  value = module.rds.rds_endpoint
}

output "redis_endpoint" {
  value = module.elasticache.redis_endpoint
}

output "alb_controller_role_arn" {
  value = module.iam.alb_controller_role_arn
}

output "flask_app_role_arn" {
  value = module.iam.flask_app_role_arn
}

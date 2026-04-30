### main root ###

module "ecr_frontend" {
  source    = "./modules/ecr"
  repo_name = "frontend"
}

module "ecr_backend" {
  source    = "./modules/ecr"
  repo_name = "backend"
}

module "vpc" {
  source                = "./modules/vpc"
  vpc_cidr              = var.vpc_cidr
  public_subnet_cidrs   = var.public_subnet_cidrs
  private_subnet_cidrs  = var.private_subnet_cidrs
  availability_zones    = var.availability_zones
  name_prefix           = var.name_prefix
}

module "eks" {
  source              = "./modules/eks"
  cluster_name        = var.cluster_name
  vpc_id              = module.vpc.vpc_id
  private_subnet_ids  = module.vpc.private_subnet_ids
  public_subnet_ids   = module.vpc.public_subnet_ids
  acm_cert_arn        = module.ssl.ssl_cert_arn
  depends_on          = [module.ssl]
}

module "iam" {
  source            = "./modules/iam"
  cluster_name      = var.cluster_name
  oidc_provider_arn = module.eks.oidc_provider_arn
  oidc_provider_url = module.eks.oidc_provider_url
  region            = var.region
  vpc_id            = module.eks.eks_vpc_id
  ssl_certificate_validation_resource = module.ssl.ssl_certificate_validation_resource
  depends_on = [
    module.eks
  ]
}

module "ssl" {
  source = "./modules/ssl"
}

module "rds" {
  source = "./modules/rds"
  DB_NAME         = var.DB_NAME
  DB_USER         = var.DB_USER
  DB_HOST         = var.DB_HOST
  secret_name     = var.secret_name
  vpc_id          = module.vpc.vpc_id
  private_subnets = module.vpc.private_subnet_ids
  cidr_blocks = module.vpc.cidr_blocks
}

# resource "helm_release" "aws_load_balancer_controller" {
#   name       = "aws-load-balancer-controller"
#   repository = "https://aws.github.io/eks-charts"
#   chart      = "aws-load-balancer-controller"
#   namespace  = "kube-system"
#   version    = "1.12.0"

#   values = [
#     <<-EOT
#     clusterName: ${module.eks.cluster_name}
#     region: ${var.region}
#     vpcId: ${module.vpc.vpc_id}
#     serviceAccount:
#       name: aws-load-balancer-controller
#       annotations:
#         eks.amazonaws.com/role-arn: ${module.iam.alb_controller_role_arn}
#     EOT
#   ]

#   depends_on = [module.eks, module.iam]
# }


resource "helm_release" "aws_load_balancer_controller" {
  name       = "aws-load-balancer-controller"
  repository = "https://aws.github.io/eks-charts"
  chart      = "aws-load-balancer-controller"
  namespace  = "kube-system"
  version    = "1.12.0"

  set {
    name  = "clusterName"
    value = module.eks.cluster_name
  }
  set {
    name  = "region"
    value = var.region
  }
  set {
    name  = "vpcId"
    value = module.vpc.vpc_id
  }
  set {
    name  = "serviceAccount.name"
    value = "aws-load-balancer-controller"
  }
  set {
    name  = "serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"
    value = module.iam.alb_controller_role_arn
  }

  depends_on = [module.iam, module.eks]
}

output "ssl_cert_arn" {
  value = module.ssl.ssl_cert_arn
}

output "amp_endpoint" {
  value = module.monitoring.amp_endpoint
}

output "amp_ingest_role_arn" {
  value = module.monitoring.amp_ingest_role_arn
}

module "monitoring" {
  source              = "./modules/monitoring"
  name_prefix         = var.name_prefix
  region              = var.region
  oidc_provider_arn   = module.eks.oidc_provider_arn
  oidc_provider_url   = module.eks.oidc_provider_url
  depends_on          = [module.eks]
}

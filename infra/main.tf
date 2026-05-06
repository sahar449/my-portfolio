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


module "monitoring" {
  source            = "./modules/monitoring"
  name_prefix       = var.name_prefix
  region            = var.region
  cluster_name      = var.cluster_name
  oidc_provider_arn = module.eks.oidc_provider_arn
  oidc_provider_url = module.eks.oidc_provider_url
  depends_on        = [module.eks]
}


### main root ###

# AZs come from the region, so changing AWS_REGION needs no other edits
data "aws_availability_zones" "available" {
  state = "available"
}

module "ecr_frontend" {
  source    = "./modules/ecr"
  repo_name = "frontend"
}

module "ecr_backend" {
  source    = "./modules/ecr"
  repo_name = "backend"
}

module "vpc" {
  source               = "./modules/vpc"
  vpc_cidr             = var.vpc_cidr
  public_subnet_cidrs  = var.public_subnet_cidrs
  private_subnet_cidrs = var.private_subnet_cidrs
  availability_zones   = slice(data.aws_availability_zones.available.names, 0, length(var.public_subnet_cidrs))
  name_prefix          = var.name_prefix
}

module "ssl" {
  source = "./modules/ssl"
}

# All IAM lives here. No module-level depends_on between iam and eks: each resource
# depends only on the inputs it uses, so cluster roles are created before the cluster
# and IRSA roles after the OIDC provider, without a dependency cycle.
module "iam" {
  source            = "./modules/iam"
  cluster_name      = var.cluster_name
  name_prefix       = var.name_prefix
  oidc_provider_arn = module.eks.oidc_provider_arn
  oidc_provider_url = module.eks.oidc_provider_url
  app_secret_arns   = [module.rds.secret_arn, module.elasticache.redis_secret_arn]
}

module "eks" {
  source             = "./modules/eks"
  cluster_name       = var.cluster_name
  cluster_version    = var.cluster_version
  private_subnet_ids = module.vpc.private_subnet_ids
  public_subnet_ids  = module.vpc.public_subnet_ids
  cluster_role_arn   = module.iam.eks_cluster_role_arn
  node_role_arn      = module.iam.node_group_role_arn
}

module "rds" {
  source          = "./modules/rds"
  DB_NAME         = var.DB_NAME
  DB_USER         = var.DB_USER
  secret_name     = var.secret_name
  vpc_id          = module.vpc.vpc_id
  private_subnets = module.vpc.private_subnet_ids
  cidr_blocks     = module.vpc.cidr_blocks
}

module "elasticache" {
  source             = "./modules/elasticache"
  name_prefix        = var.name_prefix
  vpc_id             = module.vpc.vpc_id
  private_subnet_ids = module.vpc.private_subnet_ids
  cidr_blocks        = module.vpc.cidr_blocks
}

module "monitoring" {
  source                    = "./modules/monitoring"
  name_prefix               = var.name_prefix
  region                    = var.region
  cluster_name              = module.eks.cluster_name
  cloudwatch_agent_role_arn = module.iam.cloudwatch_agent_role_arn
  # addon pods need worker nodes to be up
  depends_on = [module.eks]
}

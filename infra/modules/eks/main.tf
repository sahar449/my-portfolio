resource "aws_eks_cluster" "this" {
  name     = var.cluster_name
  role_arn = var.cluster_role_arn
  version  = var.cluster_version

  vpc_config {
    subnet_ids = var.private_subnet_ids
  }
}

resource "aws_eks_node_group" "backend_nodes" {
  cluster_name    = aws_eks_cluster.this.name
  node_group_name = "${var.cluster_name}-backend-nodegroup"
  node_role_arn   = var.node_role_arn
  subnet_ids      = var.private_subnet_ids

  scaling_config {
    desired_size = 2
    max_size     = 4
    min_size     = 2
  }

  instance_types = ["t3.medium"]

  labels = {
    role = "backend"
  }
}

resource "aws_eks_node_group" "frontend_nodes" {
  cluster_name    = aws_eks_cluster.this.name
  node_group_name = "${var.cluster_name}-frontend-nodegroup"
  node_role_arn   = var.node_role_arn
  subnet_ids      = var.public_subnet_ids

  scaling_config {
    desired_size = 2
    max_size     = 4
    min_size     = 2
  }

  instance_types = ["t3.medium"]

  labels = {
    role = "frontend"
  }
}

data "tls_certificate" "eks" {
  url = aws_eks_cluster.this.identity[0].oidc[0].issuer
}

resource "aws_iam_openid_connect_provider" "eks" {
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = [data.tls_certificate.eks.certificates[0].sha1_fingerprint]
  url             = aws_eks_cluster.this.identity[0].oidc[0].issuer
}

###############################################
# EKS Managed Addons — versions resolved from AWS for the cluster's k8s version
# Only the core add-ons Argo CD itself needs to run. Everything else
# (external-dns, metrics-server, kube-state-metrics, Secrets Store CSI)
# is installed by Argo CD: ArgoCD/apps/cluster-addons-applicationset.yaml
###############################################

locals {
  core_addons = toset(["vpc-cni", "kube-proxy", "coredns"])
}

# Latest version compatible with the cluster's Kubernetes version (never a removed one)
data "aws_eks_addon_version" "core" {
  for_each           = local.core_addons
  addon_name         = each.key
  kubernetes_version = aws_eks_cluster.this.version
  most_recent        = true
}

resource "aws_eks_addon" "core" {
  for_each      = local.core_addons
  cluster_name  = aws_eks_cluster.this.name
  addon_name    = each.key
  addon_version = data.aws_eks_addon_version.core[each.key].version
  depends_on    = [aws_eks_node_group.backend_nodes, aws_eks_node_group.frontend_nodes]
}

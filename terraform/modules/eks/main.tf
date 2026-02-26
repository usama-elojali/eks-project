# main.tf - EKS cluster and node group

#------------------------------------------------------------------------------
# EKS CLUSTER
# The control plane - managed by AWS
#------------------------------------------------------------------------------

resource "aws_eks_cluster" "main" {
  name     = var.cluster_name
  role_arn = aws_iam_role.cluster.arn
  version  = var.kubernetes_version

  vpc_config {
    subnet_ids              = concat(var.private_subnet_ids, var.public_subnet_ids)
    endpoint_private_access = true
    endpoint_public_access  = true
  }

  tags = {
    Name        = var.cluster_name
    Environment = var.environment
    Project     = var.project_name
  }

  depends_on = [
    aws_iam_role_policy_attachment.cluster_policy
  ]
}

#------------------------------------------------------------------------------
# EKS NODE GROUP
# Worker nodes - where your pods actually run
#------------------------------------------------------------------------------

resource "aws_eks_node_group" "main" {
  cluster_name    = aws_eks_cluster.main.name
  node_group_name = "${var.cluster_name}-nodes"
  node_role_arn   = aws_iam_role.node.arn
  subnet_ids      = var.private_subnet_ids # Nodes in PRIVATE subnets only

  instance_types = var.node_instance_types
  capacity_type  = "ON_DEMAND"

  scaling_config {
    desired_size = var.node_desired_size
    min_size     = var.node_min_size
    max_size     = var.node_max_size
  }

  tags = {
    Name        = "${var.cluster_name}-nodes"
    Environment = var.environment
    Project     = var.project_name
  }

  depends_on = [
    aws_iam_role_policy_attachment.node_worker_policy,
    aws_iam_role_policy_attachment.node_cni_policy,
    aws_iam_role_policy_attachment.node_ecr_policy
  ]
}

#------------------------------------------------------------------------------
# OIDC PROVIDER
# Enables IRSA - pods can assume IAM roles
#------------------------------------------------------------------------------

data "tls_certificate" "eks" {
  url = aws_eks_cluster.main.identity[0].oidc[0].issuer
}

resource "aws_iam_openid_connect_provider" "eks" {
  url             = aws_eks_cluster.main.identity[0].oidc[0].issuer
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = [data.tls_certificate.eks.certificates[0].sha1_fingerprint]

  tags = {
    Name        = "${var.cluster_name}-oidc"
    Environment = var.environment
    Project     = var.project_name
  }
}
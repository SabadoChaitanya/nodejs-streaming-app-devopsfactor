

#################################################
# Data Sources
#################################################
# Default VPC
data "aws_vpc" "default" {
  default = true
}

# Private subnets in the default VPC
data "aws_subnets" "private_subnets" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }

  filter {
    name   = "tag:Tier"
    values = ["private"]
  }
}

# Current AWS Account
data "aws_caller_identity" "current" {}

#################################################
# IAM Roles
#################################################
# Admin IAM Role for full access (optional)
resource "aws_iam_role" "eks_admin_role" {
  name               = "EKS-Admin-Role"
  assume_role_policy = data.aws_iam_policy_document.eks_admin_assume_role.json
  tags = {
    Owner   = "DevOpsFactory"
    Project = "DevOps-EKS"
  }
}

data "aws_iam_policy_document" "eks_admin_assume_role" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "AWS"
      identifiers = [data.aws_caller_identity.current.arn]
    }
  }
}

resource "aws_iam_role_policy_attachment" "eks_admin_attach" {
  role       = aws_iam_role.eks_admin_role.name
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}

# EKS Cluster IAM Role
resource "aws_iam_role" "eks_cluster_role" {
  name               = "eks-cluster-role"
  assume_role_policy = data.aws_iam_policy_document.eks_cluster_assume_role.json
  tags = {
    Owner   = "DevOpsFactory"
    Project = "DevOps-EKS"
  }
}

data "aws_iam_policy_document" "eks_cluster_assume_role" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["eks.amazonaws.com"]
    }
  }
}

resource "aws_iam_role_policy_attachment" "eks_cluster_policy" {
  role       = aws_iam_role.eks_cluster_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
}

# Fargate Pod Execution Role
resource "aws_iam_role" "fargate_pod_execution_role" {
  name               = "eks-fargate-pod-execution-role"
  assume_role_policy = data.aws_iam_policy_document.fargate_assume_role.json
  tags = {
    Owner   = "DevOpsFactory"
    Project = "DevOps-EKS"
  }
}

data "aws_iam_policy_document" "fargate_assume_role" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["eks-fargate-pods.amazonaws.com"]
    }
  }
}

resource "aws_iam_role_policy_attachment" "fargate_policy" {
  role       = aws_iam_role.fargate_pod_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSFargatePodExecutionRolePolicy"
}

#################################################
# EKS Cluster
#################################################
resource "aws_eks_cluster" "eks_cluster" {
  name     = "devops-eks-cluster"
  version  = "1.25" # ✅ supported in ap-south-2
  role_arn = aws_iam_role.eks_cluster_role.arn

  vpc_config {
    subnet_ids                = data.aws_subnets.private_subnets.ids
    endpoint_public_access    = true
    endpoint_private_access   = true
  }

  enabled_cluster_log_types = ["api", "audit", "authenticator"]

  tags = {
    Owner   = "DevOpsFactory"
    Project = "DevOps-EKS"
  }
}

#################################################
# EKS Fargate Profile
#################################################
resource "aws_eks_fargate_profile" "fargate_profile" {
  cluster_name           = aws_eks_cluster.eks_cluster.name
  fargate_profile_name   = "devops-fargate-profile"
  pod_execution_role_arn = aws_iam_role.fargate_pod_execution_role.arn
  subnet_ids             = data.aws_subnets.private_subnets.ids

  selector {
    namespace = "default"
  }

  tags = {
    Owner   = "DevOpsFactory"
    Project = "DevOps-EKS"
  }
}

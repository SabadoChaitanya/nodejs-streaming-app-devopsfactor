#################################################
# Terraform & Provider
#################################################
terraform {
  required_version = ">= 1.3"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0"
    }
  }
}

provider "aws" {
  region = "ap-south-2"
}

#################################################
# Get default VPC
#################################################
data "aws_vpc" "default" {
  default = true
}

#################################################
# Private Subnets
#################################################
resource "aws_subnet" "private_subnet_1" {
  vpc_id            = data.aws_vpc.default.id
  cidr_block        = "172.31.100.0/24"
  availability_zone = "ap-south-2a"
  map_public_ip_on_launch = false

  tags = {
    Name    = "private-subnet-1"
    Tier    = "private"
    Owner   = "DevOpsFactory"
    Project = "DevOps-EKS"
  }
}

resource "aws_subnet" "private_subnet_2" {
  vpc_id            = data.aws_vpc.default.id
  cidr_block        = "172.31.101.0/24"
  availability_zone = "ap-south-2b"
  map_public_ip_on_launch = false

  tags = {
    Name    = "private-subnet-2"
    Tier    = "private"
    Owner   = "DevOpsFactory"
    Project = "DevOps-EKS"
  }
}

#################################################
# IAM Roles
#################################################

# EKS Cluster Role
data "aws_iam_policy_document" "eks_cluster_assume_role" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["eks.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "eks_cluster_role" {
  name               = "eks-cluster-role"
  assume_role_policy = data.aws_iam_policy_document.eks_cluster_assume_role.json
  tags = {
    Owner   = "DevOpsFactory"
    Project = "DevOps-EKS"
  }
}

resource "aws_iam_role_policy_attachment" "eks_cluster_policy" {
  role       = aws_iam_role.eks_cluster_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
}

# EKS Fargate Pod Execution Role
data "aws_iam_policy_document" "fargate_assume_role" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["eks-fargate-pods.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "fargate_pod_execution_role" {
  name               = "eks-fargate-pod-execution-role"
  assume_role_policy = data.aws_iam_policy_document.fargate_assume_role.json
  tags = {
    Owner   = "DevOpsFactory"
    Project = "DevOps-EKS"
  }
}

resource "aws_iam_role_policy_attachment" "fargate_policy" {
  role       = aws_iam_role.fargate_pod_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSFargatePodExecutionRolePolicy"
}

# Admin Role for root user
data "aws_iam_policy_document" "eks_admin_assume_role" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"]
    }
  }
}

data "aws_caller_identity" "current" {}

resource "aws_iam_role" "eks_admin_role" {
  name               = "EKS-Admin-Role"
  assume_role_policy = data.aws_iam_policy_document.eks_admin_assume_role.json
  max_session_duration = 3600
  tags = {
    Owner   = "DevOpsFactory"
    Project = "DevOps-EKS"
  }
}

resource "aws_iam_role_policy_attachment" "eks_admin_attach" {
  role       = aws_iam_role.eks_admin_role.name
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}

#################################################
# EKS Cluster
#################################################
resource "aws_eks_cluster" "eks_cluster" {
  name     = "devops-eks-cluster"
  role_arn = aws_iam_role.eks_cluster_role.arn
  version  = "1.27"

  vpc_config {
    subnet_ids = [
      aws_subnet.private_subnet_1.id,
      aws_subnet.private_subnet_2.id
    ]
    endpoint_private_access = true
    endpoint_public_access  = false
  }

  depends_on = [
    aws_iam_role_policy_attachment.eks_cluster_policy
  ]

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
  subnet_ids = [
    aws_subnet.private_subnet_1.id,
    aws_subnet.private_subnet_2.id
  ]

  selector {
    namespace = "default"
  }

  depends_on = [
    aws_eks_cluster.eks_cluster
  ]
}

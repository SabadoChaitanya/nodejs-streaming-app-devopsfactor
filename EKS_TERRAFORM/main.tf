
############################################################
# Get default VPC
############################################################
data "aws_vpc" "default" {
  default = true
}

############################################################
# Private Subnets (3 AZs)
############################################################
resource "aws_subnet" "private_subnet_1" {
  vpc_id            = data.aws_vpc.default.id
  cidr_block        = "172.31.100.0/24"
  availability_zone = "ap-south-2a"
  map_public_ip_on_launch = false

  tags = {
    Name    = "private-subnet-1"
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
    Owner   = "DevOpsFactory"
    Project = "DevOps-EKS"
  }
}

resource "aws_subnet" "private_subnet_3" {
  vpc_id            = data.aws_vpc.default.id
  cidr_block        = "172.31.102.0/24"
  availability_zone = "ap-south-2c"
  map_public_ip_on_launch = false

  tags = {
    Name    = "private-subnet-3"
    Owner   = "DevOpsFactory"
    Project = "DevOps-EKS"
  }
}

############################################################
# IAM Roles for EKS
############################################################

resource "aws_iam_role" "eks_cluster_role" {
  name = "eks-cluster-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "eks.amazonaws.com"
      }
      Action = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "eks_cluster_policy" {
  role       = aws_iam_role.eks_cluster_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
}

resource "aws_iam_role" "fargate_pod_execution_role" {
  name = "eks-fargate-pod-execution-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "eks-fargate-pods.amazonaws.com"
      }
      Action = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "fargate_policy" {
  role       = aws_iam_role.fargate_pod_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSFargatePodExecutionRolePolicy"
}

data "aws_caller_identity" "current" {}

resource "aws_iam_role" "eks_admin_role" {
  name = "eks-admin-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
      }
      Action = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "eks_admin_attach" {
  role       = aws_iam_role.eks_admin_role.name
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}

############################################################
# EKS Cluster
############################################################
resource "aws_eks_cluster" "eks_cluster" {
  name     = "devops-eks-cluster"
  version  = "1.32"  # ✨ Supported Kubernetes version
  role_arn = aws_iam_role.eks_cluster_role.arn

  vpc_config {
    subnet_ids = [
      aws_subnet.private_subnet_1.id,
      aws_subnet.private_subnet_2.id,
      aws_subnet.private_subnet_3.id
    ]
  }

  enabled_cluster_log_types = ["api", "audit", "authenticator"]
}

############################################################
# Fargate Profile
############################################################
resource "aws_eks_fargate_profile" "fargate_profile" {
  cluster_name           = aws_eks_cluster.eks_cluster.name
  fargate_profile_name   = "devops-fargate-profile"
  pod_execution_role_arn = aws_iam_role.fargate_pod_execution_role.arn

  subnet_ids = [
    aws_subnet.private_subnet_1.id,
    aws_subnet.private_subnet_2.id,
    aws_subnet.private_subnet_3.id
  ]

  selector {
    namespace = "default"
  }
}

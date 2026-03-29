# -----------------------------
# Provider
# -----------------------------
provider "aws" {
  region = "ap-south-2"
}

# -----------------------------
# Get Default VPC
# -----------------------------
data "aws_vpc" "default" {
  default = true
}

# -----------------------------
# Private Subnets
# -----------------------------
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

# -----------------------------
# IAM Role for EKS Cluster Admin
# -----------------------------
resource "aws_iam_role" "eks_admin_role" {
  name = "EKS-Admin-Role"

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

# Attach AdministratorAccess Policy
resource "aws_iam_role_policy_attachment" "eks_admin_attach" {
  role       = aws_iam_role.eks_admin_role.name
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}

# -----------------------------
# EKS Cluster (Fargate)
# -----------------------------
resource "aws_eks_cluster" "eks_cluster" {
  name     = "devops-eks-cluster"
  role_arn = aws_iam_role.eks_admin_role.arn
  version  = "1.27"

  vpc_config {
    subnet_ids = [
      aws_subnet.private_subnet_1.id,
      aws_subnet.private_subnet_2.id,
      aws_subnet.private_subnet_3.id
    ]

    endpoint_private_access = true
    endpoint_public_access  = true
  }

  tags = {
    Name    = "devops-eks-cluster"
    Owner   = "DevOpsFactory"
    Project = "DevOps-EKS"
  }
}

# -----------------------------
# Fargate Profile
# -----------------------------
resource "aws_eks_fargate_profile" "fargate_profile" {
  cluster_name           = aws_eks_cluster.eks_cluster.name
  fargate_profile_name   = "devops-fargate-profile"
  pod_execution_role_arn = aws_iam_role.eks_admin_role.arn
  subnet_ids = [
    aws_subnet.private_subnet_1.id,
    aws_subnet.private_subnet_2.id,
    aws_subnet.private_subnet_3.id
  ]

  selector {
    namespace = "default"
  }

  selector {
    namespace = "kube-system"
  }

  tags = {
    Name    = "devops-fargate-profile"
    Owner   = "DevOpsFactory"
    Project = "DevOps-EKS"
  }
}

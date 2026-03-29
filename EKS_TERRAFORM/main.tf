provider "aws" {
  region = "ap-south-2"
}

# Get default VPC
data "aws_vpc" "default" {
  default = true
}

data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

# -----------------------------
# IAM Roles
# -----------------------------

# EKS Cluster Role
resource "aws_iam_role" "eks_cluster_role" {
  name = "eks-cluster-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "eks.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
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
resource "aws_iam_role" "fargate_pod_execution_role" {
  name = "eks-fargate-pod-execution-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "eks-fargate-pods.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
  tags = {
    Owner   = "DevOpsFactory"
    Project = "DevOps-EKS"
  }
}

resource "aws_iam_role_policy_attachment" "fargate_policy" {
  role       = aws_iam_role.fargate_pod_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSFargatePodExecutionRolePolicy"
}

# -----------------------------
# Private Subnets (must be private for Fargate)
# -----------------------------
resource "aws_subnet" "private_subnet_1" {
  vpc_id            = data.aws_vpc.default.id
  cidr_block        = "10.0.1.0/24"
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
  cidr_block        = "10.0.2.0/24"
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
  cidr_block        = "10.0.3.0/24"
  availability_zone = "ap-south-2c"
  map_public_ip_on_launch = false
  tags = {
    Name    = "private-subnet-3"
    Owner   = "DevOpsFactory"
    Project = "DevOps-EKS"
  }
}

# -----------------------------
# EKS Cluster
# -----------------------------
resource "aws_eks_cluster" "eks_cluster" {
  name     = "devops-eks-cluster"
  role_arn = aws_iam_role.eks_cluster_role.arn
  version  = "1.25" # supported Kubernetes version in ap-south-2

  vpc_config {
    subnet_ids = [
      aws_subnet.private_subnet_1.id,
      aws_subnet.private_subnet_2.id,
      aws_subnet.private_subnet_3.id
    ]
    endpoint_private_access = false
    endpoint_public_access  = true
  }

  enabled_cluster_log_types = ["api", "audit", "authenticator"]

  tags = {
    Owner   = "DevOpsFactory"
    Project = "DevOps-EKS"
  }
}

# -----------------------------
# EKS Fargate Profile
# -----------------------------
resource "aws_eks_fargate_profile" "fargate_profile" {
  cluster_name           = aws_eks_cluster.eks_cluster.name
  fargate_profile_name   = "devops-fargate-profile"
  pod_execution_role_arn = aws_iam_role.fargate_pod_execution_role.arn
  subnet_ids             = [
    aws_subnet.private_subnet_1.id,
    aws_subnet.private_subnet_2.id,
    aws_subnet.private_subnet_3.id
  ]

  selector {
    namespace = "default"
  }

  tags = {
    Owner   = "DevOpsFactory"
    Project = "DevOps-EKS"
  }
}

# -----------------------------
# Get Default VPC
# -----------------------------
data "aws_vpc" "default" {
  default = true
}

# -----------------------------
# Get Availability Zones
# -----------------------------
data "aws_availability_zones" "available" {}

# -----------------------------
# Create PRIVATE Subnets (IMPORTANT)
# -----------------------------
resource "aws_subnet" "private_subnet_1" {
  vpc_id                  = data.aws_vpc.default.id
  cidr_block              = "172.31.100.0/24"
  availability_zone       = data.aws_availability_zones.available.names[0]
  map_public_ip_on_launch = false

  tags = {
    Name = "private-subnet-1"
  }
}

resource "aws_subnet" "private_subnet_2" {
  vpc_id                  = data.aws_vpc.default.id
  cidr_block              = "172.31.101.0/24"
  availability_zone       = data.aws_availability_zones.available.names[1]
  map_public_ip_on_launch = false

  tags = {
    Name = "private-subnet-2"
  }
}

# -----------------------------
# IAM Role for EKS Cluster
# -----------------------------
data "aws_iam_policy_document" "eks_cluster_assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["eks.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "eks_cluster_role" {
  name = "eks-cluster-role"

  assume_role_policy = data.aws_iam_policy_document.eks_cluster_assume_role.json
}

resource "aws_iam_role_policy_attachment" "eks_cluster_policy" {
  role       = aws_iam_role.eks_cluster_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
}

# -----------------------------
# EKS Cluster (USE PRIVATE SUBNETS)
# -----------------------------
resource "aws_eks_cluster" "eks_cluster" {
  name     = "devops-eks-cluster"
  role_arn = aws_iam_role.eks_cluster_role.arn
  version  = "1.29"

  access_config {
    authentication_mode = "API_AND_CONFIG_MAP"
  }

  vpc_config {
    subnet_ids = [
      aws_subnet.private_subnet_1.id,
      aws_subnet.private_subnet_2.id
    ]
  }

  depends_on = [
    aws_iam_role_policy_attachment.eks_cluster_policy
  ]
}

# -----------------------------
# IAM Role for Fargate
# -----------------------------
data "aws_iam_policy_document" "fargate_assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["eks-fargate-pods.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "fargate_pod_execution_role" {
  name = "eks-fargate-pod-execution-role"

  assume_role_policy = data.aws_iam_policy_document.fargate_assume_role.json
}

resource "aws_iam_role_policy_attachment" "fargate_policy" {
  role       = aws_iam_role.fargate_pod_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSFargatePodExecutionRolePolicy"
}

# -----------------------------
# Fargate Profile (USE PRIVATE SUBNETS)
# -----------------------------
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

  selector {
    namespace = "kube-system"
  }

  depends_on = [
    aws_iam_role_policy_attachment.fargate_policy
  ]
}

# -----------------------------
# EKS Access for IAM User
# -----------------------------
resource "aws_eks_access_entry" "admin_access" {
  cluster_name  = aws_eks_cluster.eks_cluster.name
  principal_arn = "arn:aws:iam::679968874516:user/devops-admin"
  type          = "STANDARD"
}

resource "aws_eks_access_policy_association" "admin_policy" {
  cluster_name  = aws_eks_cluster.eks_cluster.name
  principal_arn = "arn:aws:iam::679968874516:user/devops-admin"

  policy_arn = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"

  access_scope {
    type = "cluster"
  }
}

# -----------------------------
# Root Access
# -----------------------------
resource "aws_eks_access_entry" "root_access" {
  cluster_name  = aws_eks_cluster.eks_cluster.name
  principal_arn = "arn:aws:iam::679968874516:root"
  type          = "STANDARD"
}

resource "aws_eks_access_policy_association" "root_admin" {
  cluster_name  = aws_eks_cluster.eks_cluster.name
  principal_arn = "arn:aws:iam::679968874516:root"

  policy_arn = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"

  access_scope {
    type = "cluster"
  }
}

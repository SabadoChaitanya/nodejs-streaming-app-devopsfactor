# -----------------------------
# Get default VPC and private subnets
# -----------------------------
data "aws_vpc" "default" {
  default = true
}

data "aws_subnet_ids" "private_subnets" {
  vpc_id = data.aws_vpc.default.id
  tags = {
    Type = "private"
  }
}

# -----------------------------
# IAM Roles
# -----------------------------
# EKS Cluster Role
resource "aws_iam_role" "eks_cluster_role" {
  name = "eks-cluster-role"
  assume_role_policy = data.aws_iam_policy_document.eks_assume_role.json
  tags = {
    Owner   = "DevOpsFactory"
    Project = "DevOps-EKS"
  }
}

# IAM policy document for EKS Cluster
data "aws_iam_policy_document" "eks_assume_role" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["eks.amazonaws.com"]
    }
  }
}

# Attach managed policies to cluster role
resource "aws_iam_role_policy_attachment" "eks_cluster_policy" {
  role       = aws_iam_role.eks_cluster_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
}

resource "aws_iam_role_policy_attachment" "eks_service_policy" {
  role       = aws_iam_role.eks_cluster_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSServicePolicy"
}

# Fargate Pod Execution Role
resource "aws_iam_role" "fargate_pod_execution_role" {
  name = "eks-fargate-pod-execution-role"
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

# Admin role for full access
resource "aws_iam_role" "eks_admin_role" {
  name = "EKS-Admin-Role"
  assume_role_policy = data.aws_iam_policy_document.admin_assume_role.json
  tags = {
    Owner   = "DevOpsFactory"
    Project = "DevOps-EKS"
  }
}

data "aws_iam_policy_document" "admin_assume_role" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "AWS"
      identifiers = [data.aws_caller_identity.current.account_id]
    }
  }
}

resource "aws_iam_role_policy_attachment" "eks_admin_attach" {
  role       = aws_iam_role.eks_admin_role.name
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}

data "aws_caller_identity" "current" {}

# -----------------------------
# EKS Cluster
# -----------------------------
resource "aws_eks_cluster" "eks_cluster" {
  name     = "devops-eks-cluster"
  role_arn = aws_iam_role.eks_cluster_role.arn
  version  = "1.25"

  vpc_config {
    subnet_ids = data.aws_subnet_ids.private_subnets.ids
    endpoint_public_access = true
    endpoint_private_access = true
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
  subnet_ids             = data.aws_subnet_ids.private_subnets.ids

  selector {
    namespace = "default"
  }

  tags = {
    Owner   = "DevOpsFactory"
    Project = "DevOps-EKS"
  }
}

# -----------------------------
# Outputs
# -----------------------------
output "eks_cluster_name" {
  value = aws_eks_cluster.eks_cluster.name
}

output "eks_cluster_endpoint" {
  value = aws_eks_cluster.eks_cluster.endpoint
}

output "eks_cluster_arn" {
  value = aws_eks_cluster.eks_cluster.arn
}

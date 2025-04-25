provider "aws" {
  region = var.aws_region
}

# Create the EKS Cluster Role
resource "aws_iam_role" "eks_cluster_role" {
  name = "eks_cluster_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = "sts:AssumeRole",
        Principal = {
          Service = "eks.amazonaws.com"
        },
        Effect = "Allow",
        Sid = ""
      }
    ]
  })
}

# Attach policies to the EKS cluster role
resource "aws_iam_role_policy_attachment" "eks_cluster_policy" {
  role       = aws_iam_role.eks_cluster_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
}

# Security Group for worker nodes
resource "aws_security_group" "all_worker_mgmt" {
  name        = "eks_worker_sg"
  description = "Allow worker nodes to communicate"
  vpc_id      = module.vpc.vpc_id

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "eks_worker_sg"
  }
}

# Create EKS Cluster
resource "aws_eks_cluster" "eks_cluster" {
  name     = local.cluster_name
  role_arn = aws_iam_role.eks_cluster_role.arn
  version  = var.kubernetes_version

  vpc_config {
    subnet_ids              = module.vpc.private_subnets
    endpoint_private_access = true
  }

  depends_on = [
    aws_iam_role_policy_attachment.eks_cluster_policy
  ]

  tags = {
    cluster = "demo"
  }
}

# Create the Node Group Role
resource "aws_iam_role" "eks_node_group_role" {
  name = "reena_eks_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = "sts:AssumeRole",
        Principal = {
          Service = "ec2.amazonaws.com"
        },
        Effect = "Allow",
        Sid = ""
      }
    ]
  })
}

# Attach required policies to the node group role
resource "aws_iam_role_policy_attachment" "eks_worker_node_policy" {
  role       = aws_iam_role.eks_node_group_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
}

resource "aws_iam_role_policy_attachment" "eks_cni_policy" {
  role       = aws_iam_role.eks_node_group_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
}

resource "aws_iam_role_policy_attachment" "ec2_container_registry_read_only" {
  role       = aws_iam_role.eks_node_group_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}

# Create Managed Node Group
resource "aws_eks_node_group" "node_group_1" {
  cluster_name    = aws_eks_cluster.eks_cluster.name
  node_group_name = "node-group-1"
  node_role_arn   = aws_iam_role.eks_node_group_role.arn
  subnet_ids      = module.vpc.private_subnets

  scaling_config {
    desired_size = 2
    max_size     = 3
    min_size     = 2
  }

  instance_types = ["t2.micro"]

  remote_access {
    ec2_ssh_key = "your-key-name" # Optional
  }

  tags = {
    cluster = "demo"
  }

  depends_on = [
    aws_eks_cluster.eks_cluster
  ]
}

resource "aws_security_group" "all_worker_mgmt" {
  name_prefix = "all_worker_mgmt"
  vpc_id = module.vpc.vpc_id

}

resource "aws_security_group_rule" "all_worker_mgmt_ingress" {
  description = "allow inbound traffic from eks"
  from_port =  0
  protocol = "-1"
  to_port = 0
  security_group_id = aws_security_group.all_worker_mgmt.id
  type = "ingress"
  cidr_blocks = [
     "0.0.0.0/0"

  ]
}

resource "aws_security_group_rule" "all_worker_mgmt_egress" {
  description = "allow inbound traffic from eks"
  from_port = 0
  protocol = "-1"
  security_group_id = aws_security_group.all_worker_mgmt.id
  to_port = 0
  type = "egress"
  cidr_blocks = ["0.0.0.0/0"]
}

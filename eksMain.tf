module "eks" {
  source          = "terraform-aws-modules/eks/aws"
  version         = "20.29.0"
  cluster_name    = local.cluster_name
  cluster_version = var.kubernetes_version
  subnet_ids      = module.vpc.private_subnets
  vpc_id          = module.vpc.vpc_id
   cluster_endpoint_private_access = true
  enable_irsa = true
  
   cluster_addons = {
    coredns ={ 
        most_recent = true
    }
    kube-proxy =   { 
       most_recent = true
    }
    vpc-cni ={
         most_recent = true
    }
  }

  tags = {
    cluster = "demo"
  }

  eks_managed_node_group_defaults = {
    ami_type               = "AL2_x86_64"
    instance_types         = ["t2.micro"]
    vpc_security_group_ids = [aws_security_group.all_worker_mgmt.id]
  }

  eks_managed_node_groups = {
    node_group_1 = {
      min_size     = 2
      max_size     = 3
      desired_size = 2
      
      }
    }
  }

# Define IAM Role for EKS
resource "aws_iam_role" "reena_eks_role" {
  name = "reena_eks_role"

  assume_role_policy = jsonencode({
    "Version": "2012-10-17",
    "Statement": [
      {
        "Action": "sts:AssumeRole",
        "Principal": {
          "Service": "eks.amazonaws.com"
        },
        "Effect": "Allow",
        "Sid": ""
      }
    ]
  })
}

# Attach policies to the IAM role


resource "aws_iam_role_policy_attachment" "eks_worker_node_policy" {
  role       = aws_iam_role.reena_eks_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
}

resource "aws_iam_role_policy_attachment" "eks_cni_policy" {
  role       = aws_iam_role.reena_eks_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
}

resource "aws_iam_role_policy_attachment" "ec2_container_registry_read_only" {
  role       = aws_iam_role.reena_eks_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}
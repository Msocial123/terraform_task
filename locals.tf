# Define Local Values in Terraform
locals {
  owners = var.business_divsion
  environment = var.environment
  name = "${var.business_divsion}-${var.environment}"
  #name = "${local.owners}-${local.environment}"
  common_tags = {
    owners = local.owners
    environment = local.environment
  }
  eks_cluster_name = "${local.name}-${var.cluster_name}"  
} 

data "aws_ami" "amzlinux2" {
  most_recent = true
  owners      = ["amazon"]
  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }
}

provider "aws" {
  region = var.aws_region
}

data "aws_availability_zones" "available" {}

locals {
  cluster_name = "rupa-eks-${random_string.suffix.result}"

}

resource "random_string" "suffix" {
  length = 8
  special = false
}

resource "aws_instance" "demo_server" {
  ami           = "ami-075686beab831bb7f"
  instance_type = "t2.micro"

subnet_id = module.vpc.private_subnets[0]
      
    
  vpc_security_group_ids = [aws_security_group.all_worker_mgmt.id]

  tags = {
    Name = "demo_server"
  }
}
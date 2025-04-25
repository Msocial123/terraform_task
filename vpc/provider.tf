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
  ami           = "ami-0dee22c13ea7a9a67"
  instance_type = "t2.micro"

subnet_id = module.vpc.private_subnets[0]
      
    
  vpc_security_group_ids = [aws_security_group.all_worker_mgmt.id]

  tags = {
    Name = "demo_server"
  }
}
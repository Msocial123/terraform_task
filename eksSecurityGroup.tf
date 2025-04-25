# AWS EC2 Security Group Terraform Module
# Security Group for Public Bastion Host
module "public_bastion_sg" {
  source  = "terraform-aws-modules/security-group/aws"
  #version = "4.17.2"
  version = "5.1.0"    
  
  name = "${local.name}-public-bastion-sg"
  description = "Security Group with SSH port open for everybody (IPv4 CIDR), egress ports are all world open"
  vpc_id = module.vpc.vpc_id
  # Ingress Rules & CIDR Blocks
  ingress_rules = ["ssh-tcp"]
  ingress_cidr_blocks = ["0.0.0.0/0"]
  # Egress Rule - all-all open
  egress_rules = ["all-all"]
  tags = local.common_tags
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
# Data source for latest Amazon Linux 2 AMI
data "aws_ami" "amzlinux2" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# EC2 Instance in Public Subnet
resource "aws_instance" "bastion" {
  ami                         = data.aws_ami.amzlinux2.id
  instance_type               = var.instance_type
  key_name                    = var.instance_keypair
  subnet_id                   = module.vpc.public_subnets[0]
  vpc_security_group_ids      = [aws_security_group.public_bastion_sg.id]
  associate_public_ip_address = true

  tags = merge(local.common_tags, {
    Name = "${local.name}-BastionHost"
  })
}

# Create Elastic IP and associate with EC2 instance
resource "aws_eip" "bastion_eip" {
  instance = aws_instance.bastion.id
  domain   = "vpc"

  tags = local.common_tags
}

# Null Resource with provisioners
resource "null_resource" "copy_ec2_keys" {
  depends_on = [aws_instance.bastion]

  connection {
    type        = "ssh"
    host        = aws_eip.bastion_eip.public_ip
    user        = "ec2-user"
    private_key = file("private-key/eks-terraform-key.pem")
  }

  # File Provisioner: Copy private key to bastion
  provisioner "file" {
    source      = "private-key/eks-terraform-key.pem"
    destination = "/tmp/eks-terraform-key.pem"
  }

  # Remote Exec Provisioner: Set permission for the copied key
  provisioner "remote-exec" {
    inline = [
      "sudo chmod 400 /tmp/eks-terraform-key.pem"
    ]
  }

  # Local Exec Provisioner: Log creation info locally
  provisioner "local-exec" {
    command     = "echo VPC created on `date` and VPC ID: ${module.vpc.vpc_id} >> creation-time-vpc-id.txt"
    working_dir = "local-exec-output-files/"
  }
}

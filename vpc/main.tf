provider "aws" {
  region = var.aws_region
}

# VPC
resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name        = "vpc-dev"
    Owner       = "kalyan"
    Environment = "dev"
  }
}

# Public Subnets
resource "aws_subnet" "public_a" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = data.aws_availability_zones.available.names
  map_public_ip_on_launch = true

  tags = {
    Name = "public-subnet-a"
    Type = "public-subnets"
  }
}

resource "aws_subnet" "public_b" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.2.0/24"
  availability_zone       = data.aws_availability_zones.available.names
  map_public_ip_on_launch = true

  tags = {
    Name = "public-subnet-b"
    Type = "public-subnets"
  }
}

# Private Subnets
resource "aws_subnet" "private_a" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = data.aws_availability_zones.available.names

  tags = {
    Name = "private-subnet-a"
    Type = "private-subnets"
  }
}

resource "aws_subnet" "private_b" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.2.0/24"
  availability_zone = data.aws_availability_zones.available.names

  tags = {
    Name = "private-subnet-b"
    Type = "private-subnets"
  }
}

# Database Subnets
resource "aws_subnet" "db_a" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.151.0/24"
  availability_zone = data.aws_availability_zones.available.names

  tags = {
    Name = "db-subnet-a"
    Type = "database-subnets"
  }
}

resource "aws_subnet" "db_b" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.152.0/24"
  availability_zone = data.aws_availability_zones.available.names

  tags = {
    Name = "db-subnet-b"
    Type = "database-subnets"
  }
}

# Internet Gateway
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "vpc-dev-igw"
  }
}

# Public Route Table
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name = "public-rt"
  }
}

# Public Route Table Associations
resource "aws_route_table_association" "public_a" {
  subnet_id      = aws_subnet.public_a.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "public_b" {
  subnet_id      = aws_subnet.public_b.id
  route_table_id = aws_route_table.public.id
}

# Elastic IP for NAT
resource "aws_eip" "nat" {
  #vpc = true
}

# NAT Gateway in public subnet A
resource "aws_nat_gateway" "nat" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.public_a.id

  tags = {
    Name = "vpc-dev-nat"
  }
}

# Private Route Table
resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat.id
  }

  tags = {
    Name = "private-rt"
  }
}

# Private Route Table Associations
resource "aws_route_table_association" "private_a" {
  subnet_id      = aws_subnet.private_a.id
  route_table_id = aws_route_table.private.id
}

resource "aws_route_table_association" "private_b" {
  subnet_id      = aws_subnet.private_b.id
  route_table_id = aws_route_table.private.id
}

# Database Subnet Group
resource "aws_db_subnet_group" "default" {
  name       = "db-subnet-group"
  subnet_ids = [aws_subnet.db_a.id, aws_subnet.db_b.id]

  tags = {
    Name = "db-subnet-group"
  }
}

# Database Route Table
resource "aws_route_table" "db" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "db-rt"
  }
}

resource "aws_route_table_association" "db_a" {
  subnet_id      = aws_subnet.db_a.id
  route_table_id = aws_route_table.db.id
}

resource "aws_route_table_association" "db_b" {
  subnet_id      = aws_subnet.db_b.id
  route_table_id = aws_route_table.db.id
}

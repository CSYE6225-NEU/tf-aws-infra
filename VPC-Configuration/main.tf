# AWS Provider Configuration
provider "aws" {
  region  = var.aws_build_region
  profile = var.aws_profile
}

# Random provider for generating unique identifiers
provider "random" {
}

# --------------------------------------------------------------------------------------
# DATA SOURCES
# --------------------------------------------------------------------------------------

# Retrieve all available AWS Availability Zones in the specified region
data "aws_availability_zones" "available" {}

# Get count of existing VPCs for naming convention
data "aws_vpcs" "existing" {}

# --------------------------------------------------------------------------------------
# NETWORKING RESOURCES
# --------------------------------------------------------------------------------------

# Primary VPC for application environment
resource "aws_vpc" "main" {
  cidr_block = var.vpc_cidr

  tags = {
    Name = "My-VPC-${length(data.aws_vpcs.existing.ids) + 1}"
  }
}

# Internet Gateway to provide public internet access
resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "My-Internet-Gateway"
  }
}

# Public subnets for internet-facing resources
resource "aws_subnet" "public" {
  count                   = length(var.public_subnet_cidrs)
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.public_subnet_cidrs[count.index]
  availability_zone       = element(data.aws_availability_zones.available.names, count.index)
  map_public_ip_on_launch = true

  tags = {
    Name = "Public-Subnet-${count.index + 1}"
  }
}

# Private subnets for backend resources
resource "aws_subnet" "private" {
  count             = length(var.private_subnet_cidrs)
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.private_subnet_cidrs[count.index]
  availability_zone = element(data.aws_availability_zones.available.names, count.index)

  tags = {
    Name = "Private-Subnet-${count.index + 1}"
  }
}

# Route table for public subnets
resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "Public-Route-Table"
  }
}

# Add route to internet gateway for public internet access
resource "aws_route" "public_internet_access" {
  route_table_id         = aws_route_table.public_rt.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.gw.id
}

# Associate public subnets with the public route table
resource "aws_route_table_association" "public_assoc" {
  count          = length(var.public_subnet_cidrs)
  subnet_id      = element(aws_subnet.public[*].id, count.index)
  route_table_id = aws_route_table.public_rt.id
}

# Route table for private subnets
resource "aws_route_table" "private_rt" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "Private-Route-Table"
  }
}

# Associate private subnets with the private route table
resource "aws_route_table_association" "private_assoc" {
  count          = length(var.private_subnet_cidrs)
  subnet_id      = element(aws_subnet.private[*].id, count.index)
  route_table_id = aws_route_table.private_rt.id
}

# --------------------------------------------------------------------------------------
# SECURITY RESOURCES
# --------------------------------------------------------------------------------------

# Security group for web application instances
resource "aws_security_group" "application_sg" {
  vpc_id      = aws_vpc.main.id
  description = "Security group for web application traffic"

  # SSH access
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "SSH access"
  }

  # Application port access from load balancer
  ingress {
    from_port       = var.app_port
    to_port         = var.app_port
    protocol        = "tcp"
    security_groups = [aws_security_group.lb_sg.id]
    description     = "Application port access from load balancer"
  }

  # Allow ICMP for ping (helpful for debugging)
  ingress {
    from_port   = -1
    to_port     = -1
    protocol    = "icmp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow ping"
  }

  # Allow all outbound traffic
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow all outbound traffic"
  }

  tags = {
    Name = "Web-Instance-Application-SG"
  }
}
# Deployment order dependencies
locals {
  dependencies = {
    network_deps = [
      aws_vpc.main,
      aws_internet_gateway.gw,
      aws_subnet.public,
      aws_subnet.private,
      aws_route_table.public_rt,
      aws_route_table.private_rt,
      aws_route_table_association.public_assoc,
      aws_route_table_association.private_assoc
    ]

    security_deps = [
      aws_security_group.application_sg,
      aws_security_group.database_sg,
      aws_security_group.lb_sg,
      aws_iam_role.ec2_role,
      aws_iam_policy.s3_access_policy,
      aws_iam_policy.cloudwatch_policy,
      aws_iam_policy.secrets_access_policy,
      aws_iam_role_policy_attachment.s3_policy_attachment,
      aws_iam_role_policy_attachment.cloudwatch_policy_attachment,
      aws_iam_role_policy_attachment.secrets_policy_attachment,
      aws_iam_instance_profile.ec2_profile
    ]

    kms_deps = [
      aws_kms_key.ec2_key,
      aws_kms_key.rds_key,
      aws_kms_key.s3_key,
      aws_kms_key.secrets_key,
      aws_kms_alias.ec2_key_alias,
      aws_kms_alias.rds_key_alias,
      aws_kms_alias.s3_key_alias,
      aws_kms_alias.secrets_key_alias
    ]
  }
}
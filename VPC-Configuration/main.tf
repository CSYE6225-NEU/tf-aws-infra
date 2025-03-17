# AWS Provider Configuration
provider "aws" {
  region  = var.aws_build_region
  profile = var.aws_profile
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

  # HTTP access
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "HTTP access"
  }

  # HTTPS access
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "HTTPS access"
  }

  # Application port access
  ingress {
    from_port   = var.app_port
    to_port     = var.app_port
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Application port access"
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

# --------------------------------------------------------------------------------------
# COMPUTE RESOURCES
# --------------------------------------------------------------------------------------

# EC2 instance running the web application
resource "aws_instance" "web" {
  ami                    = var.aws_base_ami        # Custom AMI built with Packer
  instance_type          = var.aws_vm_size         # Instance size
  subnet_id              = aws_subnet.public[0].id # Deploy in first public subnet
  vpc_security_group_ids = [aws_security_group.application_sg.id]
  key_name               = var.key_name # SSH key for instance access

  # Storage configuration
  root_block_device {
    volume_size           = var.volume_size
    volume_type           = var.volume_type
    delete_on_termination = true
  }

  disable_api_termination = false # Allow instance termination

  tags = {
    Name = "Webapp-Instance-AMI-${element(split("-", var.aws_base_ami), 1)}"
  }
}
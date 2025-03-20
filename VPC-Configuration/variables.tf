# --------------------------------------------------------------------------------------
# AWS PROVIDER VARIABLES
# --------------------------------------------------------------------------------------

variable "aws_build_region" {
  description = "AWS region where resources will be deployed"
  type        = string
  default     = "us-east-1"
}

variable "aws_profile" {
  description = "AWS CLI profile for authentication"
  type        = string
  default     = "packerdev"
}

# --------------------------------------------------------------------------------------
# COMPUTE VARIABLES
# --------------------------------------------------------------------------------------

variable "aws_base_ami" {
  description = "ID of the custom AMI created by Packer for the application"
  type        = string
  default     = "ami-06e6fcf44808ee14c"
}

variable "aws_vm_size" {
  description = "EC2 instance type for the application server"
  type        = string
  default     = "t2.micro"
}

variable "key_name" {
  description = "SSH key pair name for EC2 instance access"
  type        = string
  default     = "ec2"
}

variable "app_port" {
  description = "Port number on which the application listens for requests"
  type        = number
  default     = 8080
}

variable "volume_size" {
  description = "Size in GB of the root EBS volume for the EC2 instance"
  type        = number
  default     = 25
}

variable "volume_type" {
  description = "EBS volume type for the EC2 instance (gp2, gp3, io1, etc.)"
  type        = string
  default     = "gp2"
}

# --------------------------------------------------------------------------------------
# NETWORKING VARIABLES
# --------------------------------------------------------------------------------------

variable "vpc_cidr" {
  description = "CIDR block for the VPC network"
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnet_cidrs" {
  description = "List of CIDR blocks for public subnets"
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
}

variable "private_subnet_cidrs" {
  description = "List of CIDR blocks for private subnets"
  type        = list(string)
  default     = ["10.0.10.0/24", "10.0.11.0/24", "10.0.12.0/24"]
}

variable "subnet_count" {
  description = "Number of subnets to create in the VPC"
  type        = number
  default     = 3
}

# --------------------------------------------------------------------------------------
# TARGET ACCOUNT VARIABLES
# --------------------------------------------------------------------------------------

variable "target_account_id" {
  description = "AWS account ID for the target environment"
  type        = string
  default     = "980921746832"
}

# --------------------------------------------------------------------------------------
# GCP VARIABLES (FOR CROSS-CLOUD COMPATIBILITY)
# --------------------------------------------------------------------------------------

variable "gcp_dev_project" {
  description = "GCP development project identifier"
  type        = string
  default     = "dev-project-452101"
}

variable "gcp_target_project" {
  description = "GCP target project identifier for deployment"
  type        = string
  default     = ""
}

variable "gcp_build_zone" {
  description = "GCP zone for resource deployment"
  type        = string
  default     = "us-east1-b"
}

variable "gcp_vm_type" {
  description = "GCP machine type for compute instances"
  type        = string
  default     = "e2-medium"
}

variable "gcp_storage_region" {
  description = "GCP region for storage resources"
  type        = string
  default     = "us"
}

# --------------------------------------------------------------------------------------
# DATABASE VARIABLES
# --------------------------------------------------------------------------------------

variable "db_engine" {
  description = "Database engine type (mysql, mariadb, or postgres)"
  type        = string
  default     = "mysql"
}

variable "db_engine_version" {
  description = "Major version for DB parameter group family"
  type        = string
  default     = "8.0"
}

variable "db_engine_full_version" {
  description = "Full version for DB engine"
  type        = string
  default     = "8.0.35"
}

variable "db_instance_class" {
  description = "RDS instance class"
  type        = string
  default     = "db.t3.micro"
}

variable "db_allocated_storage" {
  description = "Allocated storage for RDS instance in GB"
  type        = number
  default     = 20
}

variable "db_port" {
  description = "Port for database connections"
  type        = number
  default     = 3306
}

variable "db_password" {
  description = "Master password for database"
  type        = string
  sensitive   = true
}
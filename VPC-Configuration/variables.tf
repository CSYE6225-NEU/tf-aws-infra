variable "aws_region" {
  description = "AWS region to deploy resources"
  type        = string
  default     = "us-east-1"
}

variable "aws_profile" {
  description = "AWS CLI Profile"
  type        = string
  default     = "packerdev"
}

variable "ami_id" {
  description = "Custom AMI ID for EC2"
  type        = string
  default     = "ami-0812f893ed55215a7"
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
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

variable "key_name" {
  description = "SSH key pair name for EC2"
  type        = string
  default     = "ec2"
}

variable "app_port" {
  description = "Port number on which the application runs"
  type        = number
  default     = 8080
}

variable "volume_size" {
  description = "Specifies the size in GB of the EBS volume to attach to the EC2 instance."
  type        = number
  default     = 25
}

variable "volume_type" {
  description = "Specifies the type of EBS volume to attach to the EC2 instance. Options include 'gp2' (General Purpose SSD), 'io1' (Provisioned IOPS SSD), 'st1' (Throughput Optimized HDD), among others."
  type        = string
  default     = "gp2"
}

variable "subnet_count" {
  description = "Number of subnets to create"
  type        = number
  default     = 3
}
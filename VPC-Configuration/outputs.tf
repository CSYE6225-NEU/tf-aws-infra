# --------------------------------------------------------------------------------------
# NETWORKING OUTPUTS
# --------------------------------------------------------------------------------------

output "vpc_id" {
  description = "ID of the created VPC"
  value       = aws_vpc.main.id
}

output "internet_gateway_id" {
  description = "ID of the Internet Gateway"
  value       = aws_internet_gateway.gw.id
}

output "public_subnets" {
  description = "List of public subnet IDs"
  value       = aws_subnet.public[*].id
}

output "private_subnets" {
  description = "List of private subnet IDs"
  value       = aws_subnet.private[*].id
}

output "public_route_table_id" {
  description = "ID of the public route table"
  value       = aws_route_table.public_rt.id
}

output "private_route_table_id" {
  description = "ID of the private route table"
  value       = aws_route_table.private_rt.id
}

# --------------------------------------------------------------------------------------
# COMPUTE OUTPUTS
# --------------------------------------------------------------------------------------

output "aws_instance_id" {
  description = "ID of the deployed EC2 instance"
  value       = aws_instance.web.id
}

output "aws_instance_public_ip" {
  description = "Public IP address of the EC2 instance"
  value       = aws_instance.web.public_ip
}

output "aws_instance_private_ip" {
  description = "Private IP address of the EC2 instance"
  value       = aws_instance.web.private_ip
}

# --------------------------------------------------------------------------------------
# CONFIGURATION OUTPUTS
# --------------------------------------------------------------------------------------

output "aws_region_used" {
  description = "AWS region where resources were deployed"
  value       = var.aws_build_region
}

output "aws_machine_type" {
  description = "EC2 instance type used for deployment"
  value       = var.aws_vm_size
}

output "application_url" {
  description = "URL to access the application"
  value       = "http://${aws_instance.web.public_ip}:${var.app_port}"
}

# --------------------------------------------------------------------------------------
# DATABASE OUTPUTS
# --------------------------------------------------------------------------------------

output "rds_endpoint" {
  description = "Endpoint of the RDS instance"
  value       = aws_db_instance.csye6225_db.endpoint
}

output "rds_database_name" {
  description = "Database name"
  value       = aws_db_instance.csye6225_db.db_name
}
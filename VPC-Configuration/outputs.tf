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
output "autoscaling_group_name" {
  description = "Name of the Auto Scaling Group"
  value       = aws_autoscaling_group.webapp_asg.name
}

output "launch_template_id" {
  description = "ID of the Launch Template"
  value       = aws_launch_template.app_launch_template.id
}

output "autoscaling_min_size" {
  description = "Minimum number of instances in the Auto Scaling Group"
  value       = aws_autoscaling_group.webapp_asg.min_size
}

output "autoscaling_max_size" {
  description = "Maximum number of instances in the Auto Scaling Group"
  value       = aws_autoscaling_group.webapp_asg.max_size
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
  description = "URL to access the application via domain name"
  value       = "http://${var.environment}.${var.domain_name}"
}

output "load_balancer_dns" {
  description = "DNS name of the load balancer"
  value       = aws_lb.app_lb.dns_name
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
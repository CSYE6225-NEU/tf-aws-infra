# AWS Cloud Infrastructure with Auto-Scaling and Load Balancing

## Overview
This repository contains Terraform configurations for deploying a scalable, multi-AZ infrastructure in AWS. The setup includes public and private subnets across multiple Availability Zones, auto-scaling, application load balancing, DNS configuration, and CloudWatch integration for comprehensive monitoring and logging.

## Features
- Automatic VPC naming with incrementing counters to prevent conflicts
- Dynamic multi-AZ deployment (configurable up to 3 AZs)
- Public and private subnet pairs in each AZ
- Automated CIDR block calculation and distribution
- Internet Gateway for public subnet access
- Separate route tables for public and private subnets
- **Auto-scaling group with dynamic scaling policies**
- **Application Load Balancer for traffic distribution**
- **Route 53 DNS configuration for custom domain**
- CloudWatch integration for metrics and logging
- IAM roles for secure service access
- Configurable through variables
- Comprehensive output values for integration with other infrastructure components

## Prerequisites
- AWS CLI configured with appropriate credentials
- Terraform >= 1.0.0
- AWS account with necessary permissions
- Valid AWS CLI profile
- **Registered domain name**
- **Route 53 hosted zones for your domain**

## Project Structure
```
.
├── main.tf                 # Main Terraform configuration
├── variables.tf            # Input variables definition
├── outputs.tf              # Output values
├── database.tf             # RDS database configuration
├── iam.tf                  # IAM roles and policies
├── s3.tf                   # S3 bucket configuration
├── autoscaling.tf          # Auto-scaling configuration
├── loadbalancer.tf         # Load balancer configuration
├── route53.tf              # DNS configuration
├── .terraform.lock.hcl     # Terraform dependency lock file
└── README.md               # This file
```

## Quick Start
1. Configure AWS credentials:
   ```bash
   aws configure --profile your_aws_profile
   ```

2. Set up Route 53 hosted zones:
   - Create a public hosted zone for your domain in the root AWS account
   - Create hosted zones for subdomains (dev.yourdomain.tld, demo.yourdomain.tld)
   - Delegate the subdomains to their respective AWS accounts

3. Initialize Terraform:
   ```bash
   terraform init
   ```

4. Update terraform.tfvars with your domain information:
   ```hcl
   domain_name = "yourdomain.tld"
   environment = "dev"  # or "demo" for demo environment
   ```

5. Review the deployment plan:
   ```bash
   terraform plan
   ```

6. Apply the configuration:
   ```bash
   terraform apply
   ```

## Configuration Variables

| Variable | Description | Default | Required |
|----------|-------------|---------|----------|
| aws_region | AWS region for deployment | us-east-1 | No |
| aws_profile | AWS CLI profile name | packerdev | Yes |
| vpc_cidr | CIDR block for VPC | 10.0.0.0/16 | No |
| subnet_count | Number of AZs to use (1-3) | 3 | No |
| aws_base_ami | ID of the custom AMI | - | Yes |
| app_port | Application port | 8080 | No |
| db_password | Database password | - | Yes |
| domain_name | Your registered domain name | cloud-infra.me | Yes |
| environment | Environment (dev or demo) | dev | No |
| asg_min_size | Min instances in Auto Scaling Group | 3 | No |
| asg_max_size | Max instances in Auto Scaling Group | 5 | No |
| scale_up_threshold | CPU % to trigger scale up | 5 | No |
| scale_down_threshold | CPU % to trigger scale down | 3 | No |

## Network Architecture
- VPC CIDR: 10.0.0.0/16
- Public Subnets: Automatically calculated based on VPC CIDR
- Private Subnets: Automatically calculated based on VPC CIDR
- One public and one private subnet per AZ
- Internet Gateway attached to VPC
- Separate route tables for public and private subnets
- Auto-scaling group spanning multiple AZs
- Application Load Balancer in public subnets
- RDS instance in private subnet

## Auto-Scaling Configuration
- Launch template with custom AMI
- Auto-scaling group with min=3, max=5 instances
- Instances distributed across multiple AZs
- Scale up when CPU > 5%
- Scale down when CPU < 3%
- 60-second cooldown between scaling actions
- CloudWatch alarms to trigger scaling policies

## Load Balancer Configuration
- Application Load Balancer in public subnets
- HTTP listener on port 80
- Target group on application port
- Health checks to ensure instance availability
- Security group allowing public access on ports 80/443

## DNS Configuration
- Route 53 A record for your domain
- Alias record pointing to the load balancer
- Supports both dev and demo environments
- Allows accessing application via http://dev.yourdomain.tld or http://demo.yourdomain.tld

## Security Features
- DNS hostnames enabled
- DNS support enabled
- Private subnets isolated from internet
- Public subnets with internet access through IGW
- Security groups with limited access
- Application instances only accessible through the load balancer
- IAM roles with least privilege permissions
- S3 bucket with server-side encryption
- Database in private subnet

## Testing the Deployment
1. Wait for DNS propagation (can take up to 48 hours)
2. Access your application via http://dev.yourdomain.tld or http://demo.yourdomain.tld
3. If DNS propagation is not complete, use the load balancer DNS name directly
4. Use the included Postman collection to test the API endpoints

## Maintenance
To update the infrastructure:
1. Modify the required configuration in respective .tf files
2. Run `terraform plan` to review changes
3. Apply changes using `terraform apply`

To destroy the infrastructure:
```bash
terraform destroy
```

## Best Practices Implemented
- Resource tagging for better management
- Dynamic AZ selection for reliability
- Separate route tables for security
- Auto-scaling for handling varying loads
- Load balancing for high availability
- DNS configuration for user-friendly access
- Automatic unique naming to prevent conflicts
- IAM roles for secure service access
- CloudWatch integration for monitoring
- Modular design for reusability

## State Management
The state file is stored locally by default. For production environments, it's recommended to:
1. Use remote state storage (e.g., S3)
2. Enable state locking (e.g., DynamoDB)
3. Enable state file encryption
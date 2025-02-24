# AWS VPC Terraform Infrastructure

## Overview
This repository contains Terraform configurations for deploying a scalable, multi-AZ Virtual Private Cloud (VPC) infrastructure in AWS. The setup includes both public and private subnets across multiple Availability Zones, providing a robust foundation for enterprise applications.

## Features
- Automatic VPC naming with incrementing counters to prevent conflicts
- Dynamic multi-AZ deployment (configurable up to 3 AZs)
- Public and private subnet pairs in each AZ
- Automated CIDR block calculation and distribution
- Internet Gateway for public subnet access
- Separate route tables for public and private subnets
- Configurable through variables
- Comprehensive output values for integration with other infrastructure components

## Prerequisites
- AWS CLI configured with appropriate credentials
- Terraform >= 1.0.0
- AWS account with necessary permissions
- Valid AWS CLI profile

## Project Structure
```
.
├── main.tf                 # Main Terraform configuration
├── variables.tf            # Input variables definition
├── outputs.tf             # Output values
├── .terraform.lock.hcl    # Terraform dependency lock file
└── README.md              # This file
```

## Quick Start
1. Configure AWS credentials:
   ```bash
   aws configure --profile your_aws_profile
   ```

2. Initialize Terraform:
   ```bash
   terraform init
   ```

3. Review the deployment plan:
   ```bash
   terraform plan
   ```

4. Apply the configuration:
   ```bash
   terraform apply
   ```

## Configuration Variables

| Variable | Description | Default | Required |
|----------|-------------|---------|----------|
| aws_region | AWS region for deployment | us-east-1 | No |
| aws_profile | AWS CLI profile name | your_aws_profile | Yes |
| vpc_cidr | CIDR block for VPC | 10.10.0.0/16 | No |
| subnet_count | Number of AZs to use (1-3) | 3 | No |

## Network Architecture
- VPC CIDR: 10.10.0.0/16
- Public Subnets: Automatically calculated based on VPC CIDR
- Private Subnets: Automatically calculated based on VPC CIDR
- One public and one private subnet per AZ
- Internet Gateway attached to VPC
- Separate route tables for public and private subnets

## Outputs
- VPC ID and Name
- AWS Region
- List of Availability Zones used
- Public and Private Subnet IDs
- Terraform State Key

## Security Features
- DNS hostnames enabled
- DNS support enabled
- Private subnets isolated from internet
- Public subnets with internet access through IGW

## Best Practices Implemented
- Resource tagging for better management
- Dynamic AZ selection for reliability
- Separate route tables for security
- Automatic unique naming to prevent conflicts
- Modular design for reusability

## Maintenance
To update the infrastructure:
1. Modify the required configuration in respective .tf files
2. Run `terraform plan` to review changes
3. Apply changes using `terraform apply`

To destroy the infrastructure:
```bash
terraform destroy
```

## State Management
The state file is stored locally by default. For production environments, it's recommended to:
1. Use remote state storage (e.g., S3)
2. Enable state locking (e.g., DynamoDB)
3. Enable state file encryption

## Contributing
1. Fork the repository
2. Create a feature branch
3. Commit your changes
4. Push to the branch
5. Create a Pull Request


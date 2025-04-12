# --------------------------------------------------------------------------------------
# KMS KEY RESOURCES
# --------------------------------------------------------------------------------------

# Get the current AWS account ID
data "aws_caller_identity" "current" {}

# KMS Key for EC2 Encryption
resource "aws_kms_key" "ec2_key" {
  description             = "KMS key for EC2 instance encryption"
  deletion_window_in_days = 10
  enable_key_rotation     = true
  
  policy = jsonencode({
    Version = "2012-10-17",
    Id      = "key-default-1",
    Statement = [
      {
        Sid       = "Enable IAM User Permissions",
        Effect    = "Allow",
        Principal = { AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root" },
        Action    = "kms:*",
        Resource  = "*"
      },
      {
        Sid       = "Allow EC2 Service to use the key",
        Effect    = "Allow",
        Principal = { Service = "ec2.amazonaws.com" },
        Action    = [
          "kms:Encrypt",
          "kms:Decrypt",
          "kms:ReEncrypt*",
          "kms:GenerateDataKey*",
          "kms:DescribeKey"
        ],
        Resource  = "*"
      }
    ]
  })
  
  tags = {
    Name = "EC2-KMS-Key"
  }
}

# KMS Alias for EC2 Key
resource "aws_kms_alias" "ec2_key_alias" {
  name          = "alias/ec2-encryption-key"
  target_key_id = aws_kms_key.ec2_key.key_id
}

# KMS Key for RDS Encryption
resource "aws_kms_key" "rds_key" {
  description             = "KMS key for RDS database encryption"
  deletion_window_in_days = 10
  enable_key_rotation     = true
  
  policy = jsonencode({
    Version = "2012-10-17",
    Id      = "key-default-1",
    Statement = [
      {
        Sid       = "Enable IAM User Permissions",
        Effect    = "Allow",
        Principal = { AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root" },
        Action    = "kms:*",
        Resource  = "*"
      },
      {
        Sid       = "Allow RDS Service to use the key",
        Effect    = "Allow",
        Principal = { Service = "rds.amazonaws.com" },
        Action    = [
          "kms:Encrypt",
          "kms:Decrypt",
          "kms:ReEncrypt*",
          "kms:GenerateDataKey*",
          "kms:CreateGrant",
          "kms:DescribeKey"
        ],
        Resource  = "*"
      },
      {
        Sid       = "Allow attachment of persistent resources",
        Effect    = "Allow",
        Principal = { AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root" },
        Action    = [
          "kms:CreateGrant",
          "kms:ListGrants",
          "kms:RevokeGrant"
        ],
        Resource  = "*",
        Condition = {
          Bool = { "kms:GrantIsForAWSResource": "true" }
        }
      }
    ]
  })
  
  tags = {
    Name = "RDS-KMS-Key"
  }
}

# KMS Alias for RDS Key
resource "aws_kms_alias" "rds_key_alias" {
  name          = "alias/rds-encryption-key"
  target_key_id = aws_kms_key.rds_key.key_id
}

# KMS Key for S3 Encryption
resource "aws_kms_key" "s3_key" {
  description             = "KMS key for S3 bucket encryption"
  deletion_window_in_days = 10
  enable_key_rotation     = true
  
  policy = jsonencode({
    Version = "2012-10-17",
    Id      = "key-default-1",
    Statement = [
      {
        Sid       = "Enable IAM User Permissions",
        Effect    = "Allow",
        Principal = { AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root" },
        Action    = "kms:*",
        Resource  = "*"
      },
      {
        Sid       = "Allow S3 Service to use the key",
        Effect    = "Allow",
        Principal = { Service = "s3.amazonaws.com" },
        Action    = [
          "kms:Encrypt",
          "kms:Decrypt",
          "kms:ReEncrypt*",
          "kms:GenerateDataKey*",
          "kms:DescribeKey"
        ],
        Resource  = "*"
      },
      {
        Sid       = "Allow attachment of persistent resources",
        Effect    = "Allow",
        Principal = { AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root" },
        Action    = [
          "kms:CreateGrant",
          "kms:ListGrants",
          "kms:RevokeGrant"
        ],
        Resource  = "*",
        Condition = {
          Bool = { "kms:GrantIsForAWSResource": "true" }
        }
      }
    ]
  })
  
  tags = {
    Name = "S3-KMS-Key"
  }
}

# KMS Alias for S3 Key
resource "aws_kms_alias" "s3_key_alias" {
  name          = "alias/s3-encryption-key"
  target_key_id = aws_kms_key.s3_key.key_id
}

# KMS Key for Secrets Manager
resource "aws_kms_key" "secrets_key" {
  description             = "KMS key for Secrets Manager encryption"
  deletion_window_in_days = 10
  enable_key_rotation     = true
  
  policy = jsonencode({
    Version = "2012-10-17",
    Id      = "key-default-1",
    Statement = [
      {
        Sid       = "Enable IAM User Permissions",
        Effect    = "Allow",
        Principal = { AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root" },
        Action    = "kms:*",
        Resource  = "*"
      },
      {
        Sid       = "Allow Secrets Manager Service to use the key",
        Effect    = "Allow",
        Principal = { Service = "secretsmanager.amazonaws.com" },
        Action    = [
          "kms:Encrypt",
          "kms:Decrypt",
          "kms:ReEncrypt*",
          "kms:GenerateDataKey*",
          "kms:DescribeKey"
        ],
        Resource  = "*"
      },
      {
        Sid       = "Allow attachment of persistent resources",
        Effect    = "Allow",
        Principal = { AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root" },
        Action    = [
          "kms:CreateGrant",
          "kms:ListGrants",
          "kms:RevokeGrant"
        ],
        Resource  = "*",
        Condition = {
          Bool = { "kms:GrantIsForAWSResource": "true" }
        }
      }
    ]
  })
  
  tags = {
    Name = "Secrets-KMS-Key"
  }
}

# KMS Alias for Secrets Manager Key
resource "aws_kms_alias" "secrets_key_alias" {
  name          = "alias/secrets-encryption-key"
  target_key_id = aws_kms_key.secrets_key.key_id
}
# --------------------------------------------------------------------------------------
# S3 BUCKET RESOURCES
# --------------------------------------------------------------------------------------

# Generate a random UUID for unique S3 bucket naming
resource "random_uuid" "bucket_id" {}

# Create private S3 bucket for file storage
resource "aws_s3_bucket" "app_files" {
  bucket = random_uuid.bucket_id.result

  # Force destroy option allows Terraform to delete non-empty buckets
  force_destroy = true

  tags = {
    Name        = "Application-Files-Bucket"
    Environment = "Production"
  }
}

# Configure bucket to block public access
resource "aws_s3_bucket_public_access_block" "app_files" {
  bucket = aws_s3_bucket.app_files.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Enable KMS encryption for S3 bucket
resource "aws_s3_bucket_server_side_encryption_configuration" "app_files" {
  bucket = aws_s3_bucket.app_files.id

  rule {
    apply_server_side_encryption_by_default {
      kms_master_key_id = aws_kms_key.s3_key.arn
      sse_algorithm     = "aws:kms"
    }
  }
}

# Set lifecycle policy to transition objects to STANDARD_IA after 30 days
resource "aws_s3_bucket_lifecycle_configuration" "app_files" {
  bucket = aws_s3_bucket.app_files.id

  rule {
    id     = "transition-to-standard-ia"
    status = "Enabled"

    transition {
      days          = 30
      storage_class = "STANDARD_IA"
    }
  }
}

# Add S3 bucket name to outputs
output "s3_bucket_name" {
  description = "Name of the S3 bucket for application files"
  value       = aws_s3_bucket.app_files.id
}
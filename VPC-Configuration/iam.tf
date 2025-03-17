# --------------------------------------------------------------------------------------
# IAM RESOURCES
# --------------------------------------------------------------------------------------

# IAM role for EC2 to access S3
resource "aws_iam_role" "ec2_s3_role" {
  name = "EC2-S3-Role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Name = "EC2-S3-Access-Role"
  }
}

# Custom policy for S3 access
resource "aws_iam_policy" "s3_access_policy" {
  name        = "S3-Bucket-Access"
  description = "Policy allowing EC2 access to S3 bucket"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "s3:PutObject",
          "s3:GetObject",
          "s3:DeleteObject",
          "s3:ListBucket"
        ]
        Effect = "Allow"
        Resource = [
          "${aws_s3_bucket.app_files.arn}",
          "${aws_s3_bucket.app_files.arn}/*"
        ]
      }
    ]
  })
}

# Attach policy to role
resource "aws_iam_role_policy_attachment" "s3_policy_attachment" {
  role       = aws_iam_role.ec2_s3_role.name
  policy_arn = aws_iam_policy.s3_access_policy.arn
}

# Instance profile for EC2
resource "aws_iam_instance_profile" "ec2_s3_profile" {
  name = "EC2-S3-Profile"
  role = aws_iam_role.ec2_s3_role.name
}
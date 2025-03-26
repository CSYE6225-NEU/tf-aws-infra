# --------------------------------------------------------------------------------------
# IAM RESOURCES
# --------------------------------------------------------------------------------------

# IAM role for EC2 to access S3 and CloudWatch
resource "aws_iam_role" "ec2_role" {
  name = "EC2-Role"

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
    Name = "EC2-Access-Role"
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

# Custom policy for CloudWatch access
resource "aws_iam_policy" "cloudwatch_policy" {
  name        = "CloudWatch-Access"
  description = "Policy allowing CloudWatch agent to publish metrics and logs"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "cloudwatch:PutMetricData",
          "ec2:DescribeVolumes",
          "ec2:DescribeTags",
          "logs:PutLogEvents",
          "logs:DescribeLogStreams",
          "logs:DescribeLogGroups",
          "logs:CreateLogStream",
          "logs:CreateLogGroup"
        ]
        Effect   = "Allow"
        Resource = "*"
      },
      {
        Action = [
          "ssm:GetParameter",
          "ssm:PutParameter",
          "ssm:DescribeParameters"
        ]
        Effect   = "Allow"
        Resource = "arn:aws:ssm:*:*:parameter/AmazonCloudWatch-*"
      }
    ]
  })
}

# Attach S3 policy to role
resource "aws_iam_role_policy_attachment" "s3_policy_attachment" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = aws_iam_policy.s3_access_policy.arn
}

# Attach CloudWatch policy to role
resource "aws_iam_role_policy_attachment" "cloudwatch_policy_attachment" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = aws_iam_policy.cloudwatch_policy.arn
}

# Instance profile for EC2
resource "aws_iam_instance_profile" "ec2_profile" {
  name = "EC2-Profile"
  role = aws_iam_role.ec2_role.name
}
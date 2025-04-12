# --------------------------------------------------------------------------------------
# SECRETS MANAGER RESOURCES
# --------------------------------------------------------------------------------------
# Generate a random password for the database
resource "random_password" "db_password" {
  length           = 16
  special          = true
  override_special = "!#$%&*()-_=+[]{}<>:?"
}

# Create a secret for the database password
resource "aws_secretsmanager_secret" "db_password" {
  name                    = "csye6225/db/password"
  description             = "Database password for the CSYE6225 application"
  kms_key_id              = aws_kms_key.secrets_key.arn
  recovery_window_in_days = 0
  tags = {
    Name = "DB-Password-Secret"
  }
}

# Store the database password in the secret
resource "aws_secretsmanager_secret_version" "db_password" {
  secret_id = aws_secretsmanager_secret.db_password.id
  secret_string = jsonencode({
    username = "csye6225"
    password = random_password.db_password.result
    dbname   = "csye6225"
    engine   = var.db_engine
    host     = aws_db_instance.csye6225_db.address
    port     = var.db_port
  })
}

# Create a secret for the email service credentials
resource "aws_secretsmanager_secret" "email_service" {
  name                    = "csye6225/email/credentials"
  description             = "Email service credentials for the CSYE6225 application"
  kms_key_id              = aws_kms_key.secrets_key.arn
  recovery_window_in_days = 0
  tags = {
    Name = "Email-Credentials-Secret"
  }
}

# Store the email service credentials in the secret
resource "aws_secretsmanager_secret_version" "email_service" {
  secret_id = aws_secretsmanager_secret.email_service.id
  secret_string = jsonencode({
    username = "email_service_user"
    password = random_password.db_password.result # Reusing the password generator for simplicity
    host     = "smtp.example.com"
    port     = 587
    from     = "no-reply@example.com"
  })
}

# Create Secrets Manager Access Policy
resource "aws_iam_policy" "secrets_access_policy" {
  name        = "Secrets-Manager-Access"
  description = "Policy allowing EC2 access to Secrets Manager"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "secretsmanager:GetSecretValue",
          "secretsmanager:DescribeSecret"
        ],
        Effect = "Allow",
        Resource = [
          aws_secretsmanager_secret.db_password.arn,
          aws_secretsmanager_secret.email_service.arn
        ]
      },
      {
        Action = [
          "secretsmanager:ListSecrets"
        ],
        Effect   = "Allow",
        Resource = "*"
      }
    ]
  })
}

# Attach Secrets Manager policy to EC2 role
resource "aws_iam_role_policy_attachment" "secrets_policy_attachment" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = aws_iam_policy.secrets_access_policy.arn
}
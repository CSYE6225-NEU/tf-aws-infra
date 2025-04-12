# --------------------------------------------------------------------------------------
# DATABASE RESOURCES
# --------------------------------------------------------------------------------------

# Security group for RDS instances
resource "aws_security_group" "database_sg" {
  vpc_id      = aws_vpc.main.id
  description = "Security group for database traffic"

  # Allow traffic from application security group to database port
  ingress {
    from_port       = var.db_port
    to_port         = var.db_port
    protocol        = "tcp"
    security_groups = [aws_security_group.application_sg.id]
    description     = "Database access from application"
  }

  # Allow all outbound traffic
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow all outbound traffic"
  }

  tags = {
    Name = "Database-SG"
  }
}

# RDS Parameter Group
resource "aws_db_parameter_group" "db_param_group" {
  name        = "csye6225-${lower(var.db_engine)}-params"
  family      = "${lower(var.db_engine)}${var.db_engine_version}"
  description = "Custom parameter group for CSYE6225 database"
}

# RDS Subnet Group
resource "aws_db_subnet_group" "db_subnet_group" {
  name       = "csye6225-db-subnet-group"
  subnet_ids = aws_subnet.private[*].id

  tags = {
    Name = "CSYE6225 DB Subnet Group"
  }
}

# RDS Instance - Initially without encryption
# Start with storage_encrypted set to false to get the deployment working
resource "aws_db_instance" "csye6225_db" {
  identifier             = "csye6225"
  engine                 = var.db_engine
  engine_version         = var.db_engine_full_version
  instance_class         = var.db_instance_class
  allocated_storage      = var.db_allocated_storage
  storage_type           = "gp2"
  db_name                = "csye6225"
  username               = "csye6225"
  password               = random_password.db_password.result
  parameter_group_name   = aws_db_parameter_group.db_param_group.name
  db_subnet_group_name   = aws_db_subnet_group.db_subnet_group.name
  vpc_security_group_ids = [aws_security_group.database_sg.id]
  publicly_accessible    = false
  skip_final_snapshot    = true
  multi_az               = false
  
  # Keep encryption disabled initially to get the deployment working
  # After the KMS key issues are resolved, you can enable this
  storage_encrypted      = false
  # Comment out the kms_key_id until the KMS key issues are resolved
  # kms_key_id             = aws_kms_key.rds_key.arn
  
  tags = {
    Name = "CSYE6225-DB"
  }
}
# --------------------------------------------------------------------------------------
# LOAD BALANCER RESOURCES
# --------------------------------------------------------------------------------------

# Security group for the load balancer
resource "aws_security_group" "lb_sg" {
  vpc_id      = aws_vpc.main.id
  description = "Security group for load balancer traffic"

  # Allow HTTP traffic from anywhere
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "HTTP traffic"
  }

  # Allow HTTPS traffic from anywhere
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "HTTPS traffic"
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
    Name = "Load-Balancer-SG"
  }
}

# Application Load Balancer
resource "aws_lb" "app_lb" {
  name               = "webapp-lb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.lb_sg.id]
  subnets            = aws_subnet.public[*].id

  enable_deletion_protection = false

  tags = {
    Name = "WebApp-LB"
  }
}

# Target group for the load balancer with improved health checks
resource "aws_lb_target_group" "app_tg" {
  name     = "webapp-tg"
  port     = var.app_port
  protocol = "HTTP"
  vpc_id   = aws_vpc.main.id

  health_check {
    enabled             = true
    path                = "/healthz"
    port                = "traffic-port"
    healthy_threshold   = 2
    unhealthy_threshold = 5
    timeout             = 10
    interval            = 30
    matcher             = "200"
  }

  tags = {
    Name = "WebApp-TG"
  }
}

# Data source for ACM certificate in dev environment
data "aws_acm_certificate" "dev_cert" {
  count    = var.environment == "dev" ? 1 : 0
  domain   = "${var.environment}.${var.domain_name}"
  statuses = ["ISSUED"]
}

# Import the certificate for demo environment
resource "aws_acm_certificate" "demo_cert" {
  count             = var.environment == "demo" ? 1 : 0
  private_key       = file("${path.module}/certs/demo_private.key")
  certificate_body  = file("${path.module}/certs/demo_cloud-infra_me.crt")
  certificate_chain = file("${path.module}/certs/demo_cloud-infra_me.ca-bundle")
}

# HTTPS listener for the load balancer
resource "aws_lb_listener" "https" {
  load_balancer_arn = aws_lb.app_lb.arn
  port              = 443
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-2016-08"
  
  # Use the appropriate certificate based on environment
  certificate_arn   = var.environment == "dev" ? data.aws_acm_certificate.dev_cert[0].arn : aws_acm_certificate.demo_cert[0].arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.app_tg.arn
  }
}

# HTTP listener for the load balancer
resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.app_lb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.app_tg.arn
  }
}
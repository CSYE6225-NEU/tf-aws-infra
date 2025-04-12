# --------------------------------------------------------------------------------------
# AUTO SCALING RESOURCES
# --------------------------------------------------------------------------------------

# Launch template for EC2 instances
resource "aws_launch_template" "app_launch_template" {
  name          = "csye6225_asg"
  image_id      = var.aws_base_ami
  instance_type = var.aws_vm_size
  key_name      = var.key_name

  iam_instance_profile {
    name = aws_iam_instance_profile.ec2_profile.name
  }

  network_interfaces {
    associate_public_ip_address = true
    security_groups             = [aws_security_group.application_sg.id]
  }

  block_device_mappings {
    device_name = "/dev/sda1"

    ebs {
      volume_size           = var.volume_size
      volume_type           = var.volume_type
      delete_on_termination = true
      encrypted             = true
      kms_key_id            = aws_kms_key.ec2_key.arn
    }
  }

  # Improved user data script with proper escaping
  user_data = base64encode(<<-EOF
#!/bin/bash
set -e

# Log all script execution for debugging
exec > >(tee /var/log/user-data.log) 2>&1
echo "Starting instance initialization at $$(date)"

# Update packages and install dependencies
apt-get update
apt-get install -y python3 python3-pip nodejs npm awscli jq unzip curl

# Create application directories
mkdir -p /opt/csye6225/app
mkdir -p /opt/csye6225/logs

# Retrieve database credentials from AWS Secrets Manager
echo "Retrieving database credentials from Secrets Manager..."
DB_SECRET=$$(aws secretsmanager get-secret-value --secret-id csye6225/db/password --region ${var.aws_build_region} --query SecretString --output text)
DB_PASSWORD=$$(echo $$DB_SECRET | jq -r '.password')

# Create application config file
cat > /opt/csye6225/.env <<EOL
# Database Configuration
DB_HOST=${aws_db_instance.csye6225_db.address}
DB_PORT=${var.db_port}
DB_NAME=csye6225
DB_USER=csye6225
DB_PASSWORD=$$DB_PASSWORD

# S3 Configuration
S3_BUCKET_NAME=${aws_s3_bucket.app_files.id}
PORT=${var.app_port}
EOL

chmod 600 /opt/csye6225/.env

# Create a simple health check server
cat > /opt/csye6225/app/server.js <<EOL
const http = require('http');
const fs = require('fs');
const port = process.env.PORT || ${var.app_port};

const server = http.createServer((req, res) => {
  if (req.url === '/healthz' || req.url === '/') {
    res.writeHead(200, { 'Content-Type': 'application/json' });
    res.end(JSON.stringify({ status: 'ok', timestamp: new Date().toISOString() }));
  } else if (req.url === '/cicd') {
    res.writeHead(200, { 'Content-Type': 'application/json' });
    res.end(JSON.stringify({ status: 'ok', message: 'CI/CD endpoint working', timestamp: new Date().toISOString() }));
  } else {
    res.writeHead(404);
    res.end(JSON.stringify({ status: 'not found' }));
  }
});

server.listen(port, () => {
  console.log(\`Server running on port \$${port}\`);
  // Log to a file for CloudWatch to pick up
  fs.appendFileSync('/opt/csye6225/logs/webapp.log', \`Server started at \$${new Date().toISOString()}\n\`);
});

// Handle errors
server.on('error', (err) => {
  console.error(\`Server error: \$${err.message}\`);
  fs.appendFileSync('/opt/csye6225/logs/webapp.log', \`ERROR: \$${err.message} at \$${new Date().toISOString()}\n\`);
});
EOL

# Create a systemd service file for the application
cat > /etc/systemd/system/webapp.service <<EOL
[Unit]
Description=Web Application Service
After=network.target

[Service]
Environment=NODE_ENV=production
WorkingDirectory=/opt/csye6225/app
EnvironmentFile=/opt/csye6225/.env
ExecStart=/usr/bin/node /opt/csye6225/app/server.js
Restart=always
RestartSec=10
StandardOutput=append:/opt/csye6225/logs/webapp.log
StandardError=append:/opt/csye6225/logs/webapp.log
User=root
Group=root

[Install]
WantedBy=multi-user.target
EOL

# Install node if not present
if ! command -v node &> /dev/null; then
  echo "Installing Node.js..."
  curl -fsSL https://deb.nodesource.com/setup_16.x | bash -
  apt-get install -y nodejs
fi

# Create log file and set permissions
touch /opt/csye6225/logs/webapp.log
chmod 644 /opt/csye6225/logs/webapp.log

# Enable and start the application service
systemctl daemon-reload
systemctl enable webapp.service
systemctl start webapp.service

# Setup CloudWatch agent for monitoring
curl -o /tmp/amazon-cloudwatch-agent.deb https://amazoncloudwatch-agent.s3.amazonaws.com/debian/amd64/latest/amazon-cloudwatch-agent.deb
dpkg -i -E /tmp/amazon-cloudwatch-agent.deb

# Configure CloudWatch Agent
mkdir -p /opt/aws/amazon-cloudwatch-agent/etc
cat > /opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json <<EOL
{
  "agent": {
    "metrics_collection_interval": 60,
    "run_as_user": "root"
  },
  "logs": {
    "logs_collected": {
      "files": {
        "collect_list": [
          {
            "file_path": "/var/log/syslog",
            "log_group_name": "syslog",
            "log_stream_name": "{instance_id}",
            "timezone": "UTC"
          },
          {
            "file_path": "/opt/csye6225/logs/webapp.log",
            "log_group_name": "webapp-logs",
            "log_stream_name": "{instance_id}",
            "timezone": "UTC"
          }
        ]
      }
    }
  },
  "metrics": {
    "metrics_collected": {
      "cpu": {
        "resources": ["*"],
        "measurement": ["cpu_usage_idle", "cpu_usage_user", "cpu_usage_system"]
      },
      "mem": {
        "measurement": ["mem_used_percent"]
      },
      "disk": {
        "resources": ["/"],
        "measurement": ["disk_used_percent"]
      }
    }
  }
}
EOL

# Start CloudWatch agent
systemctl enable amazon-cloudwatch-agent
systemctl start amazon-cloudwatch-agent

echo "Instance setup completed at $$(date)"
EOF
  )

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name = "WebApp-ASG-Instance"
    }
  }
}

# Auto Scaling Group
resource "aws_autoscaling_group" "webapp_asg" {
  name                = "webapp-asg"
  min_size            = 3
  max_size            = 5
  desired_capacity    = 3
  default_cooldown    = 300
  vpc_zone_identifier = aws_subnet.public[*].id
  depends_on          = [aws_db_instance.csye6225_db]

  launch_template {
    id      = aws_launch_template.app_launch_template.id
    version = "$Latest"
  }

  target_group_arns = [aws_lb_target_group.app_tg.arn]

  # Extended health check grace period to allow for proper instance initialization
  health_check_grace_period = 900
  health_check_type         = "ELB"

  tag {
    key                 = "Name"
    value               = "WebApp-ASG-Instance"
    propagate_at_launch = true
  }

  tag {
    key                 = "Application"
    value               = "CSYE6225"
    propagate_at_launch = true
  }

  # Timeouts - removed unsupported "create" argument
  timeouts {
    delete = "20m"
    update = "20m"
  }

  # Ignore changes to desired capacity from scaling policies
  lifecycle {
    ignore_changes = [desired_capacity]
  }
}

# Scale Up Policy - CPU Utilization
resource "aws_autoscaling_policy" "scale_up" {
  name                   = "webapp-scale-up"
  autoscaling_group_name = aws_autoscaling_group.webapp_asg.name
  adjustment_type        = "ChangeInCapacity"
  scaling_adjustment     = 1
  cooldown               = 300
  policy_type            = "SimpleScaling"
}

# Scale Down Policy - CPU Utilization
resource "aws_autoscaling_policy" "scale_down" {
  name                   = "webapp-scale-down"
  autoscaling_group_name = aws_autoscaling_group.webapp_asg.name
  adjustment_type        = "ChangeInCapacity"
  scaling_adjustment     = -1
  cooldown               = 300
  policy_type            = "SimpleScaling"
}

# CloudWatch Alarm for High CPU Utilization
resource "aws_cloudwatch_metric_alarm" "high_cpu" {
  alarm_name          = "webapp-high-cpu"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 300
  statistic           = "Average"
  threshold           = 5
  alarm_description   = "Scale up when CPU exceeds 5%"
  alarm_actions       = [aws_autoscaling_policy.scale_up.arn]

  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.webapp_asg.name
  }
}

# CloudWatch Alarm for Low CPU Utilization
resource "aws_cloudwatch_metric_alarm" "low_cpu" {
  alarm_name          = "webapp-low-cpu"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 300
  statistic           = "Average"
  threshold           = 3
  alarm_description   = "Scale down when CPU is below 3%"
  alarm_actions       = [aws_autoscaling_policy.scale_down.arn]

  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.webapp_asg.name
  }
}
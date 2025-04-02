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
    }
  }

  # User data script to configure application with database details and CloudWatch
  user_data = base64encode(<<-EOF
#!/bin/bash
# Create application config directory if it doesn't exist
mkdir -p /opt/csye6225

# Create application config file
cat > /opt/csye6225/.env <<EOL
# Database Configuration
DB_HOST=${aws_db_instance.csye6225_db.address}
DB_PORT=${var.db_port}
DB_NAME=${aws_db_instance.csye6225_db.db_name}
DB_USER=${aws_db_instance.csye6225_db.username}
DB_PASSWORD=${var.db_password}

# S3 Configuration
S3_BUCKET_NAME=${aws_s3_bucket.app_files.id}
PORT=${var.app_port}
EOL

# Update permissions
chown csye6225:csye6225 /opt/csye6225/.env
chmod 600 /opt/csye6225/.env

# Create empty log file for application logs
touch /opt/csye6225/webapp.log
chown csye6225:csye6225 /opt/csye6225/webapp.log
chmod 644 /opt/csye6225/webapp.log

# Get instance ID from metadata service
INSTANCE_ID=$(curl -s http://169.254.169.254/latest/meta-data/instance-id)

# Configure CloudWatch agent
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
            "log_group_name": "$INSTANCE_ID-system-logs",
            "log_stream_name": "syslog",
            "timezone": "UTC"
          },
          {
            "file_path": "/var/log/amazon/amazon-cloudwatch-agent/amazon-cloudwatch-agent.log",
            "log_group_name": "$INSTANCE_ID-cloudwatch-agent-logs",
            "log_stream_name": "amazon-cloudwatch-agent.log",
            "timezone": "UTC"
          },
          {
            "file_path": "/opt/csye6225/webapp.log",
            "log_group_name": "$INSTANCE_ID-application-logs",
            "log_stream_name": "webapp.log",
            "timezone": "UTC"
          }
        ]
      }
    }
  },
  "metrics": {
    "namespace": "CSYE6225/Custom",
    "append_dimensions": {
      "InstanceId": "$INSTANCE_ID",
      "InstanceType": "${var.aws_vm_size}"
    },
    "metrics_collected": {
      "statsd": {
        "service_address": ":8125",
        "metrics_collection_interval": 10,
        "metrics_aggregation_interval": 60
      },
      "cpu": {
        "resources": ["*"],
        "measurement": [
          "cpu_usage_idle",
          "cpu_usage_iowait",
          "cpu_usage_user",
          "cpu_usage_system"
        ],
        "totalcpu": true
      },
      "disk": {
        "resources": ["*"],
        "measurement": [
          "used_percent",
          "inodes_free"
        ]
      },
      "diskio": {
        "resources": ["*"],
        "measurement": [
          "io_time"
        ]
      },
      "mem": {
        "measurement": [
          "mem_used_percent"
        ]
      },
      "swap": {
        "measurement": [
          "swap_used_percent"
        ]
      }
    }
  }
}
EOL

# Restart CloudWatch agent
systemctl restart amazon-cloudwatch-agent

# Restart application service
systemctl restart webapp.service
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
  default_cooldown    = 60
  vpc_zone_identifier = aws_subnet.public[*].id

  launch_template {
    id      = aws_launch_template.app_launch_template.id
    version = "$Latest"
  }

  target_group_arns = [aws_lb_target_group.app_tg.arn]

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
}

# Scale Up Policy - CPU Utilization
resource "aws_autoscaling_policy" "scale_up" {
  name                   = "webapp-scale-up"
  autoscaling_group_name = aws_autoscaling_group.webapp_asg.name
  adjustment_type        = "ChangeInCapacity"
  scaling_adjustment     = 1
  cooldown               = 60
  policy_type            = "SimpleScaling"
}

# Scale Down Policy - CPU Utilization
resource "aws_autoscaling_policy" "scale_down" {
  name                   = "webapp-scale-down"
  autoscaling_group_name = aws_autoscaling_group.webapp_asg.name
  adjustment_type        = "ChangeInCapacity"
  scaling_adjustment     = -1
  cooldown               = 60
  policy_type            = "SimpleScaling"
}

# CloudWatch Alarm for High CPU Utilization
resource "aws_cloudwatch_metric_alarm" "high_cpu" {
  alarm_name          = "webapp-high-cpu"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 60
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
  period              = 60
  statistic           = "Average"
  threshold           = 3
  alarm_description   = "Scale down when CPU is below 3%"
  alarm_actions       = [aws_autoscaling_policy.scale_down.arn]

  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.webapp_asg.name
  }
}
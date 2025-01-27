# AWS Provider Configuration
provider "aws" {
  region = "us-east-1"  # Update with your desired region
}
data "aws_availability_zones" "available" {
  state = "available"
}

variable "instance_type" {
  description = "Type of EC2 instance"
}

variable "key_name" {
  description = "Name of the SSH key pair"
}



data "aws_ami" "latest_ami" {
  most_recent = true
  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }
  owners = ["amazon"]
}


# VPC Configuration
resource "aws_vpc" "main" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags = { Name = "Part02autoscaling-vpc" }
}

# Subnet Configuration
resource "aws_subnet" "subnets" {
  count                   = 3  # Create three subnets in different Availability Zones
  vpc_id                  = aws_vpc.main.id
  cidr_block              = cidrsubnet(aws_vpc.main.cidr_block, 8, count.index)
  availability_zone       = data.aws_availability_zones.available.names[count.index]
  map_public_ip_on_launch = true

  tags = {
    Name = "subnet-${count.index + 1}"
  }
}

# Internet Gateway
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id
  tags   = { Name = "main-igw" }
}

# Route Table
resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.main.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }
}

# Associate Route Table with Subnet
resource "aws_route_table_association" "subnet_association" {
  count          = length(aws_subnet.subnets)
  subnet_id      = aws_subnet.subnets[count.index].id
  route_table_id = aws_route_table.public_rt.id
}

# Security Group
resource "aws_security_group" "web_sg" {
  vpc_id = aws_vpc.main.id
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  # Allow HTTPS (port 443) traffic
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Allow custom HTTP (port 8080) traffic
  ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = { Name = "web-sg" }
}

# DB Security Group
#resource "aws_security_group" "db_sg" {
#  name        = "db-sg"
#  description = "Security group for the database allowing ingress from web servers"
#  vpc_id      = aws_vpc.main.id
#  ingress {
#    from_port       = 5432          # Adjust based on your DB engine (5432 for PostgreSQL)
#    to_port         = 5432
#    protocol        = "tcp"
#    security_groups = [aws_security_group.web_sg.id]  # Allowing traffic from web_sg
#  }

#  egress {
#    from_port   = 0
#    to_port     = 0
#    protocol    = "-1"
#    cidr_blocks = ["0.0.0.0/0"]
#  }

#  tags = {
#    Name = "db-sg"
#  }
#}


resource "aws_launch_template" "app_lt" {
  name_prefix   = "app-launch-template-"
  image_id      = data.aws_ami.latest_ami.id
  instance_type = var.instance_type
  key_name      = var.key_name

  network_interfaces {
    security_groups = [aws_security_group.web_sg.id]
    associate_public_ip_address = true
  }

  lifecycle {
    create_before_destroy = true
  }

  tags = {
    Name = "app-launch-template"
  }
}

# Auto Scaling Group
resource "aws_autoscaling_group" "app_asg" {
  launch_template {
    id      = aws_launch_template.app_lt.id
    version = "$Latest"
  } 
  min_size             = 1
  max_size             = 5
  desired_capacity     = 1
  vpc_zone_identifier  = aws_subnet.subnets[*].id
  health_check_type    = "EC2"
  health_check_grace_period = 300

  tag {
    key                 = "Name"
    value               = "autoscaling-instance"
    propagate_at_launch = true
  }
}

# Scale Up Policy
resource "aws_autoscaling_policy" "scale_up" {
  name                   = "scale-up-policy"
  scaling_adjustment     = 1
  adjustment_type        = "ChangeInCapacity"
  autoscaling_group_name = aws_autoscaling_group.app_asg.name
}

# Scale Down Policy
resource "aws_autoscaling_policy" "scale_down" {
  name                   = "scale-down-policy"
  scaling_adjustment     = -1
  adjustment_type        = "ChangeInCapacity"
  autoscaling_group_name = aws_autoscaling_group.app_asg.name
}

# CloudWatch Alarm for Scale Up
resource "aws_cloudwatch_metric_alarm" "scale_up_alarm" {
  alarm_name          = "scale-up-cpu-utilization"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 60
  statistic           = "Average"
  threshold           = 70
  alarm_actions       = [aws_autoscaling_policy.scale_up.arn]
  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.app_asg.name
  }
}

# CloudWatch Alarm for Scale Down
resource "aws_cloudwatch_metric_alarm" "scale_down_alarm" {
  alarm_name          = "scale-down-cpu-utilization"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 60
  statistic           = "Average"
  threshold           = 40
  alarm_actions       = [aws_autoscaling_policy.scale_down.arn]
  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.app_asg.name
  }
}

# Elastic Load Balancer
resource "aws_lb" "web_elb" {
  name               = "web-elb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.web_sg.id]
  subnets            = aws_subnet.subnets[*].id

  enable_deletion_protection = false

  tags = {
    Name = "web-elb1"
  }
}

# Target Group for ELB
resource "aws_lb_target_group" "web_target" {
  name     = "web-target-group"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.main.id

  health_check {
    protocol = "HTTP"
    path     = "/"
  }

  tags = {
    Name = "web-target-group"
  }
}

# Listener for ELB
resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.web_elb.arn
  port              = 80
  protocol          = "HTTP"
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.web_target.arn
  }
}

# Attach Target Group to Auto Scaling Group
resource "aws_autoscaling_attachment" "asg_target" {
  autoscaling_group_name = aws_autoscaling_group.app_asg.name
  lb_target_group_arn   = aws_lb_target_group.web_target.arn
}

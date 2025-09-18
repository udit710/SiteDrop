terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

# Data sources
data "aws_availability_zones" "available" {
  state = "available"
}

data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }
}

# Security group
resource "aws_security_group" "web" {
  name_prefix = "${var.project_name}-web-"
  description = "Security group for Docker-based static site hosting"

  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTPS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]  # Consider restricting this in production
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project_name}-security-group"
  }
}

# Key pair for deployment access
resource "aws_key_pair" "deployer" {
  key_name   = "${var.project_name}-deployer-key"
  public_key = var.ssh_public_key

  tags = {
    Name = "${var.project_name}-deployer-key"
  }
}

# User data script for Docker setup
locals {
  user_data = base64encode(templatefile("${path.module}/user-data.sh", {
    deployment_dir = var.deployment_dir
  }))
}

# EC2 Instance
resource "aws_instance" "web" {
  ami                    = data.aws_ami.amazon_linux.id
  instance_type          = var.instance_type
  key_name              = aws_key_pair.deployer.key_name
  vpc_security_group_ids = [aws_security_group.web.id]
  user_data             = local.user_data

  root_block_device {
    volume_size = 20
    volume_type = "gp3"
    encrypted   = true

    tags = {
      Name = "${var.project_name}-root-volume"
    }
  }

  tags = {
    Name        = var.project_name
    Environment = var.environment
    ManagedBy   = "terraform"
    Type        = "docker-enabled"
    Project     = "static-site-deployer"
  }

  lifecycle {
    create_before_destroy = true
  }
}

# Elastic IP for consistent access
resource "aws_eip" "web" {
  instance = aws_instance.web.id
  domain   = "vpc"

  tags = {
    Name = "${var.project_name}-eip"
  }

  depends_on = [aws_instance.web]
}

variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Name of the project (used for resource naming)"
  type        = string
  default     = "static-site-docker"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "production"
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.micro"

  validation {
    condition = contains([
      "t2.micro", "t2.small", "t2.medium",
      "t3.micro", "t3.small", "t3.medium",
      "t3a.micro", "t3a.small", "t3a.medium"
    ], var.instance_type)
    error_message = "Instance type must be a valid t2, t3, or t3a instance type."
  }
}

variable "ssh_public_key" {
  description = "SSH public key for instance access"
  type        = string
  # This will be provided by GitHub Actions
}

variable "deployment_dir" {
  description = "Directory for deployments on the instance"
  type        = string
  default     = "/opt/static-site"
}

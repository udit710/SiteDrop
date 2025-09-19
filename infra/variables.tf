variable "aws_region" {
  description = "AWS region to deploy resources"
  type        = string
  default     = "us-east-1"
}

variable "bucket_name" {
  description = "Unique name for the S3 bucket"
  type        = string
}

variable "project_name" {
  description = "Project name prefix"
  type        = string
  default     = "sitedrop"
}

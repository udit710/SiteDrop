terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  backend "s3" {
    bucket = "terraform-state-${var.project_name}"
    key    = "infrastructure/terraform.tfstate"
    region = "us-east-1"

    # Optional: Enable state locking with DynamoDB
    dynamodb_table = "terraform-state-lock"
    encrypt        = true
  }
}

provider "aws" {
  region = var.aws_region
}

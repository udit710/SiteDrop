terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
  backend "s3" {
    bucket = "my-sitedrop-terraform-state"
    key    = "sitedrop/terraform.tfstate"
    region = "us-east-1"
    dynamodb_table = "sitedrop-lock" # optional, prevents concurrent writes
    encrypt = true
  }
}

provider "aws" {
  region = var.aws_region
}

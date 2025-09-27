output "s3_bucket" {
  description = "S3 bucket name for site uploads"
  value       = aws_s3_bucket.site.bucket
}

output "cloudfront_url" {
  description = "CloudFront domain for accessing the site"
  value       = aws_cloudfront_distribution.cdn.domain_name
}

output "cloudfront_id" {
  description = "CloudFront distribution ID"
  value       = aws_cloudfront_distribution.cdn.id
}

# Add output for state bucket (used in first deployment)
output "terraform_state_bucket" {
  description = "S3 bucket used for Terraform state"
  value       = aws_s3_bucket.terraform_state.bucket
}
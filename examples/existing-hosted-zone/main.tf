# Example for AWS Static Website Module with existing hosted zone
# This example demonstrates how to use an existing Route 53 hosted zone

terraform {
  required_version = ">= 1.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# Configure AWS Provider
provider "aws" {
  region = "us-east-1"  # CloudFront requires us-east-1 for certificates
}

# Static website deployment using existing hosted zone
module "static_website" {
  source = "../../"

  # Required variables
  project_name = "existing-zone-website"
  bucket_name  = "existing-zone-website-bucket-2024"
  domain_name  = "example.com"

  # Use existing hosted zone
  create_hosted_zone = false
  hosted_zone_id     = "Z1234567890ABC"  # Replace with your actual hosted zone ID

  # Certificate and DNS Configuration
  create_certificate = true
  subject_alternative_names = ["www.example.com"]
  create_dns_record = true
  create_www_record = true

  # S3 Configuration
  index_document = "index.html"
  error_document = "error.html"
  enable_versioning = false

  # CloudFront Configuration
  cloudfront_price_class = "PriceClass_100"
  enable_cloudfront_logging = false

  # Common tags
  common_tags = {
    Environment = "production"
    Project     = "existing-zone-website"
    Owner       = "devops-team"
    ManagedBy   = "terraform"
  }
}

# Outputs
output "website_url" {
  description = "The URL of the website"
  value       = module.static_website.website_url
}

output "s3_bucket_name" {
  description = "The name of the S3 bucket"
  value       = module.static_website.s3_bucket_id
}

output "cloudfront_distribution_id" {
  description = "The ID of the CloudFront distribution"
  value       = module.static_website.cloudfront_distribution_id
}

output "route53_zone_id" {
  description = "The ID of the Route 53 hosted zone"
  value       = module.static_website.route53_zone_id
}

output "certificate_validation_records" {
  description = "DNS records required for certificate validation"
  value       = module.static_website.certificate_validation_records
  sensitive   = true
} 
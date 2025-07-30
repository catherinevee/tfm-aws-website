# Test configuration for AWS Static Website Module
# This configuration is used for testing the module functionality

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
  region = "us-east-1"
}

# Test static website deployment
module "test_website" {
  source = "../"

  # Required variables
  project_name = "test-website"
  bucket_name  = "test-website-bucket-2024"
  domain_name  = "test.example.com"

  # Minimal configuration for testing
  index_document = "index.html"
  error_document = "error.html"
  enable_versioning = false

  # Certificate and DNS (disabled for testing)
  create_certificate = false
  create_hosted_zone = false
  create_dns_record = false
  create_www_record = false

  # CloudFront configuration
  cloudfront_price_class = "PriceClass_100"
  enable_cloudfront_logging = false

  # Common tags
  common_tags = {
    Environment = "test"
    Project     = "test-website"
    Owner       = "test-team"
    ManagedBy   = "terraform"
  }
}

# Test outputs
output "test_website_url" {
  description = "The URL of the test website"
  value       = module.test_website.website_url
}

output "test_s3_bucket_name" {
  description = "The name of the test S3 bucket"
  value       = module.test_website.s3_bucket_id
}

output "test_cloudfront_distribution_id" {
  description = "The ID of the test CloudFront distribution"
  value       = module.test_website.cloudfront_distribution_id
} 
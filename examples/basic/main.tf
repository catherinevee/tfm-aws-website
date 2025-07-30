# Basic example for AWS Static Website Module
# This example demonstrates the minimal configuration required to deploy a static website

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

# Basic static website deployment
module "static_website" {
  source = "../../"

  # Required variables
  project_name = "example-website"
  bucket_name  = "example-website-bucket-2024"
  domain_name  = "example.com"

  # Optional configuration with sensible defaults
  index_document = "index.html"
  error_document = "error.html"
  enable_versioning = false

  # Certificate and DNS
  create_certificate = true
  create_hosted_zone = true
  create_dns_record = true
  create_www_record = true

  # CloudFront configuration
  cloudfront_price_class = "PriceClass_100"

  # Common tags for resource management
  common_tags = {
    Environment = "production"
    Project     = "example-website"
    Owner       = "devops-team"
    ManagedBy   = "terraform"
  }
}

# Output the important information
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

output "name_servers" {
  description = "The name servers for the hosted zone"
  value       = module.static_website.route53_zone_name_servers
} 
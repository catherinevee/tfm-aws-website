# Advanced example for AWS Static Website Module
# This example demonstrates all available features and configurations

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

# Advanced static website deployment with all features
module "static_website" {
  source = "../../"

  # Required variables
  project_name = "advanced-website"
  bucket_name  = "advanced-website-bucket-2024"
  domain_name  = "example.com"

  # S3 Configuration
  index_document = "index.html"
  error_document = "404.html"
  enable_versioning = true

  # S3 routing rules for Single Page Application (SPA)
  routing_rules = [
    {
      key_prefix_equals = "app/"
      replace_key_with  = "app/index.html"
    },
    {
      key_prefix_equals = "admin/"
      replace_key_with  = "admin/index.html"
    }
  ]

  # Certificate and DNS Configuration
  create_certificate = true
  subject_alternative_names = [
    "www.example.com",
    "api.example.com",
    "cdn.example.com"
  ]
  create_hosted_zone = true
  create_dns_record = true
  create_ipv6_record = true
  create_www_record = true

  # CloudFront Configuration
  cloudfront_price_class = "PriceClass_200"  # More edge locations
  enable_cloudfront_logging = true
  cloudfront_log_retention_days = 90

  # Custom error responses for SPA
  custom_error_responses = [
    {
      error_code            = 404
      response_code         = "200"
      response_page_path    = "/index.html"
      error_caching_min_ttl = 300
    },
    {
      error_code            = 403
      response_code         = "200"
      response_page_path    = "/index.html"
      error_caching_min_ttl = 300
    }
  ]

  # Geographic restrictions (optional)
  geo_restrictions = {
    restriction_type = "whitelist"
    locations        = ["US", "CA", "GB", "DE", "FR", "AU"]
  }

  # WAF Configuration for security
  enable_waf = true
  waf_rules = [
    {
      name                    = "AWSManagedRulesCommonRuleSet"
      priority                = 1
      override_action         = "none"
      managed_rule_group_name = "AWSManagedRulesCommonRuleSet"
      vendor_name             = "AWS"
    },
    {
      name                    = "AWSManagedRulesKnownBadInputsRuleSet"
      priority                = 2
      override_action         = "none"
      managed_rule_group_name = "AWSManagedRulesKnownBadInputsRuleSet"
      vendor_name             = "AWS"
    },
    {
      name                    = "AWSManagedRulesSQLiRuleSet"
      priority                = 3
      override_action         = "none"
      managed_rule_group_name = "AWSManagedRulesSQLiRuleSet"
      vendor_name             = "AWS"
    },
    {
      name                    = "AWSManagedRulesLinuxRuleSet"
      priority                = 4
      override_action         = "none"
      managed_rule_group_name = "AWSManagedRulesLinuxRuleSet"
      vendor_name             = "AWS"
    }
  ]

  # Comprehensive tagging
  common_tags = {
    Environment = "production"
    Project     = "advanced-website"
    Owner       = "devops-team"
    ManagedBy   = "terraform"
    CostCenter  = "marketing"
    Application = "static-website"
    Security    = "high"
  }
}

# Outputs for monitoring and management
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

output "cloudfront_distribution_domain" {
  description = "The CloudFront distribution domain name"
  value       = module.static_website.cloudfront_distribution_domain_name
}

output "route53_zone_id" {
  description = "The ID of the Route 53 hosted zone"
  value       = module.static_website.route53_zone_id
}

output "name_servers" {
  description = "The name servers for the hosted zone"
  value       = module.static_website.route53_zone_name_servers
}

output "acm_certificate_arn" {
  description = "The ARN of the ACM certificate"
  value       = module.static_website.acm_certificate_arn
}

output "waf_web_acl_id" {
  description = "The ID of the WAF Web ACL"
  value       = module.static_website.waf_web_acl_id
}

output "cloudwatch_log_group_name" {
  description = "The name of the CloudWatch log group"
  value       = module.static_website.cloudwatch_log_group_name
}

output "certificate_validation_records" {
  description = "DNS records required for certificate validation"
  value       = module.static_website.certificate_validation_records
  sensitive   = true
} 
# S3 Bucket Outputs
output "s3_bucket_id" {
  description = "The name of the S3 bucket"
  value       = aws_s3_bucket.website.id
}

output "s3_bucket_arn" {
  description = "The ARN of the S3 bucket"
  value       = aws_s3_bucket.website.arn
}

output "s3_bucket_website_endpoint" {
  description = "The website endpoint of the S3 bucket"
  value       = aws_s3_bucket_website_configuration.website.website_endpoint
}

output "s3_bucket_website_domain" {
  description = "The domain of the S3 bucket website"
  value       = aws_s3_bucket_website_configuration.website.website_domain
}

# CloudFront Outputs
output "cloudfront_distribution_id" {
  description = "The ID of the CloudFront distribution"
  value       = aws_cloudfront_distribution.website.id
}

output "cloudfront_distribution_arn" {
  description = "The ARN of the CloudFront distribution"
  value       = aws_cloudfront_distribution.website.arn
}

output "cloudfront_distribution_domain_name" {
  description = "The domain name of the CloudFront distribution"
  value       = aws_cloudfront_distribution.website.domain_name
}

output "cloudfront_distribution_hosted_zone_id" {
  description = "The hosted zone ID of the CloudFront distribution"
  value       = aws_cloudfront_distribution.website.hosted_zone_id
}

output "cloudfront_distribution_status" {
  description = "The status of the CloudFront distribution"
  value       = aws_cloudfront_distribution.website.status
}

# ACM Certificate Outputs
output "acm_certificate_arn" {
  description = "The ARN of the ACM certificate"
  value       = var.create_certificate ? aws_acm_certificate.website[0].arn : null
}

output "acm_certificate_validation_arn" {
  description = "The ARN of the validated ACM certificate"
  value       = var.create_certificate ? aws_acm_certificate_validation.website[0].certificate_arn : null
}

output "acm_certificate_status" {
  description = "The status of the ACM certificate"
  value       = var.create_certificate ? aws_acm_certificate.website[0].status : null
}

# Route 53 Outputs
output "route53_zone_id" {
  description = "The ID of the Route 53 hosted zone"
  value       = var.create_hosted_zone ? aws_route53_zone.website[0].zone_id : var.hosted_zone_id
}

output "route53_zone_name_servers" {
  description = "The name servers of the Route 53 hosted zone"
  value       = var.create_hosted_zone ? aws_route53_zone.website[0].name_servers : null
}

output "route53_website_record_name" {
  description = "The name of the Route 53 A record for the website"
  value       = var.create_dns_record ? aws_route53_record.website[0].name : null
}

output "route53_www_record_name" {
  description = "The name of the Route 53 CNAME record for www subdomain"
  value       = var.create_www_record ? aws_route53_record.www[0].name : null
}

# WAF Outputs
output "waf_web_acl_id" {
  description = "The ID of the WAF Web ACL"
  value       = var.enable_waf ? aws_wafv2_web_acl.website[0].id : null
}

output "waf_web_acl_arn" {
  description = "The ARN of the WAF Web ACL"
  value       = var.enable_waf ? aws_wafv2_web_acl.website[0].arn : null
}

# CloudWatch Logs Outputs
output "cloudwatch_log_group_name" {
  description = "The name of the CloudWatch log group for CloudFront"
  value       = var.enable_cloudfront_logging ? aws_cloudwatch_log_group.cloudfront[0].name : null
}

output "cloudwatch_log_group_arn" {
  description = "The ARN of the CloudWatch log group for CloudFront"
  value       = var.enable_cloudfront_logging ? aws_cloudwatch_log_group.cloudfront[0].arn : null
}

# Website URLs
output "website_url" {
  description = "The URL of the website (CloudFront distribution)"
  value       = "https://${var.create_certificate ? var.domain_name : aws_cloudfront_distribution.website.domain_name}"
}

output "s3_website_url" {
  description = "The direct S3 website URL (without CloudFront)"
  value       = "http://${aws_s3_bucket_website_configuration.website.website_endpoint}"
}

# Certificate Validation Records
output "certificate_validation_records" {
  description = "The DNS records required for certificate validation"
  value = var.create_certificate ? {
    for dvo in aws_acm_certificate.website[0].domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      type   = dvo.resource_record_type
      record = dvo.resource_record_value
    }
  } : {}
  sensitive = true
}

# Resource Tags
output "resource_tags" {
  description = "The tags applied to all resources"
  value       = var.common_tags
} 
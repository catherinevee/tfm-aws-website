# AWS Static Website Terraform Module

A comprehensive Terraform module for deploying a static website on AWS with S3, CloudFront, Route 53, and ACM certificate management.

## Features

- **S3 Bucket**: Secure website hosting with encryption and versioning
- **CloudFront CDN**: Global content delivery for improved performance
- **Route 53**: DNS management with custom domain support
- **ACM Certificate**: Free SSL/TLS certificate with automatic validation
- **WAF Integration**: Optional Web Application Firewall protection
- **CloudWatch Logging**: Optional access logging and monitoring
- **IPv6 Support**: Native IPv6 support for modern connectivity

## Architecture

```
Internet → CloudFront → S3 Bucket
    ↓
Route 53 (DNS)
    ↓
ACM Certificate (SSL/TLS)
```

## Usage

### Basic Example

```hcl
module "static_website" {
  source = "./tfm-aws-website"

  project_name = "my-website"
  bucket_name  = "my-website-bucket"
  domain_name  = "example.com"

  common_tags = {
    Environment = "production"
    Project     = "my-website"
    Owner       = "devops-team"
  }
}
```

### Advanced Example with Custom Configuration

```hcl
module "static_website" {
  source = "./tfm-aws-website"

  # Required variables
  project_name = "my-website"
  bucket_name  = "my-website-bucket-2024"
  domain_name  = "example.com"

  # Optional configuration
  index_document = "index.html"
  error_document = "404.html"
  enable_versioning = true

  # Certificate and DNS
  create_certificate = true
  subject_alternative_names = ["www.example.com", "api.example.com"]
  create_hosted_zone = true
  create_dns_record = true
  create_www_record = true

  # CloudFront configuration
  cloudfront_price_class = "PriceClass_100"
  enable_cloudfront_logging = true
  cloudfront_log_retention_days = 90

  # Custom error responses
  custom_error_responses = [
    {
      error_code            = 404
      response_code         = "200"
      response_page_path    = "/index.html"
      error_caching_min_ttl = 300
    }
  ]

  # S3 routing rules for SPA
  routing_rules = [
    {
      key_prefix_equals = "app/"
      replace_key_with  = "app/index.html"
    }
  ]

  # WAF protection
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
    }
  ]

  # Geo restrictions
  geo_restrictions = {
    restriction_type = "whitelist"
    locations        = ["US", "CA", "GB"]
  }

  common_tags = {
    Environment = "production"
    Project     = "my-website"
    Owner       = "devops-team"
    CostCenter  = "marketing"
  }
}
```

### Using Existing Hosted Zone

```hcl
module "static_website" {
  source = "./tfm-aws-website"

  project_name = "my-website"
  bucket_name  = "my-website-bucket"
  domain_name  = "example.com"

  # Use existing hosted zone
  create_hosted_zone = false
  hosted_zone_id     = "Z1234567890ABC"

  common_tags = {
    Environment = "production"
  }
}
```

### Minimal Configuration (No Custom Domain)

```hcl
module "static_website" {
  source = "./tfm-aws-website"

  project_name = "my-website"
  bucket_name  = "my-website-bucket"
  domain_name  = "example.com"

  # Disable custom domain features
  create_certificate = false
  create_dns_record  = false

  common_tags = {
    Environment = "development"
  }
}
```

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.0 |
| aws | ~> 5.0 |

## Providers

| Name | Version |
|------|---------|
| aws | ~> 5.0 |

## Inputs

### Required

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| project_name | Name of the project, used for resource naming and tagging | `string` | n/a | yes |
| bucket_name | Name of the S3 bucket for website hosting | `string` | n/a | yes |
| domain_name | Primary domain name for the website | `string` | n/a | yes |

### Optional

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| common_tags | Common tags to apply to all resources | `map(string)` | `{}` | no |
| index_document | Default index document for the website | `string` | `"index.html"` | no |
| error_document | Error document for the website | `string` | `"error.html"` | no |
| enable_versioning | Enable versioning on the S3 bucket | `bool` | `false` | no |
| create_certificate | Whether to create an ACM certificate for the domain | `bool` | `true` | no |
| subject_alternative_names | Additional domain names for the SSL certificate | `list(string)` | `[]` | no |
| create_hosted_zone | Whether to create a new Route 53 hosted zone | `bool` | `false` | no |
| hosted_zone_id | Existing Route 53 hosted zone ID | `string` | `null` | no |
| create_dns_record | Whether to create DNS records for the domain | `bool` | `true` | no |
| create_ipv6_record | Whether to create IPv6 (AAAA) DNS record | `bool` | `true` | no |
| create_www_record | Whether to create a CNAME record for www subdomain | `bool` | `true` | no |
| cloudfront_price_class | CloudFront price class for the distribution | `string` | `"PriceClass_100"` | no |
| enable_cloudfront_logging | Enable CloudFront access logging to CloudWatch | `bool` | `false` | no |
| cloudfront_log_retention_days | Number of days to retain CloudFront logs | `number` | `30` | no |
| cloudfront_functions | List of CloudFront functions to associate | `list(object)` | `[]` | no |
| custom_error_responses | Custom error responses for CloudFront distribution | `list(object)` | `[]` | no |
| geo_restrictions | Geographic restrictions for CloudFront distribution | `object` | `null` | no |
| routing_rules | S3 website routing rules for redirects | `list(object)` | `[]` | no |
| enable_waf | Whether to enable WAF Web ACL for the CloudFront distribution | `bool` | `false` | no |
| waf_rules | WAF rules to apply to the Web ACL | `list(object)` | `[]` | no |

## Outputs

| Name | Description |
|------|-------------|
| s3_bucket_id | The name of the S3 bucket |
| s3_bucket_arn | The ARN of the S3 bucket |
| s3_bucket_website_endpoint | The website endpoint of the S3 bucket |
| s3_bucket_website_domain | The domain of the S3 bucket website |
| cloudfront_distribution_id | The ID of the CloudFront distribution |
| cloudfront_distribution_arn | The ARN of the CloudFront distribution |
| cloudfront_distribution_domain_name | The domain name of the CloudFront distribution |
| cloudfront_distribution_hosted_zone_id | The hosted zone ID of the CloudFront distribution |
| cloudfront_distribution_status | The status of the CloudFront distribution |
| acm_certificate_arn | The ARN of the ACM certificate |
| acm_certificate_validation_arn | The ARN of the validated ACM certificate |
| acm_certificate_status | The status of the ACM certificate |
| route53_zone_id | The ID of the Route 53 hosted zone |
| route53_zone_name_servers | The name servers of the Route 53 hosted zone |
| route53_website_record_name | The name of the Route 53 A record for the website |
| route53_www_record_name | The name of the Route 53 CNAME record for www subdomain |
| waf_web_acl_id | The ID of the WAF Web ACL |
| waf_web_acl_arn | The ARN of the WAF Web ACL |
| cloudwatch_log_group_name | The name of the CloudWatch log group for CloudFront |
| cloudwatch_log_group_arn | The ARN of the CloudWatch log group for CloudFront |
| website_url | The URL of the website (CloudFront distribution) |
| s3_website_url | The direct S3 website URL (without CloudFront) |
| certificate_validation_records | The DNS records required for certificate validation |
| resource_tags | The tags applied to all resources |

## Security Features

- **S3 Bucket Security**: Private bucket with Origin Access Control (OAC)
- **Encryption**: Server-side encryption enabled by default
- **Public Access Block**: Prevents accidental public access
- **WAF Integration**: Optional Web Application Firewall protection
- **HTTPS Only**: CloudFront configured to redirect HTTP to HTTPS
- **TLS 1.2+**: Minimum TLS version set to 1.2 for security

## Performance Optimizations

- **CloudFront CDN**: Global content delivery network
- **Caching**: Configurable cache behaviors and TTL settings
- **Compression**: Automatic gzip compression for text-based content
- **IPv6 Support**: Native IPv6 connectivity
- **Price Classes**: Configurable CloudFront price classes for cost optimization

## Deployment Steps

1. **Initialize Terraform**:
   ```bash
   terraform init
   ```

2. **Plan the deployment**:
   ```bash
   terraform plan
   ```

3. **Apply the configuration**:
   ```bash
   terraform apply
   ```

4. **Upload website content**:
   ```bash
   aws s3 sync ./website-content s3://your-bucket-name
   ```

## Post-Deployment Tasks

1. **DNS Configuration**: If using an existing hosted zone, update your domain registrar's nameservers to point to the Route 53 nameservers.

2. **Certificate Validation**: If creating a new certificate, ensure the DNS validation records are properly configured.

3. **Content Upload**: Upload your website files to the S3 bucket.

4. **Cache Invalidation**: If needed, invalidate CloudFront cache after content updates:
   ```bash
   aws cloudfront create-invalidation --distribution-id <distribution-id> --paths "/*"
   ```

## Cost Considerations

- **S3 Storage**: Pay for storage and requests
- **CloudFront**: Pay for data transfer and requests
- **Route 53**: Pay for hosted zones and queries
- **ACM**: Free for public certificates
- **WAF**: Pay per request when enabled
- **CloudWatch**: Pay for logs when logging is enabled

## Troubleshooting

### Common Issues

1. **Certificate Validation Fails**: Ensure DNS records are properly configured and propagated.

2. **CloudFront Not Serving Content**: Check S3 bucket policy and Origin Access Control configuration.

3. **DNS Not Resolving**: Verify Route 53 records and nameserver configuration.

4. **403 Forbidden Errors**: Check S3 bucket permissions and CloudFront origin configuration.

### Useful Commands

```bash
# Check S3 bucket policy
aws s3api get-bucket-policy --bucket your-bucket-name

# Verify CloudFront distribution
aws cloudfront get-distribution --id your-distribution-id

# Check Route 53 records
aws route53 list-resource-record-sets --hosted-zone-id your-zone-id

# Test DNS resolution
nslookup your-domain.com
dig your-domain.com
```

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests if applicable
5. Submit a pull request

## License

This module is licensed under the MIT License. See the LICENSE file for details.

## Support

For issues and questions:
- Create an issue in the repository
- Check the troubleshooting section above
- Review AWS documentation for specific services
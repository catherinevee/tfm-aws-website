# AWS Static Website Deployment Guide

This guide provides step-by-step instructions for deploying a static website using the AWS Static Website Terraform Module.

## Prerequisites

Before you begin, ensure you have the following:

1. **AWS CLI** installed and configured with appropriate credentials
2. **Terraform** (version >= 1.0) installed
3. **Domain name** (optional, for custom domain setup)
4. **AWS Account** with appropriate permissions

### Required AWS Permissions

Your AWS credentials should have permissions for:
- S3 (bucket creation, policy management)
- CloudFront (distribution creation, cache invalidation)
- Route 53 (hosted zone and record management)
- ACM (certificate creation and validation)
- IAM (if using CloudWatch logging)
- WAF (if enabling WAF protection)

## Quick Start

### 1. Clone or Download the Module

```bash
# If using git
git clone <repository-url>
cd tfm-aws-website

# Or download and extract the module files
```

### 2. Choose an Example Configuration

Navigate to the `examples` directory and choose a configuration:

- **Basic**: Minimal setup with default settings
- **Advanced**: Full-featured setup with WAF, logging, and custom configurations
- **Existing Hosted Zone**: Use with an existing Route 53 hosted zone

### 3. Customize the Configuration

Edit the `main.tf` file in your chosen example directory:

```hcl
module "static_website" {
  source = "../../"

  # Required variables
  project_name = "my-website"
  bucket_name  = "my-website-bucket-2024"
  domain_name  = "example.com"

  # Optional: Add your custom configuration here
  common_tags = {
    Environment = "production"
    Project     = "my-website"
    Owner       = "devops-team"
  }
}
```

### 4. Deploy the Infrastructure

```bash
# Initialize Terraform
terraform init

# Plan the deployment
terraform plan

# Apply the configuration
terraform apply
```

### 5. Upload Website Content

After successful deployment, upload your website files:

```bash
# Using the provided script
./scripts/deploy-content.sh -b my-website-bucket-2024 -s ./my-website-files

# Or manually with AWS CLI
aws s3 sync ./my-website-files s3://my-website-bucket-2024
```

## Detailed Configuration Options

### Basic Configuration

```hcl
module "static_website" {
  source = "../../"

  # Required variables
  project_name = "my-website"
  bucket_name  = "my-website-bucket"
  domain_name  = "example.com"

  # S3 Configuration
  index_document = "index.html"
  error_document = "error.html"
  enable_versioning = false

  # Certificate and DNS
  create_certificate = true
  create_hosted_zone = true
  create_dns_record = true
  create_www_record = true

  # CloudFront Configuration
  cloudfront_price_class = "PriceClass_100"

  common_tags = {
    Environment = "production"
    Project     = "my-website"
  }
}
```

### Advanced Configuration

```hcl
module "static_website" {
  source = "../../"

  # Required variables
  project_name = "my-website"
  bucket_name  = "my-website-bucket"
  domain_name  = "example.com"

  # S3 Configuration
  index_document = "index.html"
  error_document = "404.html"
  enable_versioning = true

  # S3 routing rules for SPA
  routing_rules = [
    {
      key_prefix_equals = "app/"
      replace_key_with  = "app/index.html"
    }
  ]

  # Certificate and DNS
  create_certificate = true
  subject_alternative_names = ["www.example.com", "api.example.com"]
  create_hosted_zone = true
  create_dns_record = true
  create_www_record = true

  # CloudFront Configuration
  cloudfront_price_class = "PriceClass_200"
  enable_cloudfront_logging = true
  cloudfront_log_retention_days = 90

  # Custom error responses for SPA
  custom_error_responses = [
    {
      error_code            = 404
      response_code         = "200"
      response_page_path    = "/index.html"
      error_caching_min_ttl = 300
    }
  ]

  # WAF Protection
  enable_waf = true
  waf_rules = [
    {
      name                    = "AWSManagedRulesCommonRuleSet"
      priority                = 1
      override_action         = "none"
      managed_rule_group_name = "AWSManagedRulesCommonRuleSet"
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
  }
}
```

## Domain Configuration

### Using a New Domain

1. **Purchase a domain** from a domain registrar (e.g., Route 53, GoDaddy, Namecheap)
2. **Set `create_hosted_zone = true`** in your configuration
3. **Update nameservers** at your domain registrar to point to the Route 53 nameservers (output after deployment)

### Using an Existing Domain

1. **Set `create_hosted_zone = false`** in your configuration
2. **Provide the hosted zone ID**:
   ```hcl
   hosted_zone_id = "Z1234567890ABC"
   ```

## Content Deployment

### Using the Deployment Script

The module includes a deployment script for easy content upload:

```bash
# Basic usage
./scripts/deploy-content.sh -b my-website-bucket

# With custom source directory
./scripts/deploy-content.sh -b my-website-bucket -s ./my-website-files

# With cache invalidation
./scripts/deploy-content.sh -b my-website-bucket -c -i E1234567890ABC

# Dry run (see what would be uploaded)
./scripts/deploy-content.sh -b my-website-bucket -d
```

### Manual Deployment

```bash
# Upload all files
aws s3 sync ./website-content s3://my-website-bucket

# Upload specific files
aws s3 cp ./index.html s3://my-website-bucket/

# Set cache headers for specific file types
aws s3 sync ./website-content s3://my-website-bucket \
  --cache-control "max-age=31536000" \
  --exclude "*" \
  --include "*.css" \
  --include "*.js" \
  --include "*.png" \
  --include "*.jpg" \
  --include "*.gif"
```

## Post-Deployment Tasks

### 1. Verify Deployment

Check that your website is accessible:
- **CloudFront URL**: Available in the Terraform outputs
- **Custom Domain**: If configured, test your domain

### 2. DNS Configuration

If using a custom domain:
1. **Wait for certificate validation** (can take 5-30 minutes)
2. **Update nameservers** at your domain registrar
3. **Test DNS propagation** using tools like `nslookup` or `dig`

### 3. Content Updates

For future content updates:
```bash
# Upload new content
./scripts/deploy-content.sh -b my-website-bucket -s ./updated-content

# Invalidate CloudFront cache
aws cloudfront create-invalidation \
  --distribution-id E1234567890ABC \
  --paths "/*"
```

## Monitoring and Maintenance

### CloudWatch Monitoring

If logging is enabled:
1. **Access logs** in CloudWatch Logs
2. **Set up alarms** for error rates
3. **Monitor performance** metrics

### Cost Optimization

1. **Review CloudFront usage** and adjust price class if needed
2. **Monitor S3 storage** and lifecycle policies
3. **Optimize cache settings** for your content

### Security Best Practices

1. **Regular security updates** for WAF rules
2. **Monitor access logs** for suspicious activity
3. **Review IAM permissions** regularly
4. **Enable CloudTrail** for audit logging

## Troubleshooting

### Common Issues

#### Certificate Validation Fails
- **Check DNS records**: Ensure validation records are created
- **Wait for propagation**: DNS changes can take time
- **Verify domain ownership**: Ensure you control the domain

#### CloudFront Not Serving Content
- **Check S3 bucket policy**: Ensure CloudFront can access the bucket
- **Verify origin configuration**: Check CloudFront distribution settings
- **Check cache settings**: Ensure content is not cached incorrectly

#### 403 Forbidden Errors
- **Verify S3 permissions**: Check bucket policy and ACLs
- **Check CloudFront origin**: Ensure correct S3 bucket is configured
- **Review WAF rules**: If enabled, check for blocking rules

#### DNS Not Resolving
- **Check Route 53 records**: Verify A and CNAME records exist
- **Verify nameservers**: Ensure domain registrar points to Route 53
- **Wait for propagation**: DNS changes can take 24-48 hours

### Useful Commands

```bash
# Check S3 bucket policy
aws s3api get-bucket-policy --bucket my-website-bucket

# Verify CloudFront distribution
aws cloudfront get-distribution --id E1234567890ABC

# Check Route 53 records
aws route53 list-resource-record-sets --hosted-zone-id Z1234567890ABC

# Test DNS resolution
nslookup example.com
dig example.com

# Check certificate status
aws acm describe-certificate --certificate-arn arn:aws:acm:us-east-1:123456789012:certificate/12345678-1234-1234-1234-123456789012
```

## Cleanup

To destroy the infrastructure:

```bash
# Destroy all resources
terraform destroy

# Or destroy specific resources
terraform destroy -target=module.static_website.aws_s3_bucket.website
```

## Support

For issues and questions:
1. **Check the troubleshooting section** above
2. **Review AWS documentation** for specific services
3. **Create an issue** in the module repository
4. **Check Terraform documentation** for general questions

## Additional Resources

- [AWS S3 Static Website Hosting](https://docs.aws.amazon.com/AmazonS3/latest/userguide/WebsiteHosting.html)
- [AWS CloudFront Documentation](https://docs.aws.amazon.com/cloudfront/)
- [AWS Route 53 Documentation](https://docs.aws.amazon.com/route53/)
- [AWS Certificate Manager](https://docs.aws.amazon.com/acm/)
- [Terraform AWS Provider](https://registry.terraform.io/providers/hashicorp/aws/latest/docs) 
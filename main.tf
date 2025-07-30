# S3 Bucket for website hosting
resource "aws_s3_bucket" "website" {
  bucket = var.bucket_name

  tags = merge(var.common_tags, {
    Name = "${var.project_name}-website-bucket"
  })
}

# S3 Bucket versioning
resource "aws_s3_bucket_versioning" "website" {
  bucket = aws_s3_bucket.website.id
  versioning_configuration {
    status = var.enable_versioning ? "Enabled" : "Disabled"
  }
}

# S3 Bucket server-side encryption
resource "aws_s3_bucket_server_side_encryption_configuration" "website" {
  bucket = aws_s3_bucket.website.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# S3 Bucket public access block
resource "aws_s3_bucket_public_access_block" "website" {
  bucket = aws_s3_bucket.website.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# S3 Bucket policy for CloudFront access
resource "aws_s3_bucket_policy" "website" {
  bucket = aws_s3_bucket.website.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "AllowCloudFrontServicePrincipal"
        Effect    = "Allow"
        Principal = {
          Service = "cloudfront.amazonaws.com"
        }
        Action   = "s3:GetObject"
        Resource = "${aws_s3_bucket.website.arn}/*"
        Condition = {
          StringEquals = {
            "AWS:SourceArn" = aws_cloudfront_distribution.website.arn
          }
        }
      }
    ]
  })

  depends_on = [aws_s3_bucket_public_access_block.website]
}

# S3 Bucket website configuration
resource "aws_s3_bucket_website_configuration" "website" {
  bucket = aws_s3_bucket.website.id

  index_document {
    suffix = var.index_document
  }

  error_document {
    key = var.error_document
  }

  dynamic "routing_rule" {
    for_each = var.routing_rules
    content {
      condition {
        key_prefix_equals = routing_rule.value.key_prefix_equals
      }
      redirect {
        replace_key_with = routing_rule.value.replace_key_with
      }
    }
  }
}

# ACM Certificate
resource "aws_acm_certificate" "website" {
  count = var.create_certificate ? 1 : 0

  domain_name               = var.domain_name
  subject_alternative_names = var.subject_alternative_names
  validation_method         = "DNS"

  lifecycle {
    create_before_destroy = true
  }

  tags = merge(var.common_tags, {
    Name = "${var.project_name}-certificate"
  })
}

# ACM Certificate validation
resource "aws_acm_certificate_validation" "website" {
  count = var.create_certificate ? 1 : 0

  certificate_arn         = aws_acm_certificate.website[0].arn
  validation_record_fqdns = [for record in aws_route53_record.cert_validation : record.fqdn]

  timeouts {
    create = "5m"
  }
}

# CloudFront Origin Access Control
resource "aws_cloudfront_origin_access_control" "website" {
  name                              = "${var.project_name}-oac"
  description                       = "Origin Access Control for S3 website"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

# CloudFront Distribution
resource "aws_cloudfront_distribution" "website" {
  enabled             = true
  is_ipv6_enabled     = true
  default_root_object = var.index_document
  price_class         = var.cloudfront_price_class

  aliases = var.create_certificate ? [var.domain_name] : []

  origin {
    domain_name              = aws_s3_bucket.website.bucket_regional_domain_name
    origin_access_control_id = aws_cloudfront_origin_access_control.website.id
    origin_id                = "S3-${aws_s3_bucket.website.id}"
  }

  default_cache_behavior {
    allowed_methods  = ["GET", "HEAD", "OPTIONS"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = "S3-${aws_s3_bucket.website.id}"

    forwarded_values {
      query_string = false
      cookies {
        forward = "none"
      }
    }

    viewer_protocol_policy = "redirect-to-https"
    min_ttl                = 0
    default_ttl            = 3600
    max_ttl                = 86400

    dynamic "function_association" {
      for_each = var.cloudfront_functions
      content {
        event_type   = function_association.value.event_type
        function_arn = function_association.value.function_arn
      }
    }
  }

  # Error page configuration
  dynamic "custom_error_response" {
    for_each = var.custom_error_responses
    content {
      error_code            = custom_error_response.value.error_code
      response_code         = custom_error_response.value.response_code
      response_page_path    = custom_error_response.value.response_page_path
      error_caching_min_ttl = custom_error_response.value.error_caching_min_ttl
    }
  }

  # Geo restrictions
  dynamic "restrictions" {
    for_each = var.geo_restrictions != null ? [var.geo_restrictions] : []
    content {
      geo_restriction {
        restriction_type = restrictions.value.restriction_type
        locations        = restrictions.value.locations
      }
    }
  }

  # Viewer certificate
  dynamic "viewer_certificate" {
    for_each = var.create_certificate ? [1] : []
    content {
      acm_certificate_arn      = aws_acm_certificate.website[0].arn
      ssl_support_method       = "sni-only"
      minimum_protocol_version = "TLSv1.2_2021"
    }
  }

  # Default viewer certificate (when no custom domain)
  dynamic "viewer_certificate" {
    for_each = var.create_certificate ? [] : [1]
    content {
      cloudfront_default_certificate = true
    }
  }

  tags = merge(var.common_tags, {
    Name = "${var.project_name}-cloudfront-distribution"
  })
}

# Route 53 Hosted Zone (if creating new)
resource "aws_route53_zone" "website" {
  count = var.create_hosted_zone ? 1 : 0

  name = var.domain_name

  tags = merge(var.common_tags, {
    Name = "${var.project_name}-hosted-zone"
  })
}

# Route 53 A record for CloudFront
resource "aws_route53_record" "website" {
  count = var.create_dns_record ? 1 : 0

  zone_id = var.hosted_zone_id != null ? var.hosted_zone_id : aws_route53_zone.website[0].zone_id
  name    = var.domain_name
  type    = "A"

  alias {
    name                   = aws_cloudfront_distribution.website.domain_name
    zone_id                = aws_cloudfront_distribution.website.hosted_zone_id
    evaluate_target_health = false
  }
}

# Route 53 AAAA record for CloudFront (IPv6)
resource "aws_route53_record" "website_ipv6" {
  count = var.create_dns_record && var.create_ipv6_record ? 1 : 0

  zone_id = var.hosted_zone_id != null ? var.hosted_zone_id : aws_route53_zone.website[0].zone_id
  name    = var.domain_name
  type    = "AAAA"

  alias {
    name                   = aws_cloudfront_distribution.website.domain_name
    zone_id                = aws_cloudfront_distribution.website.hosted_zone_id
    evaluate_target_health = false
  }
}

# Route 53 CNAME record for www subdomain
resource "aws_route53_record" "www" {
  count = var.create_www_record ? 1 : 0

  zone_id = var.hosted_zone_id != null ? var.hosted_zone_id : aws_route53_zone.website[0].zone_id
  name    = "www.${var.domain_name}"
  type    = "CNAME"
  ttl     = "300"
  records = [var.domain_name]
}

# Route 53 records for certificate validation
resource "aws_route53_record" "cert_validation" {
  for_each = var.create_certificate ? {
    for dvo in aws_acm_certificate.website[0].domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  } : {}

  allow_overwrite = true
  name            = each.value.name
  records         = [each.value.record]
  ttl             = 60
  type            = each.value.type
  zone_id         = var.hosted_zone_id != null ? var.hosted_zone_id : aws_route53_zone.website[0].zone_id
}

# CloudWatch Log Group for CloudFront
resource "aws_cloudwatch_log_group" "cloudfront" {
  count = var.enable_cloudfront_logging ? 1 : 0

  name              = "/aws/cloudfront/${var.project_name}"
  retention_in_days = var.cloudfront_log_retention_days

  tags = merge(var.common_tags, {
    Name = "${var.project_name}-cloudfront-logs"
  })
}

# IAM Policy for CloudFront logging
resource "aws_iam_policy" "cloudfront_logging" {
  count = var.enable_cloudfront_logging ? 1 : 0

  name        = "${var.project_name}-cloudfront-logging-policy"
  description = "Policy for CloudFront logging to CloudWatch"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "logs:DescribeLogStreams"
        ]
        Resource = "${aws_cloudwatch_log_group.cloudfront[0].arn}:*"
      }
    ]
  })
}

# WAF Web ACL (optional)
resource "aws_wafv2_web_acl" "website" {
  count = var.enable_waf ? 1 : 0

  name        = "${var.project_name}-web-acl"
  description = "Web ACL for ${var.project_name} website"
  scope       = "CLOUDFRONT"

  default_action {
    allow {}
  }

  dynamic "rule" {
    for_each = var.waf_rules
    content {
      name     = rule.value.name
      priority = rule.value.priority

      override_action {
        dynamic "none" {
          for_each = rule.value.override_action == "none" ? [1] : []
          content {}
        }
        dynamic "count" {
          for_each = rule.value.override_action == "count" ? [1] : []
          content {}
        }
      }

      statement {
        managed_rule_group_statement {
          name        = rule.value.managed_rule_group_name
          vendor_name = rule.value.vendor_name
        }
      }

      visibility_config {
        cloudwatch_metrics_enabled = true
        metric_name                = "${rule.value.name}Metric"
        sampled_requests_enabled   = true
      }
    }
  }

  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name                = "${var.project_name}WebACLMetric"
    sampled_requests_enabled   = true
  }

  tags = merge(var.common_tags, {
    Name = "${var.project_name}-web-acl"
  })
}

# WAF Web ACL Association with CloudFront
resource "aws_wafv2_web_acl_association" "website" {
  count = var.enable_waf ? 1 : 0

  resource_arn = aws_cloudfront_distribution.website.arn
  web_acl_arn  = aws_wafv2_web_acl.website[0].arn
} 
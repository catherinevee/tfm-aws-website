# Required Variables
variable "project_name" {
  description = "Name of the project, used for resource naming and tagging"
  type        = string

  validation {
    condition     = can(regex("^[a-zA-Z0-9-]+$", var.project_name))
    error_message = "Project name must contain only alphanumeric characters and hyphens."
  }
}

variable "bucket_name" {
  description = "Name of the S3 bucket for website hosting"
  type        = string

  validation {
    condition     = can(regex("^[a-z0-9][a-z0-9.-]*[a-z0-9]$", var.bucket_name))
    error_message = "Bucket name must be between 3 and 63 characters, contain only lowercase letters, numbers, dots, and hyphens, and start and end with a letter or number."
  }
}

variable "domain_name" {
  description = "Primary domain name for the website"
  type        = string

  validation {
    condition     = can(regex("^[a-zA-Z0-9]([a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?\\.[a-zA-Z]{2,}$", var.domain_name))
    error_message = "Domain name must be a valid domain format."
  }
}

# Optional Variables with Defaults
variable "common_tags" {
  description = "Common tags to apply to all resources"
  type        = map(string)
  default     = {}

  validation {
    condition = alltrue([
      for key, value in var.common_tags : 
      can(regex("^[a-zA-Z0-9_.:/=+-@]+$", key)) && 
      can(regex("^[a-zA-Z0-9_.:/=+-@]+$", value))
    ])
    error_message = "Tags must contain only alphanumeric characters, dots, colons, slashes, equals, plus, minus, and at signs."
  }
}

variable "index_document" {
  description = "Default index document for the website"
  type        = string
  default     = "index.html"
}

variable "error_document" {
  description = "Error document for the website"
  type        = string
  default     = "error.html"
}

variable "enable_versioning" {
  description = "Enable versioning on the S3 bucket"
  type        = bool
  default     = false
}

# Certificate and DNS Configuration
variable "create_certificate" {
  description = "Whether to create an ACM certificate for the domain"
  type        = bool
  default     = true
}

variable "subject_alternative_names" {
  description = "Additional domain names for the SSL certificate"
  type        = list(string)
  default     = []

  validation {
    condition = alltrue([
      for domain in var.subject_alternative_names : 
      can(regex("^[a-zA-Z0-9]([a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?\\.[a-zA-Z]{2,}$", domain))
    ])
    error_message = "All subject alternative names must be valid domain formats."
  }
}

variable "create_hosted_zone" {
  description = "Whether to create a new Route 53 hosted zone"
  type        = bool
  default     = false
}

variable "hosted_zone_id" {
  description = "Existing Route 53 hosted zone ID (required if create_hosted_zone is false)"
  type        = string
  default     = null
}

variable "create_dns_record" {
  description = "Whether to create DNS records for the domain"
  type        = bool
  default     = true
}

variable "create_ipv6_record" {
  description = "Whether to create IPv6 (AAAA) DNS record"
  type        = bool
  default     = true
}

variable "create_www_record" {
  description = "Whether to create a CNAME record for www subdomain"
  type        = bool
  default     = true
}

# CloudFront Configuration
variable "cloudfront_price_class" {
  description = "CloudFront price class for the distribution"
  type        = string
  default     = "PriceClass_100"

  validation {
    condition     = contains(["PriceClass_100", "PriceClass_200", "PriceClass_All"], var.cloudfront_price_class)
    error_message = "CloudFront price class must be one of: PriceClass_100, PriceClass_200, PriceClass_All."
  }
}

variable "enable_cloudfront_logging" {
  description = "Enable CloudFront access logging to CloudWatch"
  type        = bool
  default     = false
}

variable "cloudfront_log_retention_days" {
  description = "Number of days to retain CloudFront logs"
  type        = number
  default     = 30

  validation {
    condition     = var.cloudfront_log_retention_days >= 1 && var.cloudfront_log_retention_days <= 3653
    error_message = "CloudFront log retention must be between 1 and 3653 days."
  }
}

variable "cloudfront_functions" {
  description = "List of CloudFront functions to associate with the distribution"
  type = list(object({
    event_type   = string
    function_arn = string
  }))
  default = []

  validation {
    condition = alltrue([
      for func in var.cloudfront_functions : 
      contains(["viewer-request", "viewer-response"], func.event_type)
    ])
    error_message = "CloudFront function event type must be either 'viewer-request' or 'viewer-response'."
  }
}

variable "custom_error_responses" {
  description = "Custom error responses for CloudFront distribution"
  type = list(object({
    error_code            = number
    response_code         = string
    response_page_path    = string
    error_caching_min_ttl = number
  }))
  default = []

  validation {
    condition = alltrue([
      for error in var.custom_error_responses : 
      error.error_code >= 400 && error.error_code <= 599
    ])
    error_message = "Error codes must be between 400 and 599."
  }
}

variable "geo_restrictions" {
  description = "Geographic restrictions for CloudFront distribution"
  type = object({
    restriction_type = string
    locations        = list(string)
  })
  default = null

  validation {
    condition = var.geo_restrictions == null || contains(["whitelist", "blacklist"], var.geo_restrictions.restriction_type)
    error_message = "Geo restriction type must be either 'whitelist' or 'blacklist'."
  }
}

# S3 Routing Rules
variable "routing_rules" {
  description = "S3 website routing rules for redirects"
  type = list(object({
    key_prefix_equals = string
    replace_key_with  = string
  }))
  default = []
}

# WAF Configuration
variable "enable_waf" {
  description = "Whether to enable WAF Web ACL for the CloudFront distribution"
  type        = bool
  default     = false
}

variable "waf_rules" {
  description = "WAF rules to apply to the Web ACL"
  type = list(object({
    name                    = string
    priority                = number
    override_action         = string
    managed_rule_group_name = string
    vendor_name             = string
  }))
  default = []

  validation {
    condition = alltrue([
      for rule in var.waf_rules : 
      contains(["none", "count"], rule.override_action)
    ])
    error_message = "WAF rule override action must be either 'none' or 'count'."
  }
} 
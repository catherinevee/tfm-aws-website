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

# ==============================================================================
# Enhanced S3 Website Configuration Variables
# ==============================================================================

variable "s3_buckets" {
  description = "Map of S3 buckets to create"
  type = map(object({
    name = string
    force_destroy = optional(bool, false)
    acl = optional(string, null)
    versioning = optional(object({
      enabled = optional(bool, false)
      mfa_delete = optional(bool, false)
    }), {})
    server_side_encryption_configuration = optional(object({
      rule = object({
        apply_server_side_encryption_by_default = object({
          sse_algorithm = string
          kms_master_key_id = optional(string, null)
        })
        bucket_key_enabled = optional(bool, null)
      })
    }), {})
    lifecycle_rule = optional(list(object({
      id = optional(string, null)
      prefix = optional(string, null)
      tags = optional(map(string), {})
      enabled = optional(bool, true)
      abort_incomplete_multipart_upload = optional(object({
        days_after_initiation = number
      }), {})
      expiration = optional(object({
        date = optional(string, null)
        days = optional(number, null)
        expired_object_delete_marker = optional(bool, null)
      }), {})
      noncurrent_version_expiration = optional(object({
        noncurrent_days = number
        newer_noncurrent_versions = optional(number, null)
      }), {})
      noncurrent_version_transition = optional(list(object({
        noncurrent_days = number
        storage_class = string
        newer_noncurrent_versions = optional(number, null)
      })), [])
      transition = optional(list(object({
        date = optional(string, null)
        days = optional(number, null)
        storage_class = string
      })), [])
      object_size_greater_than = optional(number, null)
      object_size_less_than = optional(number, null)
    })), [])
    cors_rule = optional(list(object({
      allowed_headers = optional(list(string), [])
      allowed_methods = list(string)
      allowed_origins = list(string)
      expose_headers = optional(list(string), [])
      max_age_seconds = optional(number, null)
    })), [])
    website = optional(object({
      index_document = optional(string, null)
      error_document = optional(string, null)
      redirect_all_requests_to = optional(string, null)
      routing_rules = optional(string, null)
    }), {})
    object_ownership = optional(object({
      object_ownership = string
      rule = optional(object({
        object_ownership = string
      }), {})
    }), {})
    block_public_acls = optional(bool, true)
    block_public_policy = optional(bool, true)
    ignore_public_acls = optional(bool, true)
    restrict_public_buckets = optional(bool, true)
    bucket_ownership_controls = optional(object({
      rule = object({
        object_ownership = string
      })
    }), {})
    intelligent_tiering = optional(list(object({
      id = string
      status = optional(string, "Enabled")
      tiering = list(object({
        access_tier = string
        days = number
      }))
    })), [])
    metric_configuration = optional(list(object({
      id = string
      filter = optional(object({
        prefix = optional(string, null)
        tags = optional(map(string), {})
      }), {})
    })), [])
    inventory = optional(list(object({
      name = string
      enabled = optional(bool, true)
      included_object_versions = optional(string, "Current")
      schedule = object({
        frequency = string
      })
      destination = object({
        bucket = object({
          format = string
          bucket_arn = string
          account_id = optional(string, null)
          prefix = optional(string, null)
          encryption = optional(object({
            sse_kms = optional(object({
              key_id = string
            }), {})
            sse_s3 = optional(object({}), {})
          }), {})
        })
      })
      optional_fields = optional(list(string), [])
    })), [])
    object_lock_configuration = optional(object({
      object_lock_enabled = optional(string, "Enabled")
      rule = optional(object({
        default_retention = object({
          mode = string
          days = optional(number, null)
          years = optional(number, null)
        })
      }), {})
    }), {})
    replication_configuration = optional(object({
      role = string
      rules = list(object({
        id = optional(string, null)
        status = optional(string, "Enabled")
        priority = optional(number, null)
        delete_marker_replication = optional(object({
          status = string
        }), {})
        destination = object({
          bucket = string
          storage_class = optional(string, null)
          replica_kms_key_id = optional(string, null)
          account_id = optional(string, null)
          access_control_translation = optional(object({
            owner = string
          }), {})
          replication_time = optional(object({
            status = string
            minutes = optional(number, null)
          }), {})
          metrics = optional(object({
            status = string
            minutes = optional(number, null)
          }), {})
        })
        source_selection_criteria = optional(object({
          sse_kms_encrypted_objects = optional(object({
            status = string
          }), {})
        }), {})
        filter = optional(object({
          prefix = optional(string, null)
          tags = optional(map(string), {})
        }), {})
      }))
    }), {})
    request_payer = optional(string, null)
    tags = optional(map(string), {})
  }))
  default = {}
}

# ==============================================================================
# Enhanced CloudFront Configuration Variables
# ==============================================================================

variable "cloudfront_distributions" {
  description = "Map of CloudFront distributions to create"
  type = map(object({
    enabled = optional(bool, true)
    is_ipv6_enabled = optional(bool, true)
    comment = optional(string, null)
    default_root_object = optional(string, null)
    price_class = optional(string, "PriceClass_All")
    retain_on_delete = optional(bool, false)
    wait_for_deployment = optional(bool, true)
    web_acl_id = optional(string, null)
    http_version = optional(string, "http2")
    aliases = optional(list(string), [])
    origins = list(object({
      domain_name = string
      origin_id = string
      origin_path = optional(string, null)
      custom_origin_config = optional(object({
        http_port = optional(number, 80)
        https_port = optional(number, 443)
        origin_protocol_policy = string
        origin_ssl_protocols = list(string)
        origin_read_timeout = optional(number, 60)
        origin_keepalive_timeout = optional(number, 5)
      }), {})
      s3_origin_config = optional(object({
        origin_access_identity = optional(string, null)
        origin_access_identity_path = optional(string, null)
      }), {})
      custom_header = optional(list(object({
        name = string
        value = string
      })), [])
      origin_shield = optional(object({
        enabled = bool
        origin_shield_region = string
      }), {})
    }))
    default_cache_behavior = object({
      target_origin_id = string
      viewer_protocol_policy = string
      allowed_methods = optional(list(string), ["GET", "HEAD"])
      cached_methods = optional(list(string), ["GET", "HEAD"])
      trusted_key_groups = optional(list(string), [])
      trusted_signers = optional(list(string), [])
      cache_policy_id = optional(string, null)
      origin_request_policy_id = optional(string, null)
      response_headers_policy_id = optional(string, null)
      realtime_log_config_arn = optional(string, null)
      min_ttl = optional(number, null)
      default_ttl = optional(number, null)
      max_ttl = optional(number, null)
      compress = optional(bool, null)
      field_level_encryption_id = optional(string, null)
      forwarded_values = optional(object({
        query_string = bool
        query_string_cache_keys = optional(list(string), [])
        headers = optional(list(string), [])
        cookies = object({
          forward = string
          whitelisted_names = optional(list(string), [])
        })
      }), {})
      lambda_function_association = optional(list(object({
        event_type = string
        lambda_arn = string
        include_body = optional(bool, null)
      })), [])
      function_association = optional(list(object({
        event_type = string
        function_arn = string
      })), [])
      smooth_streaming = optional(bool, null)
      default_ttl = optional(number, null)
      max_ttl = optional(number, null)
      min_ttl = optional(number, null)
    })
    ordered_cache_behavior = optional(list(object({
      path_pattern = string
      target_origin_id = string
      viewer_protocol_policy = string
      allowed_methods = optional(list(string), ["GET", "HEAD"])
      cached_methods = optional(list(string), ["GET", "HEAD"])
      trusted_key_groups = optional(list(string), [])
      trusted_signers = optional(list(string), [])
      cache_policy_id = optional(string, null)
      origin_request_policy_id = optional(string, null)
      response_headers_policy_id = optional(string, null)
      realtime_log_config_arn = optional(string, null)
      min_ttl = optional(number, null)
      default_ttl = optional(number, null)
      max_ttl = optional(number, null)
      compress = optional(bool, null)
      field_level_encryption_id = optional(string, null)
      forwarded_values = optional(object({
        query_string = bool
        query_string_cache_keys = optional(list(string), [])
        headers = optional(list(string), [])
        cookies = object({
          forward = string
          whitelisted_names = optional(list(string), [])
        })
      }), {})
      lambda_function_association = optional(list(object({
        event_type = string
        lambda_arn = string
        include_body = optional(bool, null)
      })), [])
      function_association = optional(list(object({
        event_type = string
        function_arn = string
      })), [])
      smooth_streaming = optional(bool, null)
    })), [])
    custom_error_response = optional(list(object({
      error_code = number
      response_code = optional(string, null)
      response_page_path = optional(string, null)
      error_caching_min_ttl = optional(number, null)
    })), [])
    logging_config = optional(object({
      include_cookies = optional(bool, null)
      bucket = string
      prefix = optional(string, null)
    }), {})
    viewer_certificate = object({
      acm_certificate_arn = optional(string, null)
      cloudfront_default_certificate = optional(bool, null)
      iam_certificate_id = optional(string, null)
      minimum_protocol_version = optional(string, "TLSv1")
      ssl_support_method = optional(string, null)
    })
    restrictions = optional(object({
      geo_restriction = object({
        restriction_type = string
        locations = optional(list(string), [])
      })
    }), {})
    tags = optional(map(string), {})
  }))
  default = {}
}

variable "cloudfront_functions" {
  description = "Map of CloudFront functions to create"
  type = map(object({
    name = string
    runtime = string
    comment = optional(string, null)
    publish = optional(bool, true)
    code = string
  }))
  default = {}
}

variable "cloudfront_cache_policies" {
  description = "Map of CloudFront cache policies to create"
  type = map(object({
    name = string
    comment = optional(string, null)
    default_ttl = optional(number, null)
    max_ttl = optional(number, null)
    min_ttl = optional(number, null)
    parameters_in_cache_key_and_forwarded_to_origin = object({
      cookies_config = object({
        cookie_behavior = string
        cookies = optional(object({
          items = list(string)
        }), {})
      })
      headers_config = object({
        header_behavior = string
        headers = optional(object({
          items = list(string)
        }), {})
      })
      query_strings_config = object({
        query_string_behavior = string
        query_strings = optional(object({
          items = list(string)
        }), {})
      })
      enable_accept_encoding_brotli = optional(bool, null)
      enable_accept_encoding_gzip = optional(bool, null)
    })
  }))
  default = {}
}

variable "cloudfront_origin_request_policies" {
  description = "Map of CloudFront origin request policies to create"
  type = map(object({
    name = string
    comment = optional(string, null)
    headers_config = object({
      header_behavior = string
      headers = optional(object({
        items = list(string)
      }), {})
    })
    cookies_config = object({
      cookie_behavior = string
      cookies = optional(object({
        items = list(string)
      }), {})
    })
    query_strings_config = object({
      query_string_behavior = string
      query_strings = optional(object({
        items = list(string)
      }), {})
    })
  }))
  default = {}
}

variable "cloudfront_response_headers_policies" {
  description = "Map of CloudFront response headers policies to create"
  type = map(object({
    name = string
    comment = optional(string, null)
         cors_config = optional(object({
       access_control_allow_credentials = bool
       access_control_allow_headers = object({
         items = list(string)
       })
       access_control_allow_methods = object({
         items = list(string)
       })
       access_control_allow_origins = object({
         items = list(string)
       })
      access_control_expose_headers = optional(object({
        items = list(string)
      }), {})
      access_control_max_age_sec = optional(number, null)
      origin_override = bool
    }), {})
    custom_headers_config = optional(object({
      items = list(object({
        header = string
        override = bool
        value = string
      }))
    }), {})
    security_headers_config = optional(object({
      content_security_policy = optional(object({
        content_security_policy = string
        override = bool
      }), {})
      content_type_options = optional(object({
        override = bool
      }), {})
      frame_options = optional(object({
        frame_option = string
        override = bool
      }), {})
      referrer_policy = optional(object({
        referrer_policy = string
        override = bool
      }), {})
      strict_transport_security = optional(object({
        access_control_max_age_sec = number
        include_subdomains = optional(bool, null)
        override = bool
        preload = optional(bool, null)
      }), {})
      x_content_type_options = optional(object({
        override = bool
      }), {})
      x_frame_options = optional(object({
        frame_option = string
        override = bool
      }), {})
      x_xss_protection = optional(object({
        mode_block = optional(bool, null)
        override = bool
        protection = bool
        report_uri = optional(string, null)
      }), {})
    }), {})
  }))
  default = {}
}

# ==============================================================================
# Enhanced Route53 Configuration Variables
# ==============================================================================

variable "route53_zones" {
  description = "Map of Route53 hosted zones to create"
  type = map(object({
    name = string
    comment = optional(string, null)
    force_destroy = optional(bool, false)
    private_zone = optional(bool, false)
    vpc = optional(list(object({
      vpc_id = string
      vpc_region = optional(string, null)
    })), [])
    tags = optional(map(string), {})
  }))
  default = {}
}

variable "route53_records" {
  description = "Map of Route53 records to create"
  type = map(object({
    zone_id = string
    name = string
    type = string
    ttl = optional(number, null)
    records = optional(list(string), [])
    set_identifier = optional(string, null)
    health_check_id = optional(string, null)
    alias = optional(object({
      name = string
      zone_id = string
      evaluate_target_health = bool
    }), {})
    weighted_routing_policy = optional(object({
      weight = number
    }), {})
    failover_routing_policy = optional(object({
      type = string
    }), {})
    latency_routing_policy = optional(object({
      region = string
    }), {})
    geolocation_routing_policy = optional(object({
      continent = optional(string, null)
      country = optional(string, null)
      subdivision = optional(string, null)
    }), {})
    multivalue_answer_routing_policy = optional(bool, null)
    allow_overwrite = optional(bool, false)
    tags = optional(map(string), {})
  }))
  default = {}
}

# ==============================================================================
# Enhanced ACM Configuration Variables
# ==============================================================================

variable "acm_certificates" {
  description = "Map of ACM certificates to create"
  type = map(object({
    domain_name = string
    subject_alternative_names = optional(list(string), [])
    validation_method = optional(string, "DNS")
    certificate_authority_arn = optional(string, null)
    certificate_body = optional(string, null)
    certificate_chain = optional(string, null)
    private_key = optional(string, null)
    options = optional(object({
      certificate_transparency_logging_preference = optional(string, "ENABLED")
    }), {})
    tags = optional(map(string), {})
  }))
  default = {}
}

variable "acm_certificate_validation" {
  description = "Map of ACM certificate validations to create"
  type = map(object({
    certificate_arn = string
    validation_record_fqdns = optional(list(string), [])
    timeouts = optional(object({
      create = optional(string, null)
    }), {})
  }))
  default = {}
}

# ==============================================================================
# Enhanced WAF Configuration Variables
# ==============================================================================

variable "waf_web_acls" {
  description = "Map of WAF Web ACLs to create"
  type = map(object({
    name = string
    description = optional(string, null)
    scope = string
    default_action = object({
      allow = optional(object({}), {})
      block = optional(object({}), {})
    })
    rules = optional(list(object({
      name = string
      priority = number
      override_action = optional(object({
        none = optional(object({}), {})
      }), {})
      action = optional(object({
        allow = optional(object({}), {})
        block = optional(object({}), {})
        count = optional(object({}), {})
      }), {})
      statement = object({
        managed_rule_group_statement = optional(object({
          name = string
          vendor_name = string
          excluded_rule = optional(list(object({
            name = string
          })), [])
        }), {})
        rate_based_statement = optional(object({
          limit = number
          aggregate_key_type = optional(string, null)
          scope_down_statement = optional(object({}), {})
        }), {})
        geo_match_statement = optional(object({
          country_codes = list(string)
          forwarded_ip_config = optional(object({
            header_name = string
            fallback_behavior = string
          }), {})
        }), {})
        ip_set_reference_statement = optional(object({
          arn = string
          ip_set_forwarded_ip_config = optional(object({
            header_name = string
            fallback_behavior = string
            position = string
          }), {})
        }), {})
        regex_pattern_set_reference_statement = optional(object({
          arn = string
          field_to_match = object({
            all_query_parameters = optional(object({}), {})
            body = optional(object({}), {})
            method = optional(object({}), {})
            query_string = optional(object({}), {})
            single_header = optional(object({
              name = string
            }), {})
            single_query_parameter = optional(object({
              name = string
            }), {})
            uri_path = optional(object({}), {})
          })
          text_transformation = object({
            priority = number
            type = string
          })
        }), {})
        rule_group_reference_statement = optional(object({
          arn = string
          excluded_rule = optional(list(object({
            name = string
          })), [])
        }), {})
        and_statement = optional(object({
          statement = list(object({}))
        }), {})
        or_statement = optional(object({
          statement = list(object({}))
        }), {})
        not_statement = optional(object({
          statement = object({})
        }), {})
      })
      visibility_config = object({
        cloudwatch_metrics_enabled = bool
        metric_name = string
        sampled_requests_enabled = bool
      })
    })), [])
    visibility_config = object({
      cloudwatch_metrics_enabled = bool
      metric_name = string
      sampled_requests_enabled = bool
    })
    tags = optional(map(string), {})
  }))
  default = {}
}

variable "waf_ip_sets" {
  description = "Map of WAF IP sets to create"
  type = map(object({
    name = string
    description = optional(string, null)
    scope = string
    ip_address_version = string
    addresses = optional(list(string), [])
    tags = optional(map(string), {})
  }))
  default = {}
}

variable "waf_regex_pattern_sets" {
  description = "Map of WAF regex pattern sets to create"
  type = map(object({
    name = string
    description = optional(string, null)
    scope = string
    regular_expression = list(object({
      regex_string = string
    }))
    tags = optional(map(string), {})
  }))
  default = {}
}

# ==============================================================================
# Enhanced Lambda@Edge Configuration Variables
# ==============================================================================

variable "lambda_functions" {
  description = "Map of Lambda functions to create"
  type = map(object({
    filename = optional(string, null)
    function_name = string
    role = string
    handler = string
    runtime = string
    description = optional(string, null)
    reserved_concurrent_executions = optional(number, null)
    publish = optional(bool, false)
    timeout = optional(number, 3)
    memory_size = optional(number, 128)
    environment = optional(object({
      variables = optional(map(string), {})
    }), {})
    tags = optional(map(string), {})
  }))
  default = {}
}

# ==============================================================================
# Enhanced S3 Object Configuration Variables
# ==============================================================================

variable "s3_bucket_objects" {
  description = "Map of S3 bucket objects to create"
  type = map(object({
    bucket = string
    key = string
    source = optional(string, null)
    content = optional(string, null)
    content_base64 = optional(string, null)
    content_type = optional(string, null)
    content_disposition = optional(string, null)
    content_encoding = optional(string, null)
    content_language = optional(string, null)
    website_redirect = optional(string, null)
    etag = optional(string, null)
    force_destroy = optional(bool, false)
    metadata = optional(map(string), {})
    object_lock_legal_hold_status = optional(string, null)
    object_lock_mode = optional(string, null)
    object_lock_retain_until_date = optional(string, null)
    server_side_encryption = optional(string, null)
    source_hash = optional(string, null)
    storage_class = optional(string, null)
    tags = optional(map(string), {})
    kms_key_id = optional(string, null)
  }))
  default = {}
} 
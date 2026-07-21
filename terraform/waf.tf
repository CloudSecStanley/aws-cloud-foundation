# 1. CloudWatch Log Group (Must start with "aws-waf-logs-")
resource "aws_cloudwatch_log_group" "waf_log_group" {
  name              = "aws-waf-logs-alb"
  retention_in_days = 365
  kms_key_id        = aws_kms_key.app_key.arn

  tags = {
    Environment = "sandbox"
    Owner       = "security-team"
  }
}

# 2. WAFv2 Web ACL
resource "aws_wafv2_web_acl" "alb_waf" {
  name        = "sandbox-alb-waf"
  description = "Temporary WAF for ALB security testing"
  scope       = "REGIONAL"

  tags = {
    Environment = "sandbox"
    Owner       = "security-team"
  }

  default_action {
    allow {}
  }

  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name                = "sandboxAlbWafMetric"
    sampled_requests_enabled   = true
  }

  # Core Rule Set
  rule {
    name     = "AWSManagedRulesCommonRuleSet"
    priority = 1

    override_action {
      none {}
    }

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesCommonRuleSet"
        vendor_name = "AWS"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "AWSManagedRulesCommonRuleSetMetric"
      sampled_requests_enabled   = true
    }
  }

  # Known Bad Inputs (Log4j / RCE mitigation)
  rule {
    name     = "AWSManagedRulesKnownBadInputsRuleSet"
    priority = 2

    override_action {
      none {}
    }

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesKnownBadInputsRuleSet"
        vendor_name = "AWS"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "AWSManagedRulesKnownBadInputsRuleSetMetric"
      sampled_requests_enabled   = true
    }
  }

  # Anonymous IP List
  rule {
    name     = "AWSManagedRulesAnonymousIpList"
    priority = 3

    override_action {
      none {}
    }

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesAnonymousIpList"
        vendor_name = "AWS"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "AWSManagedRulesAnonymousIpListMetric"
      sampled_requests_enabled   = true
    }
  }
}

# 3. WAF Logging Link
resource "aws_wafv2_web_acl_logging_configuration" "alb_waf_logging" {
  log_destination_configs = [aws_cloudwatch_log_group.waf_log_group.arn]
  resource_arn            = aws_wafv2_web_acl.alb_waf.arn
}

# 4. ALB Association
resource "aws_wafv2_web_acl_association" "alb_waf_assoc" {
  resource_arn = aws_lb.external_alb.arn
  web_acl_arn  = aws_wafv2_web_acl.alb_waf.arn
}
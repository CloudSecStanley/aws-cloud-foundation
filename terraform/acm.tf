# Request an ACM certificate

resource "aws_acm_certificate" "alb_cert" {
    domain_name = var.domain_name
    validation_method = "DNS"

    tags = {
      Name = "sandbox-alb-cert"
    }

    lifecycle {
      create_before_destroy = true
    }
}
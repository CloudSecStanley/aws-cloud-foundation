# Security Group for ALB
resource "aws_security_group" "alb_sg" {
  name        = "sandbox-alb-sg"
  description = "Security group for external application load balancer"
  vpc_id      = aws_vpc.sandbox_vpc.id

  ingress {
    description = "Allow inbound HTTPS traffic from internet"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "sandbox-alb-sg"
  }
}

resource "aws_security_group_rule" "alb_to_app_egress" {
  type                     = "egress"
  description              = "Allow ALB to forward traffic to application security group"
  from_port                = 443
  to_port                  = 443
  protocol                 = "tcp"
  security_group_id        = aws_security_group.alb_sg.id
  source_security_group_id = aws_security_group.app_sg.id
}

resource "aws_security_group_rule" "allow_alb_to_app" {
  type                     = "ingress"
  description              = "Allow inbound traffic from ALB security group"
  from_port                = 443
  to_port                  = 443
  protocol                 = "tcp"
  security_group_id        = aws_security_group.app_sg.id
  source_security_group_id = aws_security_group.alb_sg.id
}

# Application Load Balancer
resource "aws_lb" "external_alb" {
  name               = "sandbox-external-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_sg.id]
  subnets            = [aws_subnet.public_1.id, aws_subnet.public_2.id]

  drop_invalid_header_fields = true
  enable_deletion_protection = true 

  access_logs {
    bucket  = aws_s3_bucket.sandbox_storage.id
    prefix  = "alb-access-logs"
    enabled = true
  }

  tags = {
    Name = "sandbox-external-alb"
  }
}

# HTTPS Target Group 
resource "aws_lb_target_group" "app_target_group" {
  name        = "sandbox-app-tg"
  port        = 443
  protocol    = "HTTPS" 
  vpc_id      = aws_vpc.sandbox_vpc.id
  target_type = "instance"

  health_check {
    enabled             = true
    path                = "/health"
    protocol            = "HTTPS" 
    port                = "443"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 3
    unhealthy_threshold = 3
    matcher             = "200"
  }
}

# HTTPS Listener
resource "aws_lb_listener" "https_listener" {
  load_balancer_arn = aws_lb.external_alb.arn
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-TLS13-1-2-2021-06"

  # Dynamically uses the variable override if set; otherwise uses the managed ACM certificate
  certificate_arn = coalesce(var.alb_certificate_arn, aws_acm_certificate.alb_cert.arn)

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.app_target_group.arn
  }
}

# HTTP to HTTPS Redirect Listener
resource "aws_lb_listener" "http_redirect" {
  load_balancer_arn = aws_lb.external_alb.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type = "redirect"

    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }
}
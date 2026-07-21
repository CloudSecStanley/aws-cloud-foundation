# look up the latest AMI for Amazon Linux 3 in the specified region

data "aws_ami" "latest_amazon_linux_3" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = [var.ami_name_filter]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# IAM ROLE & INSTANNCE PROFILE FOR EC2 (SSM ACCESS)

# Allows secure console/shell access via AWS Systems Manager without SSH keys
resource "aws_iam_role" "app_role" {
  name = "sandbox-app-instance-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Environment = "sandbox"
  }
}

# Secure security group for the EC2 instance

resource "aws_security_group" "app_sg" {
  name        = "sandbox-app-sg"
  description = "Security group for sandbox compute instance"
  vpc_id      = aws_vpc.sandbox_vpc.id

  # Inbound traffic blocked completely by default\

  ingress {
    description = "Only allow inbound traffic from the ALB"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    security_groups = [aws_security_group.alb_sg.id]
  }

  # Egress: restrict traffic to only your CIDR block

    egress {
      description = "Allow all outbound traffic only to the VPC CIDR"
        from_port   = 0
        to_port     = 0
        protocol    = "-1"
        cidr_blocks = [var.vpc_cidr]
    }

    tags = {
        Name = "sandbox-app-sg"
    }
}

# IAM Instance profile to attach the existing minimal runtime role to the EC2 instance

resource "aws_iam_instance_profile" "app_profile" {
  name = "sandbox-app-instance-profile"
  role = aws_iam_role.runtime_exec.name
}

# THe Isolated EC2 instance

resource "aws_instance" "app_server" {
  ami                    = data.aws_ami.latest_amazon_linux_3.id
  instance_type          = var.instance_type
  subnet_id              = aws_subnet.private_compute_subnet.id
  vpc_security_group_ids = [aws_security_group.app_sg.id]
  iam_instance_profile   = aws_iam_instance_profile.app_profile.name

  root_block_device {
    volume_size           = var.root_volume_size
    volume_type           = var.root_volume_type
    delete_on_termination = true
    encrypted             = true
    kms_key_id            = aws_kms_key.app_key.arn
  }

  #Security Enhancements

  ebs_optimized = true
  monitoring    = true

  #meta-data options to prevent SSRF attacks and limit access to the instance metadata service

    metadata_options {
        http_tokens               = "required"
        http_endpoint             = "enabled"
        http_put_response_hop_limit = 1
    }

  # User Data Script: Launches a simple HTTP service returning JSON for /health
  user_data = <<-EOF
              #!/bin/bash
              yum update -y
              yum install -y python3
              cat << 'PYEOF' > /home/ec2-user/app.py
              from http.server import HTTPServer, BaseHTTPRequestHandler
              import json

              class SimpleHandler(BaseHTTPRequestHandler):
                  def do_GET(self):
                      if self.path == '/health':
                          self.send_response(200)
                          self.send_header('Content-type', 'application/json')
                          self.end_headers()
                          response = {"status": "healthy", "service": "app-server"}
                          self.wfile.write(json.dumps(response).encode())
                      else:
                          self.send_response(404)
                          self.end_headers()

              if __name__ == '__main__':
                  server = HTTPServer(('0.0.0.0', 443), SimpleHandler)
                  server.serve_forever()
              PYEOF
              python3 /home/ec2-user/app.py &
              EOF

  tags = {
    Name        = "sandbox-app-server"
    Environment = "sandbox"
  }
}

# Attach Instance to ALB Target Group
resource "aws_lb_target_group_attachment" "app_attachment" {
  target_group_arn = aws_lb_target_group.app_target_group.arn
  target_id        = aws_instance.app_server.id
  port             = 443
}

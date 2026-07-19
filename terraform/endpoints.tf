# security group for interface endpoints

resource "aws_security_group" "vpc_endpoints_sg" {
  name        = "sandbox-endpoints-sg"
  description = "Security group for interface endpoints"
  vpc_id      = aws_vpc.sandbox_vpc.id

  # Allow HTTPS traffic only from inside the VPC CIDR

  ingress {
    description = "HTTPS from within the VPC"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [aws_vpc.sandbox_vpc.cidr_block]
  }

  # Egress: Allow endpoints to respond back to the VPC

  egress {
    description = "Allow outbound inside the VPC"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [aws_vpc.sandbox_vpc.cidr_block]
    }

    tags = {
        Name = "sandbox-endpoints-sg"
    }
}


# S3 Gateway Endpoint

resource "aws_vpc_endpoint" "s3" {
  vpc_id       = aws_vpc.sandbox_vpc.id
  service_name = "com.amazonaws.${var.aws_region}.s3"
  vpc_endpoint_type = "Gateway"
  # Automatically associates with your private route table
  route_table_ids   = [aws_route_table.private_rt.id]

  tags = {
    Name = "sandbox-s3-endpoint"
  }
}

# SSM Interface Endpoint

resource "aws_vpc_endpoint" "ssm" {
  vpc_id            = aws_vpc.sandbox_vpc.id
  service_name      = "com.amazonaws.${var.aws_region}.ssm"
  vpc_endpoint_type = "Interface"
  security_group_ids = [aws_security_group.vpc_endpoints_sg.id]
  subnet_ids        = [aws_subnet.private_compute_subnet.id]

  tags = {
    Name = "sandbox-ssm-endpoint"
  }
}
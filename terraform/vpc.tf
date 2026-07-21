# Custom VPC

resource "aws_vpc" "sandbox_vpc" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "Sandbox VPC"
  }
}

# Private Subnet for compute resources

resource "aws_subnet" "private_compute_subnet" {
  vpc_id                  = aws_vpc.sandbox_vpc.id
  cidr_block              = var.private_subnet_cidr
  availability_zone       = "${var.aws_region}a"

  tags = {
    Name = "sandbox-private-subnet"
  }
}

# Public Subnet for compute resources

resource "aws_subnet" "public_1" {
  vpc_id = aws_vpc.sandbox_vpc.id
  cidr_block = var.public_cidr_1
  availability_zone = "${var.aws_region}a"

  tags = {
    Name = "sandbox-public-subnet-1"
  }
}

resource "aws_subnet" "public_2" {
  vpc_id =  aws_vpc.sandbox_vpc.id
  cidr_block = var.public_cidr_2
  availability_zone = "${var.aws_region}b"

  tags = {
    Name = "sandbox-public-subnet-2"
  }
}

resource "aws_subnet" "private_db_1" {
  vpc_id =  aws_vpc.sandbox_vpc.id
  cidr_block = var.private_dbsubnet_cidr_1
  availability_zone = "${var.aws_region}b"

  tags = {
    Name = "sandbox-private-dbsubnet-1"
  }
}

resource "aws_subnet" "private_db_2" {
  vpc_id =  aws_vpc.sandbox_vpc.id
  cidr_block = var.private_dbsubnet_cidr_2
  availability_zone = "${var.aws_region}b"

  tags = {
    Name = "sandbox-private-dbsubnet-2"
  }
}

# Isolated Route Table for the private subnet

resource "aws_route_table" "private_rt" {
  vpc_id = aws_vpc.sandbox_vpc.id

  tags = {
    Name = "sandbox-private-rt"
  }
}

# Explicitly associate the private subnet with the isolated route table

resource "aws_route_table_association" "private_rt_assoc" {
  subnet_id      = aws_subnet.private_compute_subnet.id
  route_table_id = aws_route_table.private_rt.id
}

# Manage the default security group to deny all traffic

resource "aws_default_security_group" "default" {
  vpc_id = aws_vpc.sandbox_vpc.id
}

# Enable VPC Flow Logs for monitoring and troubleshooting

resource "aws_flow_log" "vpc_flow_log" {
  log_destination      = aws_cloudwatch_log_group.vpc_flow_logs.arn
  iam_role_arn        = aws_iam_role.vpc_flow_logs_role.arn
  log_destination_type = "cloud-watch-logs"
  traffic_type         = "ALL"
  vpc_id               = aws_vpc.sandbox_vpc.id
}

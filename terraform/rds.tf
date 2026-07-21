# 1. DB SUBNET GROUP

# database across private DB subnets
resource "aws_db_subnet_group" "db_subnet_group" {
  name        = "sandbox-db-subnet-group"
  subnet_ids  = [aws_subnet.private_db_1.id, aws_subnet.private_db_2.id]
  description = "Subnet group for private RDS database instances"

  tags = {
    Name        = "sandbox-db-subnet-group"
    Environment = "sandbox"
  }
}

# 2. DATABASE SECURITY GROUP

# Strictly allows inbound PostgreSQL traffic ONLY from the App Server Security Group
resource "aws_security_group" "db_sg" {
  name        = "sandbox-db-sg"
  description = "Security group for private database instances"
  vpc_id      = aws_vpc.sandbox_vpc.id

  tags = {
    Name        = "sandbox-db-sg"
    Environment = "sandbox"
  }
}

resource "aws_security_group_rule" "allow_app_to_db" {
  type                     = "ingress"
  description              = "Allow inbound PostgreSQL from app server security group"
  from_port                = 5432
  to_port                  = 5432
  protocol                 = "tcp"
  security_group_id        = aws_security_group.db_sg.id
  source_security_group_id = aws_security_group.app_sg.id
}

# 3. PARAMETER GROUP & IAM ROLE

# parameter group for Postgres settings
resource "aws_db_parameter_group" "postgres_pg" {
  name   = "sandbox-postgres-pg"
  family = "postgres15"

  parameter {
    name  = "log_statement"
    value = "all"
  }

  # ENCRYPTION IN TRANSIT
  parameter {
    name  = "rds.force_ssl"
    value = "1"
  }

  parameter {
    name  = "log_min_duration_statement"
    value = "0"
  }
}

# IAM role for RDS to allow access to CloudWatch Logs
resource "aws_iam_role" "rds_enhanced_monitoring" {
  name = "rds-enhanced-monitoring-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = { Service = "monitoring.rds.amazonaws.com" }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "rds_enhanced_monitoring" {
  role       = aws_iam_role.rds_enhanced_monitoring.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonRDSEnhancedMonitoringRole"
}

# 4. SECURE RDS POSTGRESQL INSTANCE

resource "aws_db_instance" "postgres_db" {
    # --- CHECKOV SKIPS FOR DEV / SANDBOX SCALE ---
    #checkov:skip=CKV_AWS_293:Disabled deletion protection for dev/sandbox cleanup
    #checkov:skip=CKV_AWS_157:Disabled Multi-AZ to save costs in sandbox
    #checkov:skip=CKV_AWS_118:Disabled backups to save costs in sandbox
    #checkov:skip=CKV2_AWS_60:Disabled snapshot tag copying since final snapshots are skipped in sandbox
  identifier                  = "sandbox-db"
  allocated_storage           = 20
  max_allocated_storage       = 100
  storage_type                = "gp3"
  engine                      = "postgres"
  engine_version              = "15"
  instance_class              = "db.t4g.micro"
  db_name                     = "sandboxapp"
  username                    = "dbadmin"
  manage_master_user_password = true # Managed by AWS Secrets Manager automatically

  db_subnet_group_name   = aws_db_subnet_group.db_subnet_group.name
  vpc_security_group_ids = [aws_security_group.db_sg.id]
  parameter_group_name = aws_db_parameter_group.postgres_pg.name

  # Storage Encryption & KMS
  storage_encrypted = true
  kms_key_id        = aws_kms_key.app_key.arn

  # High Availability & Networking
  publicly_accessible = false
  multi_az            = false # Set to true for production HA

  # Maintenance & Deletion Safety
  auto_minor_version_upgrade  = true
  allow_major_version_upgrade = false
  deletion_protection         = false
  skip_final_snapshot         = true
  
  # Backup & Logging
  iam_database_authentication_enabled = true
  backup_retention_period = 7
  enabled_cloudwatch_logs_exports = ["postgresql", "upgrade"]

  # performance insights and monitoring
  performance_insights_enabled = true
  performance_insights_kms_key_id = aws_kms_key.app_key.arn
  monitoring_interval = 60
  monitoring_role_arn = aws_iam_role.rds_enhanced_monitoring.arn

  tags = {
    Name        = "sandbox-postgres-db"
    Environment = "sandbox"
  }
}
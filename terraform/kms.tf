# Customer Managed Key (CMK)
# Creates a symmetric cryptographic key to encrypt our database, log buckets, and storage at rest.
resource "aws_kms_key" "app_key" {
  description             = "Customer Managed Key for encrypting sensitive data"
  deletion_window_in_days = 30
  enable_key_rotation     = true

  tags = {
    Name        = "cmk"
    Environment = var.environment
  }
# Custom key policy to restrict administrative and usage rights
    policy = jsonencode({
        Version = "2012-10-17"
        Statement = [
        # Standard delegation: Give full management capabilities to the root account
        {
            Sid    = "Enable IAM User Permissions"
            Effect = "Allow"
            Principal = {
            AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
            }
            Action   = "kms:*"
            Resource = "*"
        },

        # Restrict use to authorization contexts

            {
                Sid    = "Allow use of the key"
                Effect = "Allow"
                Principal = {
                    AWS = [
                        "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root",
                    ]
                }
                Action   = [   
                    "kms:Encrypt",
                    "kms:Decrypt",
                    "kms:ReEncrypt*",
                    "kms:GenerateDataKey*",
                    "kms:DescribeKey"
                    ]
                    Resource = "*"
                }
            ]
        })  
}

# KMS Alias
resource "aws_kms_alias" "app_key_alias" {
  name          = "alias/${var.project_name}-key"
  target_key_id = aws_kms_key.app_key.id
}

# Data source to get the current AWS account ID 

data "aws_caller_identity" "current" {}     




# Random suffix to ensure global uniqueness of the bucket name

resource "random_string" "s3_bucket_suffix" {
  length  = 4
  special = false
  upper = false
}

resource "aws_s3_bucket" "sandbox_storage" {
  bucket = "aws-cloud-foundation-sandbox-${random_string.s3_bucket_suffix.result}"
  force_destroy = true # for easy cleanup of the sandbox environment

  # checkov:skip=CKV_AWS_18:Sandbox bucket does not require a dedicated target access logging bucket.
  # checkov:skip=CKV_AWS_144:Cross-region replication is omitted to limit cost overhead in sandbox boundaries.
}

# Enforce default server-side encryption using deployed CMK

resource "aws_s3_bucket_server_side_encryption_configuration" "sandbox_sse" {
  bucket = aws_s3_bucket.sandbox_storage.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = "aws:kms"
      kms_master_key_id = aws_kms_key.app_key.arn
    }

    bucket_key_enabled = true
  }
}

# Anti-exfiltration guardrails: Block public access to the S3 bucket

resource "aws_s3_bucket_public_access_block" "sandbox_storage_block" {
  bucket = aws_s3_bucket.sandbox_storage.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Bucket policy: Enforce secure transport (TLS 1.2+), deny unencrypted HTTP requests

resource "aws_s3_bucket_policy" "sandbox_policy" {
  bucket = aws_s3_bucket.sandbox_storage.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "EnforceTLSRequestsOnly"
        Effect = "Deny"
        Principal = "*"
        Action   = "s3:*"
        Resource = [
          "${aws_s3_bucket.sandbox_storage.arn}/*",
          aws_s3_bucket.sandbox_storage.arn
        ]
        Condition = {
          Bool = {
            "aws:SecureTransport" = false
          }
        }
      }
    ]
  })
}

# Fixes CKV_AWS_21: Enable Object Versioning for data recovery

resource "aws_s3_bucket_versioning" "sandbox_versioning" {
  bucket = aws_s3_bucket.sandbox_storage.id

  versioning_configuration {
    status = "Enabled"
  }
}

# Fixes CKV2_AWS_61: Enforce a Lifecycle Configuration to clean up stale versions

resource "aws_s3_bucket_lifecycle_configuration" "sandbox_lifecycle" {
  bucket = aws_s3_bucket.sandbox_storage.id

  rule {
    id     = "CleanOldVersions"
    status = "Enabled"

    noncurrent_version_expiration {
      noncurrent_days = 30
    }

    # Fixes CKV_AWS_300: Automatically purge failed/incomplete multipart uploads after 7 days
    abort_incomplete_multipart_upload {
      days_after_initiation = 7
    }
  }
}

# Fixes CKV2_AWS_62: Stub Notification configurations (Required for EventBridge/Security pipelines)

resource "aws_s3_bucket_notification" "sandbox_events" {
  bucket = aws_s3_bucket.sandbox_storage.id
  eventbridge = true
}
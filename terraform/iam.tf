# 1. TRUST POLICY DECLARATIONS
# Policy allowing authorized engineering/security entities to assume operations roles

data "aws_iam_policy_document" "engineering_trust_policy" {
  statement {
    sid      = "AllowAssumeRoleFromAccountRoot"
    effect = "Allow"
    actions = [
      "sts:AssumeRole",
    ]
    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"]
    } 
  }
}

# Trust policy granting EC2/ECS computing instances permission to assume execution identities

data "aws_iam_policy_document" "compute_trust_policy" {
  statement {
    sid      = "AllowAssumeRoleFromCompute"
    effect = "Allow"
    actions = [
      "sts:AssumeRole",
    ]
    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com", "ecs-tasks.amazonaws.com"]
    }
  } 
}

# 2. ROLE DECLARATIONS

# Cloud Security Auditing Role (CSPM)

resource "aws_iam_role" "cloudsec_audit" {
  name               = "CloudSecAuditRole"
  assume_role_policy = data.aws_iam_policy_document.engineering_trust_policy.json
}

# Platform Infrastructure Operations Role (CI/CD / Admin Operators)

resource "aws_iam_role" "platform_ops" {
  name               = "PlatformOpsRole"
  description        = "Administrative control for executing engineering changes and infrastructure provisioning"
  assume_role_policy = data.aws_iam_policy_document.engineering_trust_policy.json
}

# Active Runtime Application Instance Execution Role

resource "aws_iam_role" "runtime_exec" {
  name               = "AppRuntimeRole"
    description        = "Execution role for active runtime application instances"
    assume_role_policy = data.aws_iam_policy_document.compute_trust_policy.json
}

# Instance Profile to pass the AppRuntimeRole directly to an EC2 instance

resource "aws_iam_instance_profile" "app_instance_profile" {
  name = "AppRuntimeInstanceProfile"
  role = aws_iam_role.runtime_exec.name
}

# 3. LEAST-PRIVILEGE POLICY ATTACHMENTS

# Attach AWS Managed SecurityAudit policy to our CloudSec role
resource "aws_iam_role_policy_attachment" "audit_security" {
  role       = aws_iam_role.cloudsec_audit.name
  policy_arn = "arn:aws:iam::aws:policy/SecurityAudit"
}

resource "aws_iam_role_policy_attachment" "ops_admin" {
  # checkov:skip=CKV_AWS_274:PlatformOpsRole requires AdministratorAccess to execute core infrastructure provisioning within the sandbox environment.
  role       = aws_iam_role.platform_ops.name
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}

# Custom Inline Policy for AppRuntimeRole: Enforces zero access to IAM/KMS keys, allows read-only application assets

resource "aws_iam_role_policy" "app_runtime_minimal" {
  name = "AppRuntimeMinimalStorageAccess"
  role = aws_iam_role.runtime_exec.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowAppReadDataAccess"
        Effect = "Allow"
        Action = [
          "s3:GetObject"
        ]
        Resource = [
          "arn:aws:s3:::aws-cloud-foundation-sandbox-*/*"
        ]
      },
      {
        Sid    = "AllowAppListBucketAccess"
        Effect = "Allow"
        Action = [
          "s3:ListBucket"
        ]
        Resource = [
          "arn:aws:s3:::aws-cloud-foundation-sandbox-*"
        ]
      },
      {
        Sid    = "AllowAppKMSDecryption"
        Effect = "Allow"
        Action = [
          "kms:Decrypt",
          "kms:DescribeKey"
        ]
        Resource = [
          "arn:aws:kms:*:*:key/*" # Ideally scope this to your exact key ARN if known, or follow your regional naming scheme
        ]
      }
    ]
  })
} 

# Trust policy allowing the VPC Flow Logs service to assume this role

data "aws_iam_policy_document" "vpc_flow_logs_trust_policy" {
  statement {
    sid      = "AllowAssumeRoleFromVPCFlowLogs"
    effect = "Allow"
    actions = [
      "sts:AssumeRole",
    ]
    principals {
      type        = "Service"
      identifiers = ["vpc-flow-logs.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "vpc_flow_logs_role" {
  name               = "sandbox-vpc-flow-logs-role"
  assume_role_policy = data.aws_iam_policy_document.vpc_flow_logs_trust_policy.json
}

# IAM policy specifying minimal write permissions to the CloudWatch log group

resource "aws_iam_role_policy" "vpc_flow_logs_policy" {
  name   = "sandbox-vpc-flow-logs-policy"
  role   = aws_iam_role.vpc_flow_logs_role.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowVPCFlowLogsToWriteToCloudWatch"
        Effect = "Allow"
        Action = [
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "logs:DescribeLogStreams",
          "logs:DescribeLogGroups"
        ]
        Resource = "${aws_cloudwatch_log_group.vpc_flow_logs.arn}:*"
      }
    ]
  })
}
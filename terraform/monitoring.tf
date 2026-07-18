# Cloudwatch logging group for VPC Flow Logs

resource "aws_cloudwatch_log_group" "vpc_flow_logs" {
  name              = "/aws/vpc/sandbox-flow-logs"
  retention_in_days = 365
  kms_key_id        = aws_kms_key.app_key.arn
}
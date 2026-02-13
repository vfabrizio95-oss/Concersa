data "aws_caller_identity" "current" {}

resource "aws_kms_key" "cloudwatch_logs" {
  description             = "KMS key para cifrar CloudWatch Logs (${var.project_name}-${var.environment})"
  deletion_window_in_days = 7
  enable_key_rotation     = true

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Sid      = "AllowAccountAdmin",
        Effect   = "Allow",
        Principal = { AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root" },
        Action   = "kms:*",
        Resource = "*"
      },

      {
        Sid    = "AllowCloudWatchLogsUseKey",
        Effect = "Allow",
        Principal = {
          Service = "logs.${var.aws_region}.amazonaws.com"
        },
        Action = [
          "kms:Encrypt",
          "kms:Decrypt",
          "kms:ReEncrypt*",
          "kms:GenerateDataKey*",
          "kms:DescribeKey"
        ],
        Resource = "*"
      }
    ]
  })
}

resource "aws_kms_alias" "cloudwatch_logs" {
  name          = "alias/${var.project_name}-${var.environment}-cw-logs"
  target_key_id = aws_kms_key.cloudwatch_logs.key_id
}

resource "aws_kms_key" "dynamodb" {
  description             = "KMS key para cifrado DynamoDB (${var.project_name}-${var.environment})"
  deletion_window_in_days = 7
  enable_key_rotation     = true

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Sid      = "AllowAccountAdmin",
        Effect   = "Allow",
        Principal = {
          AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
        },
        Action   = "kms:*",
        Resource = "*"
      },
      {
        Sid      = "AllowDynamoDBUseKey",
        Effect   = "Allow",
        Principal = {
          Service = "dynamodb.${var.aws_region}.amazonaws.com"
        },
        Action = [
          "kms:Encrypt",
          "kms:Decrypt",
          "kms:ReEncrypt*",
          "kms:GenerateDataKey*",
          "kms:DescribeKey"
        ],
        Resource = "*",
        Condition = {
          StringEquals = {
            "kms:CallerAccount" = "${data.aws_caller_identity.current.account_id}"
          }
        }
      }
    ]
  })
}

resource "aws_kms_alias" "dynamodb" {
  name          = "alias/${var.project_name}-${var.environment}-dynamodb"
  target_key_id = aws_kms_key.dynamodb.key_id
}

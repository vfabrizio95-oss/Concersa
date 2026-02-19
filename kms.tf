data "aws_caller_identity" "current" {}

resource "aws_kms_key" "main" {
  description             = "${local.prefix} - KMS key principal"
  deletion_window_in_days = 30
  enable_key_rotation     = true

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Sid      = "Enable IAM User Permissions",
        Effect   = "Allow",
        Principal = { AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root" },
        Action   = "kms:*",
        Resource = "*"
      },

      {
        Sid    = "Allow Lambda and services",
        Effect = "Allow",
        Principal = {
          Service = [
            "lambda.amazonaws.com",
            "sqs.amazonaws.com",
            "sns.amazonaws.com",
            "dynamodb.amazonaws.com",
            "s3.amazonaws.com"
          ]
        },
        Action = [
          "kms:Decrypt",
          "kms:GenerateDataKey",
          "kms:DescribeKey"
        ],
        Resource = "*"
      }
    ]
  })
  tags = { Name = "${local.prefix}-kms" }
}

resource "aws_kms_alias" "main" {
  name          = "alias/${local.prefix}-key"
  target_key_id = aws_kms_key.main.key_id
}
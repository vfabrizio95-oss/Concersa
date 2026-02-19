resource "aws_sqs_queue" "valorizaciones" {
  name                        = "${local.prefix}-valorizaciones.fifo"
  fifo_queue                  = true
  content_based_deduplication = true
  visibility_timeout_seconds  = 300
  kms_master_key_id           = aws_kms_key.main.id

  redrive_policy = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.valorizaciones_dlq.arn
    maxReceiveCount     = 3
  })

  tags = {
    Name = "${local.prefix}-sqs-valorizaciones"
  }
}

resource "aws_sqs_queue" "valorizaciones_dlq" {
  name                      = "${local.prefix}-valorizaciones-dlq.fifo"
  fifo_queue                = true
  message_retention_seconds = 1209600
  kms_master_key_id         = aws_kms_key.main.id

  tags = {
    Name = "${local.prefix}-valorizaciones-dlq"
  }
}

resource "aws_sqs_queue" "ordenes" {
  name                        = "${local.prefix}-ordenes.fifo"
  fifo_queue                  = true
  content_based_deduplication = true
  visibility_timeout_seconds  = 300
  kms_master_key_id           = aws_kms_key.main.id

  redrive_policy = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.orden_validada_dlq.arn
    maxReceiveCount     = 3
  })

  tags = {
    Name = "${local.prefix}-sqs-ordenes"
  }
}

resource "aws_sqs_queue" "ordenes_dlq" {
  name                      = "${local.prefix}-ordenes-dlq.fifo"
  fifo_queue                = true
  message_retention_seconds = 1209600
  kms_master_key_id         = aws_kms_key.main.id

  tags = {
    Name = "${local.prefix}-ordenes-dlq"
  }
}

resource "aws_sns_topic" "notificaciones" {
  name              = "${local.prefix}-notificaciones"
  kms_master_key_id = aws_kms_key.main.id

  tags = {
    Name = "${local.prefix}-sns-notificaciones"
  }
}

resource "aws_sns_topic" "valorizacion_terminada" {
  name              = "${local.prefix}-valorizacion-terminada"
  kms_master_key_id = aws_kms_key.main.id

  tags = {
    Name = "${local.prefix}-sns-valorizacion"
  }
}

resource "aws_sns_topic_subscription" "valorizacion_a_sqs" {
  topic_arn            = aws_sns_topic.valorizacion_terminada.arn
  protocol             = "sqs"
  endpoint             = aws_sqs_queue.valorizaciones.arn
  raw_message_delivery = true
}

resource "aws_sqs_queue_policy" "valorizaciones_sns" {
  queue_url = aws_sqs_queue.valorizaciones.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "sns.amazonaws.com"
        }
        Action   = "sqs:SendMessage"
        Resource = aws_sqs_queue.valorizaciones.arn
        Condition = {
          ArnEquals = {
            "aws:SourceArn" = aws_sns_topic.valorizacion_terminada.arn
          }
        }
      }
    ]
  })
}

resource "aws_sqs_queue_policy" "valorizaciones_eventbridge" {
  queue_url = aws_sqs_queue.valorizaciones.url

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "events.amazonaws.com"
        }
        Action   = "sqs:SendMessage"
        Resource = aws_sqs_queue.valorizaciones.arn
        Condition = {
          ArnEquals = {
            "aws:SourceArn" = aws_cloudwatch_event_rule.valorizacion_creada.arn
          }
        }
      }
    ]
  })
}

resource "aws_sqs_queue_policy" "ordenes_eventbridge" {
  queue_url = aws_sqs_queue.ordenes.url

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "events.amazonaws.com"
        }
        Action   = "sqs:SendMessage"
        Resource = aws_sqs_queue.ordenes.arn
        Condition = {
          ArnEquals = {
            "aws:SourceArn" = [
            aws_cloudwatch_event_rule.orden_recibida.arn,
            aws_cloudwatch_event_rule.orden_eliminada.arn
            ]
          }
        }
      }
    ]
  })
}
resource "aws_sqs_queue" "orden_recibida" {
  name                       = "${var.project_name}-orden-recibida-${var.environment}"
  delay_seconds              = 0
  max_message_size           = 262144
  message_retention_seconds  = 345600
  receive_wait_time_seconds  = 10
  visibility_timeout_seconds = 300

  redrive_policy = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.orden_recibida_dlq.arn
    maxReceiveCount     = 3
  })

  tags = {
    Name = "${var.project_name}-orden-recibida"
  }
}

resource "aws_sqs_queue" "orden_recibida_dlq" {
  name                      = "${var.project_name}-orden-recibida-dlq-${var.environment}"
  message_retention_seconds = 1209600 # 14 días
}

resource "aws_sqs_queue" "orden_validada" {
  name                       = "${var.project_name}-orden-validada-${var.environment}"
  delay_seconds              = 0
  max_message_size           = 262144
  message_retention_seconds  = 345600
  receive_wait_time_seconds  = 10
  visibility_timeout_seconds = 300

  redrive_policy = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.orden_validada_dlq.arn
    maxReceiveCount     = 3
  })
}

resource "aws_sqs_queue" "orden_validada_dlq" {
  name                      = "${var.project_name}-orden-validada-dlq-${var.environment}"
  message_retention_seconds = 1209600
}

resource "aws_sqs_queue" "orden_ejecutada" {
  name                       = "${var.project_name}-orden-ejecutada-${var.environment}"
  delay_seconds              = 0
  max_message_size           = 262144
  message_retention_seconds  = 345600
  receive_wait_time_seconds  = 10
  visibility_timeout_seconds = 300

  redrive_policy = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.orden_ejecutada_dlq.arn
    maxReceiveCount     = 3
  })
}

resource "aws_sqs_queue" "orden_ejecutada_dlq" {
  name                      = "${var.project_name}-orden-ejecutada-dlq-${var.environment}"
  message_retention_seconds = 1209600
}

resource "aws_sqs_queue_policy" "orden_recibida" {
  queue_url = aws_sqs_queue.orden_recibida.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "events.amazonaws.com"
        }
        Action   = "sqs:SendMessage"
        Resource = aws_sqs_queue.orden_recibida.arn
        Condition = {
          ArnEquals = {
            "aws:SourceArn" = aws_cloudwatch_event_rule.orden_recibida.arn
          }
        }
      }
    ]
  })
}

resource "aws_sqs_queue_policy" "orden_validada" {
  queue_url = aws_sqs_queue.orden_validada.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "events.amazonaws.com"
        }
        Action   = "sqs:SendMessage"
        Resource = aws_sqs_queue.orden_validada.arn
        Condition = {
          ArnEquals = {
            "aws:SourceArn" = aws_cloudwatch_event_rule.orden_validada.arn
          }
        }
      }
    ]
  })
}

resource "aws_sqs_queue_policy" "orden_ejecutada" {
  queue_url = aws_sqs_queue.orden_ejecutada.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "events.amazonaws.com"
        }
        Action   = "sqs:SendMessage"
        Resource = aws_sqs_queue.orden_ejecutada.arn
        Condition = {
          ArnEquals = {
            "aws:SourceArn" = aws_cloudwatch_event_rule.orden_ejecutada.arn
          }
        }
      }
    ]
  })
}

resource "aws_cloudwatch_metric_alarm" "orden_recibida_dlq" {
  alarm_name          = "${var.project_name}-orden-recibida-dlq-alarm-${var.environment}"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "1"
  metric_name         = "ApproximateNumberOfMessagesVisible"
  namespace           = "AWS/SQS"
  period              = "300"
  statistic           = "Average"
  threshold           = "1"
  alarm_description   = "Alerta cuando hay mensajes en la DLQ"
  treat_missing_data  = "notBreaching"

  dimensions = {
    QueueName = aws_sqs_queue.orden_recibida_dlq.name
  }
}
resource "aws_xray_sampling_rule" "main" {
  rule_name      = "${local.prefix}-sampling"
  priority       = 9000
  version        = 1
  reservoir_size = 10
  fixed_rate     = 0.05
  url_path       = "*"
  host           = "*"
  http_method    = "*"
  service_type   = "*"
  service_name   = "*"
  resource_arn   = "*"
}


resource "aws_cloudwatch_log_group" "api" {
  name              = "/aws/apigateway/${local.prefix}"
  retention_in_days = 30
}

resource "aws_cloudwatch_log_group" "lambda_valorizacion_negocio" {
  name              = "/aws/lambda/${aws_lambda_function.valorizacion_consersa.function_name}"
  retention_in_days = 30
}

resource "aws_cloudwatch_log_group" "lambda_orden_recibida" {
  name              = "/aws/lambda/${aws_lambda_function.orden_recibida.function_name}"
  retention_in_days = 30
}

resource "aws_cloudwatch_log_group" "lambda_orden_eliminada" {
  name              = "/aws/lambda/${aws_lambda_function.orden_eliminada.function_name}"
  retention_in_days = 30
}

resource "aws_cloudwatch_log_group" "lambda_consultar_ordenes" {
  name              = "/aws/lambda/${aws_lambda_function.consultar_ordenes.function_name}"
  retention_in_days = 30
}

resource "aws_cloudwatch_log_group" "lambda_valorizacion_completada" {
  name              = "/aws/lambda/${aws_lambda_function.valorizacion_completada.function_name}"
  retention_in_days = 30
}

resource "aws_cloudwatch_log_group" "lambda_pdf_processing" {
  name              = "/aws/lambda/${aws_lambda_function.pdf_processing.function_name}"
  retention_in_days = 30
}

resource "aws_sns_topic" "alarmas" {
  name              = "${local.prefix}-alarmas"
  kms_master_key_id = aws_kms_key.main.id
}

resource "aws_sns_topic_subscription" "alarmas_email" {
  topic_arn = aws_sns_topic.alarmas.arn
  protocol  = "email"
  endpoint  = var.alarm_email
}

resource "aws_cloudwatch_metric_alarm" "api_5xx" {
  alarm_name          = "${local.prefix}-api-5xx"
  namespace           = "AWS/ApiGateway"
  metric_name         = "5XXError"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  period              = 300
  statistic           = "Sum"
  threshold           = 10
  alarm_description   = "Más de 10 errores 5XX en 10 min"
  treat_missing_data  = "notBreaching"
  alarm_actions       = [aws_sns_topic.alarmas.arn]
  dimensions          = { ApiName = aws_api_gateway_rest_api.main.name }
}

resource "aws_cloudwatch_metric_alarm" "dlq_valorizaciones" {
  alarm_name          = "${local.prefix}-dlq-valorizaciones"
  namespace           = "AWS/SQS"
  metric_name         = "ApproximateNumberOfMessagesVisible"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  period              = 300
  statistic           = "Sum"
  threshold           = 0
  alarm_description   = "Mensajes en DLQ Valorizaciones"
  treat_missing_data  = "notBreaching"
  alarm_actions       = [aws_sns_topic.alarmas.arn]
  dimensions          = { QueueName = aws_sqs_queue.valorizaciones_dlq.name }
}

resource "aws_cloudwatch_metric_alarm" "dlq_ordenes" {
  alarm_name          = "${local.prefix}-dlq-ordenes"
  namespace           = "AWS/SQS"
  metric_name         = "ApproximateNumberOfMessagesVisible"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  period              = 300
  statistic           = "Sum"
  threshold           = 0
  alarm_description   = "Mensajes en DLQ Ordenes"
  treat_missing_data  = "notBreaching"
  alarm_actions       = [aws_sns_topic.alarmas.arn]
  dimensions          = { QueueName = aws_sqs_queue.ordenes_dlq.name }
}

resource "aws_cloudwatch_metric_alarm" "lambda_errors" {
  alarm_name          = "${local.prefix}-lambda-errors"
  namespace           = "AWS/Lambda"
  metric_name         = "Errors"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  period              = 300
  statistic           = "Sum"
  threshold           = 5
  alarm_description   = "Lambdas con más de 5 errores en 10 min"
  treat_missing_data  = "notBreaching"
  alarm_actions       = [aws_sns_topic.alarmas.arn]
  dimensions          = { FunctionName = aws_lambda_function.valorizacion_consersa.function_name }
}

resource "aws_cloudwatch_dashboard" "main" {
  dashboard_name = "${local.prefix}-dashboard"
  dashboard_body = jsonencode({
    widgets = [
      {
        type = "metric"
        x = 0
        y = 0
        width = 12
        height = 6

        properties = {
          title   = "API Gateway - Solicitudes y Errores"
          period  = 300
          metrics = [
            ["AWS/ApiGateway", "Count",    "ApiName", aws_api_gateway_rest_api.main.name],
            ["AWS/ApiGateway", "5XXError", "ApiName", aws_api_gateway_rest_api.main.name],
            ["AWS/ApiGateway", "4XXError", "ApiName", aws_api_gateway_rest_api.main.name]
          ]
        }
      },
      {
        type = "metric"
        x = 12
        y = 0
        width = 12
        height = 6

        properties = {
          title   = "Lambda - Errores"
          period  = 300
          metrics = [
            ["AWS/Lambda", "Errors", "FunctionName", aws_lambda_function.valorizacion_consersa.function_name],
            ["AWS/Lambda", "Errors", "FunctionName", aws_lambda_function.orden_recibida.function_name],
            ["AWS/Lambda", "Errors", "FunctionName", aws_lambda_function.orden_eliminada.function_name],
            ["AWS/Lambda", "Errors", "FunctionName", aws_lambda_function.consultar_ordenes.function_name],
            ["AWS/Lambda", "Errors", "FunctionName", aws_lambda_function.valorizacion_completada.function_name],
            ["AWS/Lambda", "Errors", "FunctionName", aws_lambda_function.pdf_processing.function_name]
          ]
        }
      },
      {
        type = "metric"
        x = 0
        y = 6
        width = 24
        height = 6
        
        properties = {
          title   = "SQS - Mensajes en Cola"
          period  = 300
          metrics = [
            ["AWS/SQS", "ApproximateNumberOfMessagesVisible", "QueueName", aws_sqs_queue.valorizaciones.name],
            ["AWS/SQS", "ApproximateNumberOfMessagesVisible", "QueueName", aws_sqs_queue.ordenes.name],
            ["AWS/SQS", "ApproximateNumberOfMessagesVisible", "QueueName", aws_sqs_queue.valorizaciones_dlq.name],
            ["AWS/SQS", "ApproximateNumberOfMessagesVisible", "QueueName", aws_sqs_queue.ordenes_dlq.name]
          ]
        }
      }
    ]
  })
}

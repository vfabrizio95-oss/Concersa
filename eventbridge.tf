resource "aws_cloudwatch_event_bus" "main" {
  name = "${var.project_name}-event-bus-${var.environment}"

  tags = {
    Name = "${var.project_name}-event-bus"
  }
}

resource "aws_cloudwatch_event_rule" "orden_recibida" {
  name           = "${var.project_name}-orden-recibida-${var.environment}"
  description    = "Regla para eventos de orden recibida"
  event_bus_name = aws_cloudwatch_event_bus.main.name

  event_pattern = jsonencode({
    source      = ["custom.orders"]
    detail-type = ["Order Received"]
  })
}

resource "aws_cloudwatch_event_target" "orden_recibida_sqs" {
  rule           = aws_cloudwatch_event_rule.orden_recibida.name
  event_bus_name = aws_cloudwatch_event_bus.main.name
  arn            = aws_sqs_queue.orden_recibida.arn
  target_id      = "OrdenRecibidaSQS"
}

resource "aws_cloudwatch_event_rule" "orden_validada" {
  name           = "${var.project_name}-orden-validada-${var.environment}"
  description    = "Regla para eventos de orden validada"
  event_bus_name = aws_cloudwatch_event_bus.main.name

  event_pattern = jsonencode({
    source      = ["custom.orders"]
    detail-type = ["Order Validated"]
  })
}

resource "aws_cloudwatch_event_target" "orden_validada_sqs" {
  rule           = aws_cloudwatch_event_rule.orden_validada.name
  event_bus_name = aws_cloudwatch_event_bus.main.name
  arn            = aws_sqs_queue.orden_validada.arn
  target_id      = "OrdenValidadaSQS"
}

resource "aws_cloudwatch_event_rule" "orden_ejecutada" {
  name           = "${var.project_name}-orden-ejecutada-${var.environment}"
  description    = "Regla para eventos de orden ejecutada"
  event_bus_name = aws_cloudwatch_event_bus.main.name

  event_pattern = jsonencode({
    source      = ["custom.orders"]
    detail-type = ["Order Executed"]
  })
}

resource "aws_cloudwatch_event_target" "orden_ejecutada_sqs" {
  rule           = aws_cloudwatch_event_rule.orden_ejecutada.name
  event_bus_name = aws_cloudwatch_event_bus.main.name
  arn            = aws_sqs_queue.orden_ejecutada.arn
  target_id      = "OrdenEjecutadaSQS"
}

resource "aws_cloudwatch_event_rule" "orden_eliminada" {
  name           = "${var.project_name}-orden-eliminada-${var.environment}"
  description    = "Regla para eventos de orden eliminada"
  event_bus_name = aws_cloudwatch_event_bus.main.name

  event_pattern = jsonencode({
    source      = ["custom.orders"]
    detail-type = ["Order Deleted"]
  })
}

resource "aws_cloudwatch_event_target" "orden_eliminada_lambda" {
  rule           = aws_cloudwatch_event_rule.orden_eliminada.name
  event_bus_name = aws_cloudwatch_event_bus.main.name
  arn            = aws_lambda_function.orden_eliminada_handler.arn
  target_id      = "OrdenEliminadaLambda"
}

resource "aws_lambda_permission" "eventbridge_orden_eliminada" {
  statement_id  = "AllowExecutionFromEventBridge"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.orden_eliminada_handler.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.orden_eliminada.arn
}

resource "aws_cloudwatch_event_archive" "main" {
  name             = "${var.project_name}-events-archive-${var.environment}"
  event_source_arn = aws_cloudwatch_event_bus.main.arn
  retention_days   = 30

  description = "Archivo de eventos para auditoría"
}

output "event_bus_name" {
  value = aws_cloudwatch_event_bus.main.name
}

output "event_bus_arn" {
  value = aws_cloudwatch_event_bus.main.arn
}

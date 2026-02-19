resource "aws_cloudwatch_event_bus" "main" {
  name = "${local.prefix}-bus"
  tags = {
    Name = "${local.prefix}-event-bus"
  }
}

resource "aws_cloudwatch_event_rule" "valorizacion_creada" {
  name           = "${local.prefix}-valorizacion-creada"
  event_bus_name = aws_cloudwatch_event_bus.main.name

  event_pattern = jsonencode({
    source      = ["Concersa.valorizacion"]
    detail-type = ["Valorizacion Creada"]
  })
}

resource "aws_cloudwatch_event_target" "valorizacion_sqs" {
  rule           = aws_cloudwatch_event_rule.valorizacion_creada.name
  event_bus_name = aws_cloudwatch_event_bus.main.name
  arn            = aws_sqs_queue.valorizaciones.arn
  target_id      = "SQS_valorizaciones"
  sqs_target {
    message_group_id = "default"
    }
}

resource "aws_cloudwatch_event_rule" "orden_recibida" {
  name           = "${local.prefix}-orden-recibida"
  event_bus_name = aws_cloudwatch_event_bus.main.name

  event_pattern = jsonencode({
    source      = ["Concersa.ordenes"]
    detail-type = ["Order recibida"]
  })
}

resource "aws_cloudwatch_event_target" "orden_recibida_sqs" {
  rule           = aws_cloudwatch_event_rule.orden_recibida.name
  event_bus_name = aws_cloudwatch_event_bus.main.name
  arn            = aws_sqs_queue.ordenes.arn
  target_id      = "SQS_Ordenes"
  sqs_target {
    message_group_id = "default"
    }
}

resource "aws_cloudwatch_event_rule" "orden_eliminada" {
  name           = "${local.prefix}-orden-eliminada"
  event_bus_name = aws_cloudwatch_event_bus.main.name

  event_pattern = jsonencode({
    source      = ["Consersa.orders"]
    detail-type = ["Order Eliminada"]
  })
}

resource "aws_cloudwatch_event_target" "orden_eliminada_sqs" {
  rule           = aws_cloudwatch_event_rule.orden_eliminada.name
  event_bus_name = aws_cloudwatch_event_bus.main.name
  arn            = aws_sqs_queue.ordenes.arn
  target_id      = "SQS_ordenes_eliminadas"
  sqs_target {
    message_group_id = "default"
    }
}

resource "aws_cloudwatch_event_bus_policy" "allow_account" {
  event_bus_name = aws_cloudwatch_event_bus.main.name
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Sid       = "AllowAccountPutEvents"
      Effect    = "Allow"
      Principal = { AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root" }
      Action    = "events:PutEvents"
      Resource  = aws_cloudwatch_event_bus.main.arn
    }]
  })
}
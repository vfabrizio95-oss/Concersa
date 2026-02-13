resource "aws_dynamodb_table" "usuarios" {
  name             = "${var.project_name}-usuarios-${var.environment}"
  billing_mode     = "PAY_PER_REQUEST"
  hash_key         = "userId"
  stream_enabled   = true
  stream_view_type = "NEW_AND_OLD_IMAGES"

  attribute {
    name = "userId"
    type = "S"
  }

  attribute {
    name = "email"
    type = "S"
  }

  global_secondary_index {
    name            = "EmailIndex"
    hash_key        = "email"
    projection_type = "ALL"
  }

  point_in_time_recovery {
    enabled = true
  }

  server_side_encryption {
    enabled = true
  }

  tags = {
    Name = "${var.project_name}-usuarios"
  }
}

resource "aws_dynamodb_table" "informacion_original" {
  name             = "${var.project_name}-informacion-original-${var.environment}"
  billing_mode     = "PAY_PER_REQUEST"
  hash_key         = "infoId"
  range_key        = "timestamp"
  stream_enabled   = true
  stream_view_type = "NEW_AND_OLD_IMAGES"

  attribute {
    name = "infoId"
    type = "S"
  }

  attribute {
    name = "timestamp"
    type = "N"
  }

  attribute {
    name = "categoria"
    type = "S"
  }

  global_secondary_index {
    name            = "CategoriaIndex"
    hash_key        = "categoria"
    range_key       = "timestamp"
    projection_type = "ALL"
  }

  ttl {
    attribute_name = "expirationTime"
    enabled        = true
  }

  point_in_time_recovery {
    enabled = true
  }

  server_side_encryption {
    enabled = true
  }

  tags = {
    Name = "${var.project_name}-informacion-original"
  }
}

resource "aws_dynamodb_table" "informacion_guardada" {
  name             = "${var.project_name}-informacion-guardada-${var.environment}"
  billing_mode     = "PAY_PER_REQUEST"
  hash_key         = "savedId"
  range_key        = "userId"
  stream_enabled   = true
  stream_view_type = "NEW_AND_OLD_IMAGES"

  attribute {
    name = "savedId"
    type = "S"
  }

  attribute {
    name = "userId"
    type = "S"
  }

  attribute {
    name = "createdAt"
    type = "N"
  }

  global_secondary_index {
    name            = "UserIndex"
    hash_key        = "userId"
    range_key       = "createdAt"
    projection_type = "ALL"
  }

  point_in_time_recovery {
    enabled = true
  }

  server_side_encryption {
    enabled = true
  }

  tags = {
    Name = "${var.project_name}-informacion-guardada"
  }
}

resource "aws_cloudwatch_metric_alarm" "dynamodb_read_throttle" {
  alarm_name          = "${var.project_name}-dynamodb-read-throttle-${var.environment}"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "ReadThrottleEvents"
  namespace           = "AWS/DynamoDB"
  period              = "300"
  statistic           = "Sum"
  threshold           = "10"
  alarm_description   = "Alerta cuando hay throttling de lectura en DynamoDB"

  dimensions = {
    TableName = aws_dynamodb_table.usuarios.name
  }
}

resource "aws_cloudwatch_metric_alarm" "dynamodb_write_throttle" {
  alarm_name          = "${var.project_name}-dynamodb-write-throttle-${var.environment}"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "WriteThrottleEvents"
  namespace           = "AWS/DynamoDB"
  period              = "300"
  statistic           = "Sum"
  threshold           = "10"
  alarm_description   = "Alerta cuando hay throttling de escritura en DynamoDB"

  dimensions = {
    TableName = aws_dynamodb_table.usuarios.name
  }
}
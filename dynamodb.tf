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
    kms_key_arn = aws_kms_key.main.arn
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
    kms_key_arn = aws_kms_key.main.arn
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
    kms_key_arn = aws_kms_key.main.arn
  }

  tags = {
    Name = "${var.project_name}-informacion-guardada"
  }
}
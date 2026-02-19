resource "aws_iam_role" "lambda" {
  name = "${local.prefix}-lambda-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_basic" {
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
  role       = aws_iam_role.lambda.name
}

resource "aws_iam_role_policy_attachment" "lambda_vpc" {
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole"
  role       = aws_iam_role.lambda.name
}

resource "aws_iam_role_policy_attachment" "lambda_xray" {
  policy_arn = "arn:aws:iam::aws:policy/AWSXRayDaemonWriteAccess"
  role       = aws_iam_role.lambda.name
}

resource "aws_iam_role_policy" "lambda_custom" {
  name = "${local.prefix}-lambda-policy"
  role = aws_iam_role.lambda.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid: "Dynamo"
        Effect = "Allow"
        Action = [
          "dynamodb:GetItem",
          "dynamodb:PutItem",
          "dynamodb:UpdateItem",
          "dynamodb:DeleteItem",
          "dynamodb:Query",
          "dynamodb:Scan"
        ]
        Resource = [
          aws_dynamodb_table.usuarios.arn,
          aws_dynamodb_table.informacion_original.arn,
          aws_dynamodb_table.informacion_guardada.arn,
          "${aws_dynamodb_table.usuarios.arn}/index/*",
          "${aws_dynamodb_table.informacion_original.arn}/index/*",
          "${aws_dynamodb_table.informacion_guardada.arn}/index/*"
        ]
      },
      {
        Sid      = "SNS"
        Effect   = "Allow"
        Action   = [
          "sns:Publish"
        ]
        Resource = [
          aws_sns_topic.notificaciones.arn,
          aws_sns_topic.valorizacion_terminada.arn
        ]
      },
      {
        Sid = "S3"
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject"
        ]
        Resource = [
          "${aws_s3_bucket.data_storage.arn}/*"
        ]
      },
      {
        Sid: "SQS"
        Effect = "Allow"
        Action = [
          "sqs:ReceiveMessage",
          "sqs:DeleteMessage",
          "sqs:GetQueueAttributes",
          "sqs:SendMessage"
        ]
        Resource = [
          aws_sqs_queue.valorizaciones.arn,
          aws_sqs_queue.ordenes.arn
        ]
      },
      {
        Sid = "Events"
        Effect = "Allow"
        Action = [
          "events:PutEvents"
        ]
        Resource = [
          aws_cloudwatch_event_bus.main.arn
        ]
      },
      {
        Sid      = "KMS"
        Effect   = "Allow"
        Action   = [
          "kms:Decrypt",
          "kms:GenerateDataKey",
          "kms:DescribeKey"
        ]
        Resource = [
          aws_kms_key.main.arn
        ]
      },
      {
        Sid = "SES"
        Effect = "Allow"
        Action = [
          "ses:SendEmail",
          "ses:SendRawEmail"
        ]
        Resource = "*"
      }
    ]
  })
}

data "archive_file" "placeholder" {
  type        = "zip"
  output_path = "/tmp/lambda_placeholder.zip"
  source {
    filename = "index.js"
    content  = "exports.handler = async (e, c) => ({ statusCode: 200, body: JSON.stringify({ ok: true, id: c.awsRequestId }) });"
  }
}

resource "aws_lambda_function" "valorizacion_consersa" {
  filename      = data.archive_file.placeholder.output_path
  function_name = "${local.prefix}-valorizacion-consersa"
  role          = aws_iam_role.lambda.arn
  handler       = "index.handler"
  runtime       = "nodejs20.x"
  timeout       = 30
  memory_size   = 256
  source_code_hash = data.archive_file.placeholder.output_base64sha256

  vpc_config {
    subnet_ids         = aws_subnet.private[*].id
    security_group_ids = [aws_security_group.lambda_sg.id]
  }

    tracing_config {
    mode = "Active"
  }

  environment {
    variables = {
      TABLE_USUARIOS             = aws_dynamodb_table.usuarios.name
      TABLE_INFORMACION_ORIGINAL = aws_dynamodb_table.informacion_original.name
      TABLE_INFORMACION_GUARDADA = aws_dynamodb_table.informacion_guardada.name
      EVENT_BUS_NAME             = aws_cloudwatch_event_bus.main.name
      SQS_VAL_URL                = aws_sqs_queue.valorizaciones.url
    }
  }
}

resource "aws_lambda_permission" "api_gateway_valorizacion" {
  statement_id  = "AllowAPIGW"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.valorizacion_consersa.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.main.execution_arn}/*/*"
}

resource "aws_lambda_function" "orden_recibida" {
  filename      = data.archive_file.placeholder.output_path
  function_name = "${local.prefix}-orden-recibida"
  role          = aws_iam_role.lambda.arn
  handler       = "index.handler"
  runtime       = "nodejs20.x"
  timeout       = 30
  memory_size   = 256
  source_code_hash = data.archive_file.placeholder.output_base64sha256
  
  vpc_config {
    subnet_ids         = aws_subnet.private[*].id
    security_group_ids = [aws_security_group.lambda_sg.id]
  }

    tracing_config {
    mode = "Active"
  }

  environment {
    variables = {
      TABLE_USUARIOS = aws_dynamodb_table.usuarios.name
      TABLE_INFORMACION_ORIGINAL = aws_dynamodb_table.informacion_original.name
      TABLE_INFORMACION_GUARDADA = aws_dynamodb_table.informacion_guardada.name
      EVENT_BUS_NAME = aws_cloudwatch_event_bus.main.name
    }
  }
}

resource "aws_lambda_permission" "api_gateway_orden_recibida" {
  statement_id  = "AllowAPIGW"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.orden_recibida.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.main.execution_arn}//"
}

resource "aws_lambda_function" "orden_eliminada" {
  filename      = data.archive_file.placeholder.output_path
  function_name = "${local.prefix}-orden-eliminada"
  role          = aws_iam_role.lambda.arn
  handler       = "index.handler"
  runtime       = "nodejs20.x"
  timeout       = 30
  memory_size   = 256
  source_code_hash = data.archive_file.placeholder.output_base64sha256
  vpc_config {
    subnet_ids         = aws_subnet.private[*].id
    security_group_ids = [aws_security_group.lambda_sg.id]
  }

    tracing_config {
    mode = "Active"
  }

  environment {
    variables = {
      TABLE_USUARIOS             = aws_dynamodb_table.usuarios.name
      TABLE_INFORMACION_ORIGINAL = aws_dynamodb_table.informacion_original.name
      TABLE_INFORMACION_GUARDADA = aws_dynamodb_table.informacion_guardada.name
      EVENT_BUS_NAME             = aws_cloudwatch_event_bus.main.name
    }
  }
}

resource "aws_lambda_permission" "api_gateway_orden_eliminada" {
  statement_id  = "AllowAPIGW"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.orden_eliminada.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.main.execution_arn}//"
}

resource "aws_lambda_function" "consultar_ordenes" {
  filename      = data.archive_file.placeholder.output_path
  function_name = "${local.prefix}-consultar-ordenes"
  role          = aws_iam_role.lambda.arn
  handler       = "index.handler"
  runtime       = "nodejs20.x"
  timeout       = 30
  memory_size   = 256
  source_code_hash = data.archive_file.placeholder.output_base64sha256

   vpc_config {
    subnet_ids         = aws_subnet.private[*].id
    security_group_ids = [aws_security_group.lambda_sg.id]
  }

    tracing_config {
    mode = "Active"
  }

  environment {
    variables = {
      TABLE_USUARIOS             = aws_dynamodb_table.usuarios.name
      TABLE_INFORMACION_ORIGINAL = aws_dynamodb_table.informacion_original.name
      TABLE_INFORMACION_GUARDADA = aws_dynamodb_table.informacion_guardada.name
    }
  }
}

resource "aws_lambda_permission" "api_gateway_consultar" {
  statement_id  = "AllowAPIGW"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.consultar_ordenes.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.main.execution_arn}//"
}

resource "aws_lambda_function" "valorizacion_completada" {
  filename      = data.archive_file.placeholder.output_path
  function_name = "${local.prefix}-valorizacion-completada"
  role          = aws_iam_role.lambda.arn
  handler       = "index.handler"
  runtime       = "nodejs20.x"
  timeout       = 60
  memory_size   = 512
  source_code_hash = data.archive_file.placeholder.output_base64sha256

  vpc_config {
    subnet_ids         = aws_subnet.private[*].id
    security_group_ids = [aws_security_group.lambda_sg.id]
  }

    tracing_config {
    mode = "Active"
  }

  environment {
    variables = {
      TABLE_USUARIOS             = aws_dynamodb_table.usuarios.name
      TABLE_INFORMACION_ORIGINAL = aws_dynamodb_table.informacion_original.name
      TABLE_INFORMACION_GUARDADA = aws_dynamodb_table.informacion_guardada.name
      SNS_VALORIZACION           = aws_sns_topic.valorizacion_terminada.arn
      SES_FROM_EMAIL             = "notificaciones@${var.domain_name}"
    }
  }
}

resource "aws_lambda_event_source_mapping" "sqs_valorizacion" {
  event_source_arn        = aws_sqs_queue.valorizaciones.arn
  function_name           = aws_lambda_function.valorizacion_completada.arn
  batch_size              = 10
  function_response_types = ["ReportBatchItemFailures"]
}

resource "aws_lambda_function" "pdf_processing" {
  filename      = data.archive_file.placeholder.output_path
  function_name = "${local.prefix}-pdf-processing"
  role          = aws_iam_role.lambda.arn
  handler       = "index.handler"
  runtime       = "nodejs20.x"
  timeout       = 120
  memory_size   = 1024

  source_code_hash = data.archive_file.placeholder.output_base64sha256

  vpc_config {
    subnet_ids         = aws_subnet.private[*].id
    security_group_ids = [aws_security_group.lambda_sg.id]
  }

    tracing_config {
    mode = "Active"
  }

  environment {
    variables = {
      PDF_BUCKET                 = aws_s3_bucket.pdfs.bucket
      TABLE_INFORMACION_ORIGINAL = aws_dynamodb_table.informacion_original.name
      TABLE_INFORMACION_GUARDADA = aws_dynamodb_table.informacion_guardada.name
    }
  }
  ephemeral_storage {
   size = 1024
  }
}

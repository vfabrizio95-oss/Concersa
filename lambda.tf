resource "aws_iam_role" "lambda_exec" {
  name = "${var.project_name}-lambda-exec-role-${var.environment}"

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
  role       = aws_iam_role.lambda_exec.name
}

resource "aws_iam_role_policy_attachment" "lambda_vpc" {
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole"
  role       = aws_iam_role.lambda_exec.name
}

resource "aws_iam_role_policy" "lambda_access" {
  name = "${var.project_name}-lambda-access-policy"
  role = aws_iam_role.lambda_exec.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
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
        Effect = "Allow"
        Action = [
          "sqs:ReceiveMessage",
          "sqs:DeleteMessage",
          "sqs:GetQueueAttributes",
          "sqs:SendMessage"
        ]
        Resource = [
          aws_sqs_queue.orden_recibida.arn,
          aws_sqs_queue.orden_validada.arn,
          aws_sqs_queue.orden_ejecutada.arn
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "events:PutEvents"
        ]
        Resource = [
          aws_cloudwatch_event_bus.main.arn
        ]
      },
      {
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

resource "aws_lambda_layer_version" "common_dependencies" {
  filename            = "lambda_layers/common_dependencies.zip"
  layer_name          = "${var.project_name}-common-deps-${var.environment}"
  compatible_runtimes = ["nodejs18.x", "python3.11"]
  description         = "Dependencias comunes para funciones Lambda"
}

resource "aws_lambda_function" "api_handler" {
  filename      = "lambda_functions/api_handler.zip"
  function_name = "${var.project_name}-api-handler-${var.environment}"
  role          = aws_iam_role.lambda_exec.arn
  handler       = "index.handler"
  runtime       = "nodejs18.x"
  timeout       = 30
  memory_size   = 512

    tracing_config {
    mode = "Active"
  }

  layers = [aws_lambda_layer_version.common_dependencies.arn]

  environment {
    variables = {
      DYNAMODB_USUARIOS_TABLE = aws_dynamodb_table.usuarios.name
      DYNAMODB_INFO_TABLE     = aws_dynamodb_table.informacion_original.name
      EVENT_BUS_NAME          = aws_cloudwatch_event_bus.main.name
      ENVIRONMENT             = var.environment
    }
  }


}

resource "aws_lambda_permission" "api_gateway" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.api_handler.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.main.execution_arn}/*/*"
}

resource "aws_lambda_function" "sqs_orden_recibida_processor" {
  filename      = "lambda_functions/orden_recibida_processor.zip"
  function_name = "${var.project_name}-orden-recibida-processor-${var.environment}"
  role          = aws_iam_role.lambda_exec.arn
  handler       = "index.handler"
  runtime       = "python3.11"
  timeout       = 60
  memory_size   = 512

    tracing_config {
    mode = "Active"
  }

  environment {
    variables = {
      DYNAMODB_TABLE = aws_dynamodb_table.informacion_original.name
      EVENT_BUS_NAME = aws_cloudwatch_event_bus.main.name
    }
  }
}

resource "aws_lambda_event_source_mapping" "orden_recibida" {
  event_source_arn = aws_sqs_queue.orden_recibida.arn
  function_name    = aws_lambda_function.sqs_orden_recibida_processor.arn
  batch_size       = 10
  enabled          = true
}

resource "aws_lambda_function" "sqs_orden_validada_processor" {
  filename      = "lambda_functions/orden_validada_processor.zip"
  function_name = "${var.project_name}-orden-validada-processor-${var.environment}"
  role          = aws_iam_role.lambda_exec.arn
  handler       = "index.handler"
  runtime       = "python3.11"
  timeout       = 60
  memory_size   = 512

    tracing_config {
    mode = "Active"
  }

  environment {
    variables = {
      DYNAMODB_TABLE = aws_dynamodb_table.informacion_guardada.name
      S3_BUCKET      = aws_s3_bucket.data_storage.bucket
    }
  }
}

resource "aws_lambda_event_source_mapping" "orden_validada" {
  event_source_arn = aws_sqs_queue.orden_validada.arn
  function_name    = aws_lambda_function.sqs_orden_validada_processor.arn
  batch_size       = 10
  enabled          = true
}

resource "aws_lambda_function" "sqs_orden_ejecutada_processor" {
  filename      = "lambda_functions/orden_ejecutada_processor.zip"
  function_name = "${var.project_name}-orden-ejecutada-processor-${var.environment}"
  role          = aws_iam_role.lambda_exec.arn
  handler       = "index.handler"
  runtime       = "python3.11"
  timeout       = 60
  memory_size   = 512

    tracing_config {
    mode = "Active"
  }

  environment {
    variables = {
      DYNAMODB_TABLE = aws_dynamodb_table.informacion_guardada.name
      S3_BUCKET      = aws_s3_bucket.data_storage.bucket
    }
  }
}

resource "aws_lambda_event_source_mapping" "orden_ejecutada" {
  event_source_arn = aws_sqs_queue.orden_ejecutada.arn
  function_name    = aws_lambda_function.sqs_orden_ejecutada_processor.arn
  batch_size       = 10
  enabled          = true
}

resource "aws_lambda_function" "orden_eliminada_handler" {
  filename      = "lambda_functions/orden_eliminada_handler.zip"
  function_name = "${var.project_name}-orden-eliminada-handler-${var.environment}"
  role          = aws_iam_role.lambda_exec.arn
  handler       = "index.handler"
  runtime       = "python3.11"
  timeout       = 30
  memory_size   = 256

    tracing_config {
    mode = "Active"
  }

  environment {
    variables = {
      DYNAMODB_TABLE = aws_dynamodb_table.informacion_original.name
    }
  }
}

resource "aws_lambda_function" "completar_finalizar" {
  filename      = "lambda_functions/completar_finalizar.zip"
  function_name = "${var.project_name}-completar-finalizar-${var.environment}"
  role          = aws_iam_role.lambda_exec.arn
  handler       = "index.handler"
  runtime       = "python3.11"
  timeout       = 60
  memory_size   = 512

    tracing_config {
    mode = "Active"
  }

  environment {
    variables = {
      DYNAMODB_TABLE = aws_dynamodb_table.informacion_guardada.name
      S3_BUCKET      = aws_s3_bucket.data_storage.bucket
    }
  }
}

resource "aws_lambda_function" "pdf_processing" {
  filename      = "lambda_functions/pdf_processing.zip"
  function_name = "${var.project_name}-pdf-processing-${var.environment}"
  role          = aws_iam_role.lambda_exec.arn
  handler       = "index.handler"
  runtime       = "python3.11"
  timeout       = 120
  memory_size   = 1024

    tracing_config {
    mode = "Active"
  }

  layers = [aws_lambda_layer_version.common_dependencies.arn]

  environment {
    variables = {
      S3_BUCKET      = aws_s3_bucket.data_storage.bucket
      DYNAMODB_TABLE = aws_dynamodb_table.informacion_guardada.name
    }
  }
}

resource "aws_cloudwatch_log_group" "api_handler" {
  name              = "/aws/lambda/${aws_lambda_function.api_handler.function_name}"
  retention_in_days = 365
  kms_key_id = aws_kms_key.cloudwatch_logs.arn
}

resource "aws_cloudwatch_log_group" "orden_recibida" {
  name              = "/aws/lambda/${aws_lambda_function.sqs_orden_recibida_processor.function_name}"
  retention_in_days = 365
  kms_key_id = aws_kms_key.cloudwatch_logs.arn
}

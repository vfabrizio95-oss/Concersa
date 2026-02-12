output "domain_name" {
  description = "Nombre de dominio principal"
  value       = var.domain_name
}

output "api_domain" {
  description = "Dominio de la API"
  value       = "https://${var.api_subdomain}.${var.domain_name}"
}

output "cloudfront_url" {
  description = "URL de CloudFront"
  value       = "https://${aws_cloudfront_distribution.main.domain_name}"
}

output "cognito_user_pool_id" {
  description = "ID del Cognito User Pool"
  value       = aws_cognito_user_pool.main.id
}

output "cognito_client_id" {
  description = "ID del Cognito Client"
  value       = aws_cognito_user_pool_client.main.id
}

output "cognito_domain_url" {
  description = "URL del dominio de Cognito"
  value       = "https://${aws_cognito_user_pool_domain.main.domain}.auth.${var.aws_region}.amazoncognito.com"
}

output "api_gateway_url" {
  description = "URL del API Gateway"
  value       = aws_api_gateway_stage.main.invoke_url
}

output "dynamodb_tables" {
  description = "Nombres de las tablas DynamoDB"
  value = {
    usuarios             = aws_dynamodb_table.usuarios.name
    informacion_original = aws_dynamodb_table.informacion_original.name
    informacion_guardada = aws_dynamodb_table.informacion_guardada.name
  }
}

output "sqs_queues" {
  description = "URLs de las colas SQS"
  value = {
    orden_recibida  = aws_sqs_queue.orden_recibida.url
    orden_validada  = aws_sqs_queue.orden_validada.url
    orden_ejecutada = aws_sqs_queue.orden_ejecutada.url
  }
}

output "event_bus_name" {
  description = "Nombre del Event Bus"
  value       = aws_cloudwatch_event_bus.main.name
}

output "s3_buckets" {
  description = "Nombres de los buckets S3"
  value = {
    frontend     = aws_s3_bucket.frontend.bucket
    data_storage = aws_s3_bucket.data_storage.bucket
  }
}

output "ses_configuration" {
  description = "Configuración de SES"
  value = {
    domain             = aws_ses_domain_identity.main.domain
    configuration_set  = aws_ses_configuration_set.main.name
    smtp_endpoint      = "email-smtp.${var.aws_region}.amazonaws.com"
  }
}

output "lambda_functions" {
  description = "ARNs de las funciones Lambda principales"
  value = {
    api_handler              = aws_lambda_function.api_handler.arn
    orden_recibida_processor = aws_lambda_function.sqs_orden_recibida_processor.arn
    orden_validada_processor = aws_lambda_function.sqs_orden_validada_processor.arn
    orden_ejecutada_processor = aws_lambda_function.sqs_orden_ejecutada_processor.arn
    pdf_processing           = aws_lambda_function.pdf_processing.arn
  }
}

output "aws_region" {
  description = "Región de AWS donde está desplegada la infraestructura"
  value       = var.aws_region
}

output "environment" {
  description = "Ambiente de despliegue"
  value       = var.environment
}

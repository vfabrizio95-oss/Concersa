output "api_url" {
  description = "URL del API Gateway"
  value       = aws_api_gateway_stage.main.invoke_url
}

output "cloudfront_domain" {
  description = "Dominio CloudFront del frontend"
  value       = aws_cloudfront_distribution.frontend.domain_name
}

output "cognito_pool_id" {
  description = "ID del Cognito User Pool"
  value       = aws_cognito_user_pool.main.id
}

output "cognito_client_id" {
  description = "ID del cliente web Cognito"
  value       = aws_cognito_user_pool_client.web.id
}

output "cognito_auth_domain" {
  description = "Dominio de autenticación Cognito"
  value       = "https://${aws_cognito_user_pool_domain.main.domain}.auth.${var.aws_region}.amazoncognito.com"
}

output "dynamodb_tabla_usuarios" {
  description = "Nombre de la tabla DynamoDB usuarios"
  value       = aws_dynamodb_table.usuarios.name
}

output "dynamodb_tabla_informacion_original" {
  description = "Nombre de la tabla DynamoDB informacion_original"
  value       = aws_dynamodb_table.informacion_original.name
}

output "dynamodb_tabla_informacion_guardada" {
  description = "Nombre de la tabla DynamoDB informacion_guardada"
  value       = aws_dynamodb_table.informacion_guardada.name
}

output "sqs_valorizaciones_url" {
  description = "URL SQS Valorizaciones"
  value       = aws_sqs_queue.valorizaciones.url
}

output "sqs_ordenes_url" {
  description = "URL SQS Ordenes"
  value       = aws_sqs_queue.ordenes.url
}

output "event_bus_name" {
  description = "Nombre del EventBridge Bus"
  value       = aws_cloudwatch_event_bus.main.name
}

output "vpc_id" {
  description = "ID del VPC"
  value       = aws_vpc.main.id
}

output "kms_key_arn" {
  description = "ARN de la KMS Key principal"
  value       = aws_kms_key.main.arn
}

output "route53_name_servers" {
  description = "Name servers a configurar en tu registrador"
  value       = aws_route53_zone.main.name_servers
}

output "dashboard_url" {
  description = "URL del dashboard CloudWatch"
  value       = "https://console.aws.amazon.com/cloudwatch/home?region=${var.aws_region}#dashboards:name=${aws_cloudwatch_dashboard.main.dashboard_name}"
}

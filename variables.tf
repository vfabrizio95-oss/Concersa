variable "aws_region" {
  description = "AWS region donde se desplegará la infraestructura"
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Nombre del proyecto"
  type        = string
  default     = "Concersa"
}

variable "environment" {
  description = "Ambiente de despliegue"
  type        = string
  default     = "dev"
}

variable "domain_name" {
  description = "Nombre de dominio principal"
  type        = string
  default     = "consersa.com"
}

variable "api_subdomain" {
  description = "Subdominio para la API"
  type        = string
  default     = "api"
}

variable "kms_master_key_id" {
  type    = string
  default = null
}

variable "alarm_email" {
  description = "Correo para notificaciones de alarmas"
  type      = string
  sensitive = true
}

variable "cognito_callback_urls" {
  type = list(string)
}

variable "vpc_cidr" {
  type    = string
  default = "10.0.0.0/16"
}

variable "azs" {
  type    = list(string)
  default = ["us-east-1a", "us-east-1b"]
}

locals {
  prefix = "${var.project_name}-${var.environment}"
}
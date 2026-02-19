resource "aws_cognito_user_pool" "main" {
  name = "${local.prefix}-user-pool"
  username_attributes      = ["email"]
  auto_verified_attributes = ["email"]
  mfa_configuration        = "OPTIONAL"

  password_policy {
    minimum_length                   = 10
    require_lowercase                = true
    require_uppercase                = true
    require_numbers                  = true
    require_symbols                  = true
    temporary_password_validity_days = 7
  }

  schema {
    attribute_data_type      = "String"
    name                     = "email"
    required                 = true
    mutable                  = false

    string_attribute_constraints {
      min_length = 1
      max_length = 256
    }
  }

  software_token_mfa_configuration {
    enabled = true
  }

  account_recovery_setting {
    recovery_mechanism {
      name     = "verified_email"
      priority = 1
    }
  }

  tags = {
    Name = "${var.project_name}-user-pool"
  }
}

resource "aws_cognito_user_pool_client" "web" {
  name         = "${local.prefix}-web-client"
  user_pool_id = aws_cognito_user_pool.main.id

  generate_secret = false

  explicit_auth_flows = [
    "ALLOW_USER_SRP_AUTH",
    "ALLOW_REFRESH_TOKEN_AUTH",
    "ALLOW_USER_PASSWORD_AUTH"
  ]

  access_token_validity  = 1
  id_token_validity      = 1
  refresh_token_validity = 30

  token_validity_units {
    access_token  = "minutes"
    id_token      = "minutes"
    refresh_token = "days"
  }

  prevent_user_existence_errors = "ENABLED"

  allowed_oauth_flows                  = ["code"]
  allowed_oauth_scopes                 = ["email", "openid", "profile"]
  allowed_oauth_flows_user_pool_client = true
  callback_urls                        = var.cognito_callback_urls
  supported_identity_providers = ["COGNITO"]
}

resource "aws_cognito_user_pool_domain" "main" {
  domain       = "${local.prefix}-auth"
  user_pool_id = aws_cognito_user_pool.main.id
}

resource "aws_cognito_user_group" "admins" {
  name         = "Administradores"
  user_pool_id = aws_cognito_user_pool.main.id
  description  = "Grupo de administradores con acceso completo"
  precedence   = 1
}

resource "aws_cognito_user_group" "callcenter" {
  name         = "Operadores CallCenter"
  user_pool_id = aws_cognito_user_pool.main.id
  description  = "Grupo para validadores de rutas"
  precedence   = 2
}

resource "aws_cognito_user_group" "valorizacion" {
  name         = "Operadores Valorizacion"
  user_pool_id = aws_cognito_user_pool.main.id
  description  = "Grupo general de usuarios"
  precedence   = 3
}
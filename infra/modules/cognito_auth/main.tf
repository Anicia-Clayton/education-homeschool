variable "project_name" { type = string }
variable "environment"  { type = string }
variable "mfa"          { type = string  default = "OPTIONAL" } # "ON" for enforced MFA
variable "groups"       { type = list(string) default = [] }

resource "aws_cognito_user_pool" "pool" {
  name = "${var.project_name}-${var.environment}-user-pool"
  mfa_configuration = var.mfa
  software_token_mfa_configuration { enabled = var.mfa != "OFF" }
  password_policy {
    minimum_length    = 12
    require_lowercase = true
    require_numbers   = true
    require_symbols   = true
    require_uppercase = true
  }
}

resource "aws_cognito_user_pool_client" "client" {
  name         = "${var.project_name}-${var.environment}-app"
  user_pool_id = aws_cognito_user_pool.pool.id
  generate_secret = false
  explicit_auth_flows = ["ALLOW_USER_PASSWORD_AUTH","ALLOW_USER_SRP_AUTH","ALLOW_REFRESH_TOKEN_AUTH"]
  supported_identity_providers = ["COGNITO"]
  prevent_user_existence_errors = "ENABLED"
}

resource "aws_cognito_user_group" "groups" {
  for_each = toset(var.groups)
  name     = each.key
  user_pool_id = aws_cognito_user_pool.pool.id
  description  = "Group ${each.key}"
}

output "user_pool_id" { value = aws_cognito_user_pool.pool.id }
output "app_client_id" { value = aws_cognito_user_pool_client.client.id }

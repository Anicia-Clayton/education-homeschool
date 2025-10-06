# Enable a Cognito JWT authorizer and protected routes at /secure/v1/*

data "aws_region" "current" {}

# Authorizer uses outputs from optional Cognito module
locals {
  issuer = "https://cognito-idp.${data.aws_region.current.name}.amazonaws.com/${module.cognito_auth.user_pool_id}"
  audience = [module.cognito_auth.app_client_id]
}

resource "aws_apigatewayv2_authorizer" "jwt" {
  api_id           = module.api.api_id
  authorizer_type  = "JWT"
  identity_sources = ["$request.header.Authorization"]
  name             = "${var.project_name}-${var.environment}-jwt"
  jwt_configuration {
    audience = local.audience
    issuer   = local.issuer
  }
}

# Reuse the same Lambda by creating a new integration
data "aws_lambda_function" "api" { function_name = module.api.lambda_function_name }

resource "aws_apigatewayv2_integration" "secure" {
  api_id                 = module.api.api_id
  integration_type       = "AWS_PROXY"
  integration_uri        = data.aws_lambda_function.api.arn
  payload_format_version = "2.0"
}

resource "aws_apigatewayv2_route" "progress_secure" {
  api_id             = module.api.api_id
  route_key          = "GET /secure/v1/progress"
  target             = "integrations/${aws_apigatewayv2_integration.secure.id}"
  authorizer_id      = aws_apigatewayv2_authorizer.jwt.id
  authorization_type = "JWT"
}

resource "aws_apigatewayv2_route" "tutor_secure" {
  api_id             = module.api.api_id
  route_key          = "POST /secure/v1/tutor-match"
  target             = "integrations/${aws_apigatewayv2_integration.secure.id}"
  authorizer_id      = aws_apigatewayv2_authorizer.jwt.id
  authorization_type = "JWT"
}

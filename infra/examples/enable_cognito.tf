# Optional: add Cognito user pool with groups for parent/student/tutor
module "cognito_auth" {
  source       = "../modules/cognito_auth"
  project_name = var.project_name
  environment  = var.environment
  mfa          = "OPTIONAL"
  groups       = ["parent","student","tutor"]
}
# Next step (not included): add an HTTP API JWT authorizer using this user pool.

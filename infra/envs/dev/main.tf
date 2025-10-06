module "ddb" {
  source       = "../../modules/ddb"
  project_name = var.project_name
  environment  = var.environment
  tags         = var.tags
}
module "api" {
  source       = "../../modules/api"
  project_name = var.project_name
  environment  = var.environment
  tags         = var.tags
}
module "aws_config_baseline" {
  source       = "../../modules/aws_config_baseline"
  project_name = var.project_name
  environment  = var.environment
  tags         = var.tags
}
output "api_base_url"        { value = module.api.api_base_url }
output "config_logs_bucket"  { value = module.aws_config_baseline.config_logs_bucket }

terraform {
  required_version = ">= 1.6.0"
  required_providers { aws = { source = "hashicorp/aws", version = "~> 5.60" } }
  backend "s3" {}
}
provider "aws" { region = var.aws_region }
variable "aws_region"   { type = string }
variable "project_name" { type = string }
variable "environment"  { type = string }
variable "tags"         { type = map(string) default = {} }

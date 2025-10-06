# AWS Config baseline: recorder + delivery + a few managed rules + a small conformance pack
resource "aws_s3_bucket" "config_logs" {
  bucket = "${var.project_name}-${var.environment}-config-logs-${random_id.suffix.hex}"
  tags   = merge(var.tags, { Component = "aws-config-logs" })
}
resource "aws_s3_bucket_versioning" "v" { bucket = aws_s3_bucket.config_logs.id
  versioning_configuration { status = "Enabled" }
}
resource "aws_s3_bucket_public_access_block" "pab" {
  bucket = aws_s3_bucket.config_logs.id
  block_public_acls = true
  block_public_policy = true
  ignore_public_acls = true
  restrict_public_buckets = true
}
resource "aws_s3_bucket_server_side_encryption_configuration" "sse" {
  bucket = aws_s3_bucket.config_logs.id
  rule { apply_server_side_encryption_by_default { sse_algorithm = "AES256" } }
}

resource "random_id" "suffix" { byte_length = 3 }

data "aws_iam_policy_document" "assume_config" {
  statement {
    actions = ["sts:AssumeRole"]
    principals { type = "Service" identifiers = ["config.amazonaws.com"] }
  }
}

resource "aws_iam_role" "config_role" {
  name               = "${var.project_name}-${var.environment}-aws-config-role"
  assume_role_policy = data.aws_iam_policy_document.assume_config.json
  tags               = var.tags
}

resource "aws_iam_role_policy_attachment" "managed" {
  role       = aws_iam_role.config_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSConfigRole"
}

resource "aws_config_configuration_recorder" "rec" {
  name     = "${var.project_name}-${var.environment}-recorder"
  role_arn = aws_iam_role.config_role.arn
  recording_group { all_supported = true }
}

resource "aws_config_delivery_channel" "dc" {
  name           = "${var.project_name}-${var.environment}-delivery"
  s3_bucket_name = aws_s3_bucket.config_logs.bucket
  depends_on     = [aws_config_configuration_recorder.rec]
}

resource "aws_config_configuration_recorder_status" "status" {
  name       = aws_config_configuration_recorder.rec.name
  is_enabled = true
  depends_on = [aws_config_delivery_channel.dc]
}

# A few high-value managed rules (runtime)
resource "aws_config_config_rule" "s3_encryption" {
  name = "${var.project_name}-${var.environment}-s3-bucket-sse"
  source { owner = "AWS" source_identifier = "S3_BUCKET_SERVER_SIDE_ENCRYPTION_ENABLED" }
}
resource "aws_config_config_rule" "ddb_encryption" {
  name = "${var.project_name}-${var.environment}-ddb-kms"
  source { owner = "AWS" source_identifier = "DYNAMODB_TABLE_ENCRYPTION_ENABLED" }
}
resource "aws_config_config_rule" "lambda_public" {
  name = "${var.project_name}-${var.environment}-lambda-no-public"
  source { owner = "AWS" source_identifier = "LAMBDA_FUNCTION_PUBLIC_ACCESS_PROHIBITED" }
}
resource "aws_config_config_rule" "s3_no_public_read" {
  name = "${var.project_name}-${var.environment}-s3-no-public-read"
  source { owner = "AWS" source_identifier = "S3_BUCKET_PUBLIC_READ_PROHIBITED" }
}

# Lightweight conformance pack using a template with some managed rules
resource "aws_config_conformance_pack" "baseline_pack" {
  name          = "${var.project_name}-${var.environment}-baseline-pack"
  template_body = <<EOT
Resources:
  S3Encryption:
    Type: "AWS::Config::ConfigRule"
    Properties:
      ConfigRuleName: "${var.project_name}-${var.environment}-pack-s3-sse"
      Source:
        Owner: "AWS"
        SourceIdentifier: "S3_BUCKET_SERVER_SIDE_ENCRYPTION_ENABLED"
  DDBEncryption:
    Type: "AWS::Config::ConfigRule"
    Properties:
      ConfigRuleName: "${var.project_name}-${var.environment}-pack-ddb-kms"
      Source:
        Owner: "AWS"
        SourceIdentifier: "DYNAMODB_TABLE_ENCRYPTION_ENABLED"
  LambdaNoPublic:
    Type: "AWS::Config::ConfigRule"
    Properties:
      ConfigRuleName: "${var.project_name}-${var.environment}-pack-lambda-no-public"
      Source:
        Owner: "AWS"
        SourceIdentifier: "LAMBDA_FUNCTION_PUBLIC_ACCESS_PROHIBITED"
EOT
  depends_on = [aws_config_configuration_recorder_status.status]
}

output "config_logs_bucket" { value = aws_s3_bucket.config_logs.bucket }

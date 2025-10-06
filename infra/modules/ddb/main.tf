resource "aws_kms_key" "ddb" {
  description = "${var.project_name}-${var.environment}-ddb-kms"
  enable_key_rotation = true
  deletion_window_in_days = 7
  tags = var.tags
}
resource "aws_dynamodb_table" "students" {
  name         = "${var.project_name}-${var.environment}-students"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "student_id"
  server_side_encryption { enabled = true, kms_key_arn = aws_kms_key.ddb.arn }
  attribute { name = "student_id" type = "S" }
  tags = merge(var.tags, { Component = "dynamodb" })
}
output "table_name" { value = aws_dynamodb_table.students.name }
output "arn"        { value = aws_dynamodb_table.students.arn }

output "s3_bucket_domain_name" {
  value       = aws_s3_bucket.default.bucket_domain_name
  description = "S3 bucket domain name"
}

output "s3_bucket_id" {
  value       = aws_s3_bucket.default.id
  description = "S3 bucket ID"
}

output "s3_bucket_arn" {
  value       = aws_s3_bucket.default.arn
  description = "S3 bucket ARN"
}

output "dynamodb_table_name" {
  value       = aws_dynamodb_table.with_server_side_encryption[0].name
  description = "DynamoDB table name"
}

output "dynamodb_table_id" {
  value       = aws_dynamodb_table.with_server_side_encryption[0].id
  description = "DynamoDB table ID"
}

output "dynamodb_table_arn" {
  value       = aws_dynamodb_table.with_server_side_encryption[0].arn
  description = "DynamoDB table ARN"
}


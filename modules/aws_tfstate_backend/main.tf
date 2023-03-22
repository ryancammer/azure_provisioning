locals {
  s3_bucket_label      = "${var.stage}-${var.region}-${var.name}-state"
  dynamodb_table_label = "${var.stage}-${var.region}-${var.name}-state-lock"
}

resource "aws_s3_bucket" "default" {
  bucket        = local.s3_bucket_label
  force_destroy = true
}

resource "aws_dynamodb_table" "with_server_side_encryption" {
  count          = 1
  name           = local.dynamodb_table_label
  read_capacity  = 5
  write_capacity = 5
  hash_key       = "LockID" # https://www.terraform.io/docs/backends/types/s3.html#dynamodb_table

  server_side_encryption {
    enabled = true
  }

  lifecycle {
    ignore_changes = [
      read_capacity,
      write_capacity,
    ]
  }

  attribute {
    name = "LockID"
    type = "S"
  }
}

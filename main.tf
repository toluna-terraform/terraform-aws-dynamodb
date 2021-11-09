locals {
  env_name = var.env_name
  full_name = "dynamodb-${var.table_name}-${local.env_name}"
}

resource "aws_dynamodb_table" "basic-dynamodb-table" {
  name           = local.full_name
  hash_key       = var.primary_key
  range_key      = var.primary_sort_key
  billing_mode   = "PROVISIONED"
  read_capacity  = var.read_capacity
  write_capacity = var.write_capacity

  point_in_time_recovery {
    enabled = true
  }

  attribute {
    name = var.primary_key
    type = var.primary_key_type
  }

  attribute {
    name = var.primary_sort_key
    type = var.primary_sort_key_type
  }

    global_secondary_index {
    name               = var.secondary_index_name
    hash_key           = var.primary_sort_key
    write_capacity     = 5
    read_capacity      = 5
    projection_type    = "ALL"
    
  }

  tags = {
    Name        = local.full_name
    Environment = local.env_name
  }
}


resource "null_resource" "db_backup" {
  count = var.backup_on_destroy ? 1 : 0
  triggers = {
    address = "${aws_dynamodb_table.basic-dynamodb-table.name}",
    backup_file = "${data.template_file.dynamo_backup.rendered}",
  }

  provisioner "local-exec" {
    when       = destroy
    on_failure = fail
    command    = "${path.module}/files/${self.triggers.backup_file}"
  }
  depends_on = [
    aws_dynamodb_table.basic-dynamodb-table, data.template_file.dynamo_backup
  ]
}

## on destroy backup to s3 cli and remove old if exists
## on copy backup to source bucket - restore to target s3 cli
## on restore  restore to target s3 cli
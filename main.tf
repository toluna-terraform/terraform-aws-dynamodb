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
    name = "${aws_dynamodb_table.basic-dynamodb-table.name}",
    backup_file = "${data.template_file.dynamo_backup.rendered}"
  }

  provisioner "local-exec" {
    when       = destroy
    on_failure = fail
    command    = "${path.module}/files/${self.triggers.backup_file}"
  }
  depends_on = [
    aws_dynamodb_table.basic-dynamodb-table,data.template_file.dynamo_backup
  ]
}

resource "null_resource" "db_restore" {
  count = var.restore_on_create ? 1 : 0
  triggers = {
    name = "${aws_dynamodb_table.basic-dynamodb-table.name}"
  }
  provisioner "local-exec" {
    command = "${path.module}/files/${data.template_file.dynamo_restore.rendered}"
  }
  depends_on = [
    aws_dynamodb_table.basic-dynamodb-table,data.template_file.dynamo_restore
  ]
}
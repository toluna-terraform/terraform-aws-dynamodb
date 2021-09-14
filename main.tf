locals {
  full_name = "dynamodb-${var.table_name}-${var.env_name}"
  env_name = split("-", var.env_name)[0]
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
    Environment = var.env_name
  }
}

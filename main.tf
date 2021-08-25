locals {
  full_name = "dynamodb-${var.table_name}-${var.env_name}"
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

  //  dynamic "attribute" {
  //  for_each = var.attributes
  //  content {
  //      name = attribute.key
  //      type = attribute.value
  //  }
  //  }

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
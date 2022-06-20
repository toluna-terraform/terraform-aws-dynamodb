locals {
  env_name = var.env_name
  full_name = "dynamodb-${var.table_name}-${local.env_name}"
}

resource "aws_dynamodb_table" "basic-dynamodb-table" {
  name           = local.full_name
  hash_key       = var.primary_key
  range_key      = var.primary_sort_key
  billing_mode   = var.billing_mode

  read_capacity =  var.billing_mode == "PROVISIONED" ? var.read_capacity :  null
  write_capacity =  var.billing_mode == "PROVISIONED" ? var.write_capacity :  null

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
    read_capacity =  var.billing_mode == "PROVISIONED" ? var.read_capacity :  null
    write_capacity =  var.billing_mode == "PROVISIONED" ? var.write_capacity :  null
    projection_type    = "ALL"
    
  }

  tags = {
    Name        = local.full_name
    Environment = local.env_name
  }
}


resource "aws_appautoscaling_target" "dynamodb_table_read_target" {
  count = var.autoscaling_enabled ? 1 : 0
  max_capacity       = var.max_read_capacity
  min_capacity       = var.read_capacity
  resource_id        = "table/${local.full_name}"
  scalable_dimension = "dynamodb:table:ReadCapacityUnits"
  service_namespace  = "dynamodb"
}

resource "aws_appautoscaling_policy" "dynamodb_table_read_policy" {
  count = var.autoscaling_enabled ? 1 : 0
  name               = "DynamoDBReadCapacityUtilization:${aws_appautoscaling_target.dynamodb_table_read_target[count.index].resource_id}"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.dynamodb_table_read_target[count.index].resource_id
  scalable_dimension = aws_appautoscaling_target.dynamodb_table_read_target[count.index].scalable_dimension
  service_namespace  = aws_appautoscaling_target.dynamodb_table_read_target[count.index].service_namespace

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "DynamoDBReadCapacityUtilization"
    }

    target_value = var.target_utilization_percent
  }
}

resource "aws_appautoscaling_target" "dynamodb_table_write_target" {
  count = var.autoscaling_enabled ? 1 : 0
  max_capacity       = var.max_write_capacity
  min_capacity       = var.write_capacity
  resource_id        = "table/${local.full_name}"
  scalable_dimension = "dynamodb:table:WriteCapacityUnits"
  service_namespace  = "dynamodb"
}

resource "aws_appautoscaling_policy" "dynamodb_table_write_policy" {
  count = var.autoscaling_enabled ? 1 : 0
  name               = "DynamoDBWriteCapacityUtilization:${aws_appautoscaling_target.dynamodb_table_write_target[count.index].resource_id}"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.dynamodb_table_write_target[count.index].resource_id
  scalable_dimension = aws_appautoscaling_target.dynamodb_table_write_target[count.index].scalable_dimension
  service_namespace  = aws_appautoscaling_target.dynamodb_table_write_target[count.index].service_namespace

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "DynamoDBWriteCapacityUtilization"
    }

    target_value = var.target_utilization_percent
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
    aws_dynamodb_table.basic-dynamodb-table,data.template_file.dynamo_restore,aws_appautoscaling_policy.dynamodb_table_write_policy,aws_appautoscaling_policy.dynamodb_table_read_policy
  ]
}
locals {
  env_name = var.env_name

  # at different places, scripts are using app_name instead of table_name, 
  # and expect user to give same value for app_name and table_name.
  # Until code is refactored to use table_name appropriately, we will use app_name
  # in all places, and ignore table_name variable, to avoid issues

  table_name = try("${var.table_name}","dynamodb-${var.app_name}-${local.env_name}")
}

resource "aws_dynamodb_table" "basic-dynamodb-table" {
  name           = local.table_name
  hash_key       = var.primary_key
  range_key      = var.primary_sort_key
  billing_mode   = var.billing_mode

  read_capacity =  var.billing_mode == "PROVISIONED" ? var.read_capacity :  null
  write_capacity =  var.billing_mode == "PROVISIONED" ? var.write_capacity :  null

  attribute {
    name = var.primary_key
    type = var.primary_key_type
  }

  dynamic "attribute" {
     for_each = var.primary_sort_key != null ? [1] : []
     iterator = index
     content {
      name = var.primary_sort_key
      type = var.primary_sort_key_type
    }
  }

  dynamic "attribute" {
    for_each = var.global_secondary_indeces
    iterator = index
    content {
      name = index.value.hash_key
      type = index.value.hash_key_type
    }
  }

  dynamic "attribute" {
    for_each = [
      for i in var.global_secondary_indeces : i
      if can(i.range_key)
    ]
    iterator = index
    content {
      name = index.value.range_key
      type = index.value.range_key_type
    }
  }

  dynamic "global_secondary_index" {
    for_each = var.global_secondary_indeces
    iterator = index
    content {
      name = index.value.name
      hash_key = index.value.hash_key
      range_key = try(index.value.range_key, null)
      read_capacity =  var.billing_mode == "PROVISIONED" ? var.read_capacity :  null
      write_capacity =  var.billing_mode == "PROVISIONED" ? var.write_capacity :  null
      projection_type    = "ALL"
    }
  }
  
  ttl {
    attribute_name = var.ttl_attribute_name
    enabled        = var.ttl_value
  }

  tags = {
    Name        = local.table_name
    Environment = local.env_name
  }
}


resource "aws_appautoscaling_target" "dynamodb_table_read_target" {
  count = var.autoscaling_enabled ? 1 : 0
  max_capacity       = var.max_read_capacity
  min_capacity       = var.read_capacity
  resource_id        = "table/${local.table_name}"
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
  resource_id        = "table/${local.table_name}"
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
    when    = create
    command = "${path.module}/files/${data.template_file.dynamo_restore.rendered}"
  }
  depends_on = [
    aws_dynamodb_table.basic-dynamodb-table,data.template_file.dynamo_restore,aws_appautoscaling_policy.dynamodb_table_write_policy,aws_appautoscaling_policy.dynamodb_table_read_policy
  ]
}

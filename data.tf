data "aws_s3_bucket_objects" "get_dump_list" {
  bucket = "${local.app_name}-${local.env_type}-dynamodb-dumps"
  prefix = "${local.env_name}/dynamodb-${local.app_name}-${local.env_name}.json"
}



data "template_file" "dynamo_backup" {
  template = "${file("${path.module}/files/dynamo_backup.tpl")}"
  vars = {
    SERVICE_NAME="${local.app_name}"
    WORKSPACE="${local.env_name}"
    ENV_TYPE="${local.env_type}"
    AWS_PROFILE="${local.aws_profile}"
    TABLE_NAME="${local.table_name}"
  }
  depends_on = [
    aws_dynamodb_table.basic-dynamodb-table
  ]
}

data "template_file" "dynamo_restore" {
  template = "${file("${path.module}/files/dynamo_restore.tpl")}"
  vars = {
    SERVICE_NAME="${local.app_name}"
    WORKSPACE="${local.env_name}"
    ENV_TYPE="${local.env_type}"
    AWS_PROFILE="${local.aws_profile}"
    INIT_DB_ENVIRONMENT="${var.init_db_environment}"
    SOURCE_AWS_PROFILE="${var.init_db_aws_profile}"
    SOURCE_ENV_TYPE="${var.init_db_env_type}"
    TABLE_NAME="${local.table_name}"
  }
  depends_on = [
    aws_dynamodb_table.basic-dynamodb-table
  ]
}


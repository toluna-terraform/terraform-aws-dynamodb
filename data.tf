data "aws_s3_bucket_objects" "get_dump_list" {
  bucket = "${var.app_name}-${var.env_type}-dynamodb-dumps"
  prefix = "${var.env_name}/dynamodb-${var.app_name}-${var.env_name}.json"
}

data "aws_s3_bucket_object" "get_dump_data" {
  count  = length(data.aws_s3_bucket_objects.get_dump_list.keys)
  bucket = data.aws_s3_bucket_objects.get_dump_list.bucket
  key    = data.aws_s3_bucket_objects.get_dump_list.keys[0]
    depends_on = [
    data.aws_s3_bucket_objects.get_dump_list
  ]
}

data "template_file" "dynamo_backup" {
  template = "${file("${path.module}/files/dynamo_backup.tpl")}"
  vars = {
    SERVICE_NAME="${var.app_name}"
    WORKSPACE="${var.env_name}"
    ENV_TYPE="${var.env_type}"
    AWS_PROFILE="${var.aws_profile}"
    TABLE_NAME="${local.table_name}"
  }
  depends_on = [
    aws_dynamodb_table.basic-dynamodb-table
  ]
}

data "template_file" "dynamo_restore" {
  template = "${file("${path.module}/files/dynamo_restore.tpl")}"
  vars = {
    SERVICE_NAME="${var.app_name}"
    WORKSPACE="${var.env_name}"
    ENV_TYPE="${var.env_type}"
    AWS_PROFILE="${var.aws_profile}"
    INIT_DB_ENVIRONMENT="${var.init_db_environment}"
    SOURCE_AWS_PROFILE="${var.init_db_aws_profile}"
    SOURCE_ENV_TYPE="${var.init_db_env_type}"
    TABLE_NAME="${local.table_name}"
  }
  depends_on = [
    aws_dynamodb_table.basic-dynamodb-table
  ]
}


data "template_file" "dynamo_backup" {
  template = "${file("${path.module}/files/dynamo_backup.tpl")}"
  vars = {
    SERVICE_NAME="${var.app_name}"
    WORKSPACE="${var.env_name}"
    ENV_TYPE="${var.env_type}"
    AWS_PROFILE="${var.aws_profile}"
    TABLE_ARN="${aws_dynamodb_table.basic-dynamodb-table.arn}"

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
    TABLE_ARN="${aws_dynamodb_table.basic-dynamodb-table.arn}"
    INIT_DB_ENVIRONMENT="${var.init_db_environment}"
    SOURCE_AWS_PROFILE="${var.init_db_aws_profile}"
    SOURCE_ENV_TYPE="${var.init_db_env_type}"
  }
  depends_on = [
    aws_dynamodb_table.basic-dynamodb-table
  ]
}
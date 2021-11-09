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

  }
  depends_on = [
    aws_dynamodb_table.basic-dynamodb-table
  ]
}
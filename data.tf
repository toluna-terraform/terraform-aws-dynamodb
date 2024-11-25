data "aws_s3_objects" "get_dump_list" {
  bucket = "${var.app_name}-${var.env_type}-dynamodb-dumps"
  prefix = "${var.env_name}/dynamodb-${var.app_name}-${var.env_name}.json"
}
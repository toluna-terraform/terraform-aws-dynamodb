module "dynamodb" {
  source                = "../../"
  version               = "~>0.0.1" // Change to the required version.
  env_name                   = local.environment
  table_name                 = "quota-service"
  primary_key                = "TemplateId"
  primary_key_type           = "S"
  primary_sort_key           = "Entity"
  primary_sort_key_type      = "N"
  secondary_index_name       = "Entity-index"
  read_capacity              = local.read_capacity
  write_capacity             = local.write_capacity
  max_read_capacity          = local.max_read_capacity
  max_write_capacity         = local.max_write_capacity
  autoscaling_enabled        = local.autoscaling_enabled
  target_utilization_percent = local.target_utilization_percent
  backup_on_destroy          = true
  restore_on_create          = true
  aws_profile                = local.aws_profile
  env_type                   = local.env_type
  app_name                   = local.app_name
  init_db_environment        = local.init_db_environment
  init_db_aws_profile        = local.init_db_aws_profile
  init_db_env_type           = local.init_db_env_type
}
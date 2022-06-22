module "dynamodb" {
  source                = "../../"

  aws_profile                = var.aws_profile
  app_name                   = var.app_name
  env_name                   = var.env_name
  env_type                   = var.env_type

  # currently only app_name used instead of table_name in scripts
  # this needs to be changed after module code is refactored
  table_name                 = var.app_name
  primary_key                = "mobile"
  primary_key_type           = "S"
  primary_sort_key           = "first_name"
  primary_sort_key_type      = "S"
  secondary_index_name       = "sec_index"

  read_capacity              = var.read_capacity
  write_capacity             = var.write_capacity

  # max_read_capacity          = local.max_read_capacity
  # max_write_capacity         = local.max_write_capacity
  # autoscaling_enabled        = local.autoscaling_enabled
  # target_utilization_percent = local.target_utilization_percent

  backup_on_destroy          = true
  restore_on_create          = true

  # init_db_environment        = local.init_db_environment
  # init_db_aws_profile        = local.init_db_aws_profile
  # init_db_env_type           = local.init_db_env_type
}

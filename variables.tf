variable "env_name" {
  type = string
}

variable "app_name" {
  type = string
}

variable "table_name" {
  type = string
}

variable "primary_key"{
    type = string
}

variable "primary_key_type"{
    type = string
}

variable "primary_sort_key" {
  type = string
  default = null
}

variable "primary_sort_key_type" {
  default = null
}

variable "read_capacity" {
  default = 10
}

variable "write_capacity" {
  default = 10
}

variable "env_type" {
  type = string
}

variable "aws_profile" {
  type = string
}

variable "backup_on_destroy" {
  type        = bool
  default     = true
  description = "Backup DB to S3"
}

variable "restore_on_create" {
  type        = bool
  default     = true
  description = "Restore DB from dump file"
}

variable "init_db_environment" {
  default     = "NULL"
  description = "Source envirnment name to restore db from"
} 

variable "init_db_aws_profile" {
  default     = "NULL"
  description = "Source envirnment aws profile to restore db from"
} 

variable "init_db_env_type" {
  default     = "NULL"
  description = "Source envirnment aws profile to restore db from"
} 

variable "target_utilization_percent" {
  default     = 70
  description = "Target utilization for read/write autoscaling capacity"
}

variable "max_write_capacity" {
  default     = 100
  description = "Maximum write autoscaling capacity"
}

variable "max_read_capacity" {
  default     = 100
  description = "Maximum read autoscaling capacity"
}

variable "autoscaling_enabled" {
  default     = false
  description = "Use autoscaling for read/write capacity"
}

variable "billing_mode" {
  type        = string
  description = "Indicates mode of billing. Value should be either PROVISIONED or PAY_PER_REQUEST"
  default     = "PROVISIONED"
}

variable "global_secondary_indeces" {
  type        = any
  description = "Array of GSI definitions"
  default     = []
}

variable "indeces_table_target_utilization_percent" {
  type        = number
  default     = 70
  description = "Target utilization for read/write autoscaling capacity"
}

variable "index_read_capacity" {
  type        = number
  description = "Index read autoscaling capacity"
  default     = 10
}

variable "index_read_max_capacity" {
  type        = number
  default     = 100
  description = "Index max read autoscaling capacity"
}

variable "index_read_min_capacity" {
  type        = number
  default     = 5
  description = "Index min read autoscaling capacity"
}

variable "index_write_capacity" {
  type        = number
  description = "Index write autoscaling capacity"
  default     = 10
}

variable "index_write_max_capacity" {
  type        = number
  default     = 100
  description = "Index max write autoscaling capacity"
}

variable "index_write_min_capacity" {
  type        = number
  default     = 5
  description = "Index min write autoscaling capacity"
}

variable "ttl_attribute_name" {
  type    = string
  default = null
}
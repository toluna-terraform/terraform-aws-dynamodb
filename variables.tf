variable "env_name" {
  default = "trn"
}

variable "table_name" {
  type = string
  default = "ServiceQuotas"
}

variable "primary_key"{
    type = string
    default = "TemplateId"
}

variable "primary_key_type"{
    type = string
    default = "S"
}

variable "primary_sort_key" {
  default = "Entity"
}

variable "primary_sort_key_type" {
  type = string
  default = "N"
}

variable "secondary_index_name" {
  type = string
  default = "Entity-index"
}

variable "read_capacity" {
  default = 5
}


variable "write_capacity" {
  default = 5
}

variable "attributes" {
    default = {"TemplateName" = "S","CustomerId" = "N"}
}


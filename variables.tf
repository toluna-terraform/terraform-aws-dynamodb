variable "env_name" {
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
}

variable "primary_sort_key_type" {
  type = string
}

variable "secondary_index_name" {
  type = string
}

variable "read_capacity" {
  default = 5
}


variable "write_capacity" {
  default = 5
}

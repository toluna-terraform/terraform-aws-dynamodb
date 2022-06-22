variable "aws_profile" {
    type = string
}

variable "app_name" {
    type = string
}

variable "env_name" {
    type = string
}

variable "env_type" {
    type = string
}

variable "read_capacity" {
    type = number
    default = 5
}

variable "write_capacity" {
    type = number
    default = 5
}
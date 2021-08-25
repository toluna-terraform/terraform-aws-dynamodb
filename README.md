# terraform-aws-dynamodb
Toluna [Terraform module](https://registry.terraform.io/modules/toluna-terraform/dynamodb/aws/latest), which creates AWS DynamoDB table.

## Usage
```
module "dynamodb" {
  source                = "toluna-terraform/dynamodb/aws"
  version               = "~>0.0.1" // Change to the required version.
  env_name              = local.environment
  table_name            = "ServiceQuotas"
  primary_key           = "TemplateId"
  primary_key_type      = "S"
  primary_sort_key      = "Entity"
  primary_sort_key_type = "N"
  secondary_index_name  = "Entity-index"
  read_capacity         = 5
  write_capacity        = 5
}
```
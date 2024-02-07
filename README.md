# terraform-aws-dynamodb
Toluna [Terraform module](https://registry.terraform.io/modules/toluna-terraform/dynamodb/aws/latest), which creates AWS DynamoDB table.

## Description
This module supports persistency of DynamoDB, by creating/restoring dump files(json) to AWS s3 bucket, this is done by running a shell script upon apply and before destroy, the shell script starts an AWS Cli command to output the entire table to a json file, upon destroy and read the json file on create.

The module also supports starting with a copy of the DB from another created environment (I.E. you can start a "DEV" environment with a copy of "QA" DB that resides on the same AWS account).
The creation of dump files and restore/copy functions are triggered by terraform events (apply/destroy) based on the DynamoDB Table resource.

\* **an environment equals in it's name to the Terraform workspace it runs under so when referring to an environment or workspace throughout this document their value is actually the same.**



The following resources will be created:
- DynamoDB Table
- **If you intend to copy a db from another workspace you first must use this module to created the source DB**
- Upon destroy if DynamoDB dumps bucket does not exist it will be created

## Requirements
None.

### Example Usage
```
module "dynamodb" {
  source                = "toluna-terraform/dynamodb/aws"
  version               = "~>1.1.0" 
  aws_profile                = local.aws_profile
  app_name                   = local.app_name
  env_type                   = local.env_type
  env_name                   = local.environment

  table_name                 = "quota-service"
  primary_key                = "TemplateId"
  primary_key_type           = "S"
  primary_sort_key           = "Entity"
  primary_sort_key_type      = "N"

  billing_mode               = "PROVISONED"
  read_capacity              = local.read_capacity
  write_capacity             = local.write_capacity
  max_read_capacity          = local.max_read_capacity
  max_write_capacity         = local.max_write_capacity
  autoscaling_enabled        = local.autoscaling_enabled
  target_utilization_percent = local.target_utilization_percent

  backup_on_destroy          = true
  restore_on_create          = true

  init_db_environment        = local.init_db_environment
  init_db_aws_profile        = local.init_db_aws_profile
  init_db_env_type           = local.init_db_env_type

  ttl_attribute_name         = "created_at"

  global_secondary_indeces   = [
    {
      name           = "Entity-TemplateId-index"
      hash_key       = "Entity"
      hash_key_type  = "N"
      range_key      = "TemplateId"
      range_key_type = "S"
    },
    {
      name           = "CustomerId-TemplateId-index"
      hash_key       = "CustomerId"
      hash_key_type  = "N"
      range_key      = "TemplateId"
      range_key_type = "S"
      projection_type = "KEYS_ONLY"
    },
    {
      name           = "UserId-TemplateId-index"
      hash_key       = "UserId"
      hash_key_type  = "N"
      range_key      = "TemplateId"
      range_key_type = "S"
      projection_type = "INCLUDE"
      non_key_attributes = [ "CreateDate", "Entity" ]
    }
  ]
}
```
## Important notes.
By providing `ttl_attribute_name` you enabling the TTL on you dynamodb table.<br>
FYI this option have some limitation set by AWS:<br>
* Once you set `ttl_attribute_name` attribute you cannot immediatly change it to other value you will need to wait around one hour.
* If you will remove `ttl_attribute_name` attribute from your `dynamodb.tf` it will not turn off the TTL on your table.

For more information visit [this](https://github.com/hashicorp/terraform-provider-aws/issues/10304) opened bug.<br>
## Parameters
`billing_mode = PROVISIONED | PAY_PER_REQUEST`

PROVISIONED is for custom provisioning. PAY_PER_REQUEST is for on-demand provisioning. 

certain parameters like read_capacity, etc., are applicable only for PROVISIONED billing_mode

### Toggles
#### Backup, Restore and Initial DB flags:
```yaml
backup_on_destroy     = boolean (true/false) default = true
restore_on_create     = boolean (true/false) default = true

init_db_environment   = string the name of the source environment to copy db from
autoscaling_enabled   =  to use autoscaling for DB read/write capacity 
```

if restore_on_create = true the following flow is used:
```flow
                                             ┌────────────────────────┐
                                             │ Is s3 dump file found  │
                                             └───────────┬────────────┘
                                                         │
                                 ┌────────┐              │              ┌─────────┐
                                 │   NO   │ ◄────────────┴─────────────►│   YES   │
                                 └───┬────┘                             └────┬────┘
                                     │                                       │
                                     ▼                                       ▼
                      ┌───────────────────────────────┐        ┌──────────────────────────┐
                      │ Is initial DB Environment set │        │Restore from s3 dump file │
                      └───────────────┬───────────────┘        └──────────────────────────┘
                                      │
           ┌────────┐                 │           ┌─────────┐
           │   NO   │ ◄───────────────┴──────────►│   YES   │
           └───┬────┘                             └────┬────┘
               │                                       │
               ▼                                       ▼
      ┌────────────────┐            ┌─────────────────────────────────────┐
      │ Start empty DB │            │ Restore from initial DB Environment │
      └────────────────┘            └─────────────────────────────────────┘
```
- **To force initialization from another environment DB you must remove the dump file of your target environment from s3 and set the init_db_environment variable to the name of the source environment you want to copy the db from.**
- **If backup_on_destroy = true, each time the DynamoDB Table is destroyed (including force update - force replace), a dump will be created and uploaded to s3, so if "force replace" is done the DB restored will be from latest point before update.**
- **To force a replacement of DynamoDB Table you can run terraform taint <module.dynamodb>**

## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.0.0 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 3.59 |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="dynamodb"></a> [dynamodb](#module\_dynamodb) | ../../ |  |

## Resources

| Name | Type |
|------|------|
| [aws_dynamodb_table](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/dynamodb_table) | resource |
| [null_resource](https://registry.terraform.io/providers/hashicorp/null/latest/docs/resources/resource) | resource |


## Inputs

No inputs.

## Outputs
| Name | Value |
|------|-------|
| s3_dump_file | Details about the dump file created |

<!-- BEGIN_TF_DOCS -->
## Requirements

No requirements.

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | n/a |
| <a name="provider_null"></a> [null](#provider\_null) | n/a |
| <a name="provider_template"></a> [template](#provider\_template) | n/a |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [aws_appautoscaling_policy.dynamodb_table_read_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/appautoscaling_policy) | resource |
| [aws_appautoscaling_policy.dynamodb_table_write_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/appautoscaling_policy) | resource |
| [aws_appautoscaling_target.dynamodb_table_read_target](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/appautoscaling_target) | resource |
| [aws_appautoscaling_target.dynamodb_table_write_target](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/appautoscaling_target) | resource |
| [aws_dynamodb_table.basic-dynamodb-table](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/dynamodb_table) | resource |
| [null_resource.db_backup](https://registry.terraform.io/providers/hashicorp/null/latest/docs/resources/resource) | resource |
| [null_resource.db_restore](https://registry.terraform.io/providers/hashicorp/null/latest/docs/resources/resource) | resource |
| [aws_s3_bucket_objects.get_dump_list](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/s3_bucket_objects) | data source |
| [template_file.dynamo_backup](https://registry.terraform.io/providers/hashicorp/template/latest/docs/data-sources/file) | data source |
| [template_file.dynamo_restore](https://registry.terraform.io/providers/hashicorp/template/latest/docs/data-sources/file) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_app_name"></a> [app\_name](#input\_app\_name) | n/a | `string` | `null` | no |
| <a name="input_autoscaling_enabled"></a> [autoscaling\_enabled](#input\_autoscaling\_enabled) | Use autoscaling for read/write capacity | `bool` | `false` | no |
| <a name="input_aws_profile"></a> [aws\_profile](#input\_aws\_profile) | n/a | `string` | `null` | no |
| <a name="input_backup_on_destroy"></a> [backup\_on\_destroy](#input\_backup\_on\_destroy) | Backup DB to S3 | `bool` | `true` | no |
| <a name="input_billing_mode"></a> [billing\_mode](#input\_billing\_mode) | Indicates mode of billing. Value should be either PROVISIONED or PAY\_PER\_REQUEST | `string` | `"PROVISIONED"` | no |
| <a name="input_dynamodb_config"></a> [dynamodb\_config](#input\_dynamodb\_config) | n/a | `any` | n/a | yes |
| <a name="input_env_name"></a> [env\_name](#input\_env\_name) | n/a | `string` | `null` | no |
| <a name="input_env_type"></a> [env\_type](#input\_env\_type) | n/a | `string` | `null` | no |
| <a name="input_global_secondary_indeces"></a> [global\_secondary\_indeces](#input\_global\_secondary\_indeces) | Array of GSI definitions | `any` | `[]` | no |
| <a name="input_init_db_aws_profile"></a> [init\_db\_aws\_profile](#input\_init\_db\_aws\_profile) | Source envirnment aws profile to restore db from | `string` | `"NULL"` | no |
| <a name="input_init_db_env_type"></a> [init\_db\_env\_type](#input\_init\_db\_env\_type) | Source envirnment aws profile to restore db from | `string` | `"NULL"` | no |
| <a name="input_init_db_environment"></a> [init\_db\_environment](#input\_init\_db\_environment) | Source envirnment name to restore db from | `string` | `"NULL"` | no |
| <a name="input_max_read_capacity"></a> [max\_read\_capacity](#input\_max\_read\_capacity) | Maximum read autoscaling capacity | `number` | `20` | no |
| <a name="input_max_write_capacity"></a> [max\_write\_capacity](#input\_max\_write\_capacity) | Maximum write autoscaling capacity | `number` | `20` | no |
| <a name="input_primary_key"></a> [primary\_key](#input\_primary\_key) | n/a | `string` | n/a | yes |
| <a name="input_primary_key_type"></a> [primary\_key\_type](#input\_primary\_key\_type) | n/a | `string` | n/a | yes |
| <a name="input_primary_sort_key"></a> [primary\_sort\_key](#input\_primary\_sort\_key) | n/a | `string` | `null` | no |
| <a name="input_primary_sort_key_type"></a> [primary\_sort\_key\_type](#input\_primary\_sort\_key\_type) | n/a | `any` | `null` | no |
| <a name="input_read_capacity"></a> [read\_capacity](#input\_read\_capacity) | n/a | `number` | `5` | no |
| <a name="input_restore_on_create"></a> [restore\_on\_create](#input\_restore\_on\_create) | Restore DB from dump file | `bool` | `true` | no |
| <a name="input_table_name"></a> [table\_name](#input\_table\_name) | n/a | `string` | n/a | yes |
| <a name="input_target_utilization_percent"></a> [target\_utilization\_percent](#input\_target\_utilization\_percent) | Target utilization for read/write autoscaling capacity | `number` | `70` | no |
| <a name="input_ttl_attribute_name"></a> [ttl\_attribute\_name](#input\_ttl\_attribute\_name) | n/a | `string` | `null` | no |
| <a name="input_write_capacity"></a> [write\_capacity](#input\_write\_capacity) | n/a | `number` | `5` | no |

## Outputs

No outputs.
<!-- END_TF_DOCS -->
# terraform-aws-dynamodb
Toluna [Terraform module](https://registry.terraform.io/modules/toluna-terraform/dynamodb/aws/latest), which creates AWS DynamoDB table.

### Description
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

## Usage
```
module "dynamodb" {
  source                = "toluna-terraform/dynamodb/aws"
  version               = "~>0.0.1" // Change to the required version.
  env_name                   = local.environment
  table_name                 = "quota-service"
  primary_key                = "TemplateId"
  primary_key_type           = "S"
  primary_sort_key           = "Entity"
  primary_sort_key_type      = "N"
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

## Toggles
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

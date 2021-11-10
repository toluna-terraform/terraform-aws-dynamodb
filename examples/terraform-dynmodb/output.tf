output "s3_dump_file" {
    value = try("${module.dynamodb.s3_dump_file[0].id}:${module.dynamodb.s3_dump_file[0].last_modified}","{}")
}
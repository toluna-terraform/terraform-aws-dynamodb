output "s3_dump_file" {
    value = "${data.aws_s3_bucket_object.get_dump_data}"
}

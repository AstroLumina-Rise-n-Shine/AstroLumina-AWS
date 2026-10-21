output "bucket_id" {
  description = "Name of the bucket (S3 emits the name as the resource ID)"
  value       = module.s3_bucket.bucket_id
}

output "bucket_arn" {
  description = "ARN of the bucket"
  value       = module.s3_bucket.bucket_arn
}

output "object_key" {
  description = "Key of the uploaded object"
  value       = aws_s3_object.hello.key
}

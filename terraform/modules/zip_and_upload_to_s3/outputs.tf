output "s3_object_key" {
  description = "The key of the uploaded S3 object"
  value       = aws_s3_object.zip_upload.key
}

output "s3_object_etag" {
  description = "The ETag of the uploaded S3 object"
  value       = aws_s3_object.zip_upload.etag
}

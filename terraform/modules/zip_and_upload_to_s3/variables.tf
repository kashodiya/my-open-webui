variable "bucket_name" {
  description = "Name of the S3 bucket"
  type        = string
}

variable "folder_name" {
  description = "Name of the folder in S3 bucket"
  type        = string
}

variable "source_dir" {
  description = "Path to the directory to be zipped"
  type        = string
}

variable "output_filename" {
  description = "Name of the output zip file"
  type        = string
}
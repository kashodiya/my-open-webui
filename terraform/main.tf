variable "region" {}
# variable "public_key_file_path" {}
variable "allowed_source_ips" {}
# variable "vpc_id" {}
# variable "subnet_cidr" {}
variable "project_id" {}
variable "ami" {}
variable "instance_type" {}
variable "availability_zone" {}
variable "create_gpu_instance" {}

variable "jupyter_lab_token" {
  type        = string
  description = "Token for Jupyter Lab"
  sensitive   = true  # Changed to true for security
  validation {
    condition     = length(var.jupyter_lab_token) >= 8
    error_message = "The token for Jupyter Lab must be at least 8 characters long."
  }
}

variable "litellm_api_key" {
  type        = string
  description = "Key for LiteLLM"
  sensitive   = true  # Changed to true for security
  validation {
    condition     = length(var.litellm_api_key) >= 8
    error_message = "The LiteLLm API key must be at least 8 characters long."
  }
}

variable "code_server_password" {
  type        = string
  description = "Password for code-server"
  sensitive   = true  # Changed to true for security
  validation {
    condition     = length(var.code_server_password) >= 8
    error_message = "The code-server password password must be at least 8 characters long."
  }
}


variable "controller_auth_key" {
  type        = string
  description = "Key for Controller"
  sensitive   = true  # Changed to true for security
  validation {
    condition     = length(var.controller_auth_key) >= 8
    error_message = "The key for Controller must be at least 8 characters long."
  }
}


variable "bedrock_gateway_api_key" {
  type        = string
  description = "Key for Bedrock Gateway"
  sensitive   = true  # Changed to true for security
  validation {
    condition     = length(var.bedrock_gateway_api_key) >= 8
    error_message = "The key for Bedrock Gateway must be at least 8 characters long."
  }
}


variable "server_tool_password" {
  type        = string
  description = "Server Tool password"
  sensitive   = true  # Changed to true for security
  validation {
    condition     = length(var.server_tool_password) >= 8
    error_message = "The password for Server Tool must be at least 8 characters long."
  }
}

provider "aws" {
  region = var.region
}

data "aws_region" "current" {}
data "aws_caller_identity" "current" {}
data "aws_availability_zones" "available" {}

# data "aws_internet_gateway" "main" {
#   filter {
#     name   = "attachment.vpc-id"
#     values = [aws_vpc.main.id]
#   }
# }


# Create a VPC
resource "aws_vpc" "main" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "${var.project_id}-main-vpc"
  }
}

# Create a public subnet
resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.1.0/24"
  map_public_ip_on_launch = true
  availability_zone       = var.availability_zone

  tags = {
    Name = "${var.project_id}-public-subnet"
  }
}

# Create an Internet Gateway
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${var.project_id}-main-igw"
  }
}


data "http" "my_public_ip" {
  url = "https://api.ipify.org"

  # Optional: add a custom request header
  request_headers = {
    Accept = "application/text"
  }
}

# resource "aws_subnet" "public" {
#   vpc_id                  = aws_vpc.main.id
#   cidr_block              = var.subnet_cidr
#   availability_zone       = var.availability_zone
#   map_public_ip_on_launch = false
#   tags = {
#     Name      = "${var.project_id}"
#     CreatedBy = "terraform"
#   }
# }

# resource "aws_route_table" "public_rt" {
#   vpc_id = aws_vpc.main.id

#   route {
#     cidr_block = "0.0.0.0/0"
#     gateway_id = data.aws_internet_gateway.main.id
#   }
#   tags = {
#     Name      = "${var.project_id}"
#     CreatedBy = "terraform"
#   }
# }

# Create a route table
resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = {
    Name = "public-route-table"
  }
}

# Associate the public subnet with the route table
resource "aws_route_table_association" "public_assoc" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public_rt.id
}

# Add my laptop public facing ip to the allowed_source_ips
locals {
  my_ip = "${chomp(data.http.my_public_ip.response_body)}/32"
  all_allowed_ips = concat(var.allowed_source_ips, [local.my_ip])
}

resource "aws_security_group" "allow_sources" {
  name        = "${var.project_id}_allow_sources"
  description = "Allow SSH, Jupyter inbound traffic"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "SSH from VPC"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = local.all_allowed_ips
  }

  ingress {
    # Do not change this description, it is used in controller lambda
    description = "main-range"  
    from_port   = 7000
    to_port     = 7999
    protocol    = "tcp"
    cidr_blocks = local.all_allowed_ips
  }

  # ingress {
  #   description     = "Allow ingress from controller lambda security group"
  #   from_port       = 0
  #   to_port         = 65535
  #   protocol        = "tcp"
  #   security_groups = [aws_security_group.controller_lambda_sg.id]
  # }

  # ingress {
  #   # Do not change this description, it is used in controller lambda
  #   description = "main-range"
  #   from_port   = 0
  #   to_port     = 65535
  #   protocol    = "tcp"
  #   cidr_blocks = local.all_allowed_ips
  # }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name      = "${var.project_id}_allow_sources"
    CreatedBy = "terraform"
  }
}

resource "aws_iam_role" "dev_role" {
  name = "${var.project_id}_dev_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = [
            "ec2.amazonaws.com",
            "lambda.amazonaws.com"
          ]
      }
      Action = "sts:AssumeRole"
    }]
  })

  tags = {
    Name      = "${var.project_id}_dev_role"
    CreatedBy = "terraform"
  }
}

resource "aws_iam_policy" "dev_role_policy" {
  name        = "${var.project_id}_dev_role_policy"
  description = "Policy for Dev access"

  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Effect" : "Allow",
        "Action" : "*",
        "Resource" : "*"
      }
    ]
  })
  tags = {
    Name      = "${var.project_id}_dev_role_policy"
    CreatedBy = "terraform"
  }
}

resource "aws_iam_role_policy_attachment" "attach_dev_role_policy" {
  policy_arn = aws_iam_policy.dev_role_policy.arn
  role       = aws_iam_role.dev_role.name
}

resource "aws_iam_instance_profile" "instance_profile" {
  name = "${var.project_id}-instance-profile"
  role = aws_iam_role.dev_role.name
  tags = {
    Name      = "${var.project_id}-instance-profile"
    CreatedBy = "terraform"
  }
}


# Generate a new private key
resource "tls_private_key" "this" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

# Create local files for the private and public keys
resource "local_file" "private_key" {
  content  = tls_private_key.this.private_key_pem
  filename = "..\\keys\\private_key.pem"
}

resource "local_file" "public_key" {
  content  = tls_private_key.this.public_key_openssh
  filename = "..\\keys\\public_key.pub"
}

resource "aws_key_pair" "main_key" {
  key_name   = "${var.project_id}_key_pair"  # Change this to your desired key pair name
  public_key = tls_private_key.this.public_key_openssh
  tags = {
    Name      = "${var.project_id}_key_pair"
    CreatedBy = "terraform"
  }
}

# data "archive_file" "code_zip" {
#   type        = "zip"
#   output_path = "${path.module}/../code.zip"

#   source {
#     content  = "${path.module}/../caddy"
#     filename = "caddy"
#   }
#   source {
#     content  = "${path.module}/../docker"
#     filename = "docker"
#   }
#   source {
#     content  = "${path.module}/../scripts"
#     filename = "scripts"
#   }
#   source {
#     content  = "${path.module}/../ec2-setup"
#     filename = "ec2-setup"
#   }

# }

# # Upload the zip content directly to the S3 bucket
# resource "aws_s3_object" "code_zip_upload" {
#   bucket  = aws_s3_bucket.data_bucket.id
#   key     = "code.zip"
#   content_type = "application/zip"
#   source = data.archive_file.code_zip.output_path

#   # Ensure the object is re-uploaded if the zip content changes
#   etag = data.archive_file.caddy_zip.output_md5
# }

# # Create an in-memory zip archive
# data "archive_file" "caddy_zip" {
#   type        = "zip"
#   source_dir  = local.caddy_folder
#   output_path = "${path.module}/../caddy.zip"
# }

# # Upload the zip content directly to the S3 bucket
# resource "aws_s3_object" "caddy_zip_upload" {
#   bucket  = aws_s3_bucket.data_bucket.id
#   key     = "caddy.zip"
#   # content = data.archive_file.caddy_zip.output_base64sha256  # This is the in-memory zip content
#   content_type = "application/zip"
#   source = data.archive_file.caddy_zip.output_path

#   # Ensure the object is re-uploaded if the zip content changes
#   etag = data.archive_file.caddy_zip.output_md5
# }


module "caddy_zip_upload" {
  source          = "./modules/zip_and_upload_to_s3"
  bucket_name     = aws_s3_bucket.data_bucket.id
  folder_name     = "caddy"
  source_dir      = "${path.module}/../caddy"
  output_filename = "caddy.zip"
}

module "docker_zip_upload" {
  source          = "./modules/zip_and_upload_to_s3"
  bucket_name     = aws_s3_bucket.data_bucket.id
  folder_name     = "docker"
  source_dir      = "${path.module}/../docker"
  output_filename = "docker.zip"
}

module "scripts_zip_upload" {
  source          = "./modules/zip_and_upload_to_s3"
  bucket_name     = aws_s3_bucket.data_bucket.id
  folder_name     = "scripts"
  source_dir      = "${path.module}/../scripts"
  output_filename = "scripts.zip"
}

module "ec2-setup_zip_upload" {
  source          = "./modules/zip_and_upload_to_s3"
  bucket_name     = aws_s3_bucket.data_bucket.id
  folder_name     = "ec2-setup"
  source_dir      = "${path.module}/../ec2-setup"
  output_filename = "ec2-setup.zip"
}

module "web-apps_zip_upload" {
  source          = "./modules/zip_and_upload_to_s3"
  bucket_name     = aws_s3_bucket.data_bucket.id
  folder_name     = "web-apps"
  source_dir      = "${path.module}/../web-apps"
  output_filename = "web-apps.zip"
}

module "ansible_zip_upload" {
  source          = "./modules/zip_and_upload_to_s3"
  bucket_name     = aws_s3_bucket.data_bucket.id
  folder_name     = "ansible"
  source_dir      = "${path.module}/../ansible"
  output_filename = "ansible.zip"
}

module "code-server-extensions_zip_upload" {
  source          = "./modules/zip_and_upload_to_s3"
  bucket_name     = aws_s3_bucket.data_bucket.id
  folder_name     = "code-server-extensions"
  source_dir      = "${path.module}/../code-server-extensions"
  output_filename = "code-server-extensions.zip"
}

locals {
  # caddy_folder = "${path.module}/../caddy"

  # litellm_config_yml = file("${path.module}/../docker/open-webui/litellm-config.yml")
  # docker_compose_yml = file("${path.module}/../docker/open-webui/docker-compose.yml")
  # portainer_compose_yml = file("${path.module}/../docker/portainer/docker-compose.yml")
  # bedrock_gateway_compose_yml = file("${path.module}/../docker/bedrock-gateway/docker-compose.yml")
  # generate_app_urls_py = file("${path.module}/../scripts/generate-app-urls.py")
  # caddyfile = file("${path.module}/../caddy/Caddyfile")
  user_data_script   = file("${path.module}/../ec2-setup/user-data.sh")
  ec2_user_data = <<-EOT
#!/bin/bash

export PROJECT_ID=${var.project_id}
export AWS_REGION=${data.aws_region.current.name}
export CODE_SERVER_PASSWORD="${var.code_server_password}"
export LITELLM_API_KEY="${var.litellm_api_key}"
export BEDROCK_GATEWAY_API_KEY="${var.bedrock_gateway_api_key}"
export JUPYTER_LAB_TOKEN="${var.jupyter_lab_token}"
export DATA_BUCKET_NAME=${aws_s3_bucket.data_bucket.id}

${local.user_data_script}

EOT 

}

resource "aws_s3_object" "ec2_setup_script" {
  bucket  = aws_s3_bucket.data_bucket.id
  key     = "ec2-setup.sh"
  content = local.ec2_user_data
  # content_type = "text/x-sh"
  content_type = "text/x-shellscript"  
}

resource "aws_instance" "main_instance" {
  ami                         = var.ami
  instance_type               = var.instance_type
  subnet_id                   = aws_subnet.public.id
  key_name                    = aws_key_pair.main_key.key_name
  iam_instance_profile        = aws_iam_instance_profile.instance_profile.name
  vpc_security_group_ids      = [aws_security_group.allow_sources.id]
  associate_public_ip_address = true # Ensure public IP is associated

  # user_data = local.ec2_user_data
  user_data = <<-EOF
#!/bin/bash
aws s3 cp s3://${aws_s3_bucket.data_bucket.id}/ec2-setup.sh /root/
chmod +x /root/ec2-setup.sh
sudo yum install dos2unix -y
dos2unix /root/ec2-setup.sh
/root/ec2-setup.sh
EOF

  root_block_device {
    volume_type = "gp3"
    volume_size = 2048 # 2TB root volume
    # encrypted = false 
    # delete_on_termination = true
  }

  lifecycle {
    create_before_destroy = true
  }

  depends_on = [
    aws_s3_bucket.data_bucket,
    aws_s3_object.ec2_setup_script
  ]

  metadata_options {
    http_tokens                 = "required"
    http_put_response_hop_limit = 2 # Increase this value as needed for docker container
  }

  tags = {
    Name      = "${var.project_id}_main_server"
    CreatedBy = "terraform"
    AutoStopStart = "True"
  }
}


resource "aws_eip" "dev_ec2_eip" {
  instance = aws_instance.main_instance.id
  tags = {
    Name      = "${var.project_id}_dev_ec2_eip"
    CreatedBy = "terraform"
  }
}



# EC2 GPU

resource "aws_instance" "gpu_instance" {
  count = var.create_gpu_instance ? 1 : 0

  # Deep Learning Base AMI (Amazon Linux 2) Version 58.3
  # ami           = "ami-001c6931a3dcdfbff"

  # Deep Learning Base OSS Nvidia Driver GPU AMI (Ubuntu 20.04) 20240827
  ami = "ami-003c04f18386a1dcc"

  # instance_type = "g4dn.xlarge"  
  instance_type = "g5.xlarge"  
  subnet_id                   = aws_subnet.public.id
  key_name                    = aws_key_pair.main_key.key_name
  iam_instance_profile        = aws_iam_instance_profile.instance_profile.name
  vpc_security_group_ids      = [aws_security_group.allow_sources.id]
  associate_public_ip_address = true # Ensure public IP is associated

  root_block_device {
    volume_type           = "gp3"
    volume_size           = 2048 # 2TB root volume
    encrypted             = true
    delete_on_termination = true
  }

  tags = {
    Name      = "${var.project_id}_gpu"
    CreatedBy = "terraform"
  }
}


resource "aws_eip" "gpu_ec2_eip" {
  count = var.create_gpu_instance ? 1 : 0

  instance = aws_instance.gpu_instance[0].id
  tags = {
    Name      = "${var.project_id}_gpu"
    CreatedBy = "terraform"
  }
}



# Add basic Lambda execution permissions
resource "aws_iam_role_policy_attachment" "lambda_basic_execution" {
  role       = aws_iam_role.dev_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

data "archive_file" "controller_lambda_zip" {
  type        = "zip"
  output_path = "${path.module}/../lambda/function.zip"
  source_dir  = "${path.module}/../lambda/controller"
}



# Define the AWS Lambda Layer
resource "aws_lambda_layer_version" "common_layer" {
  layer_name = "common-layer"
  
  filename = data.archive_file.layer_zip.output_path
  
  compatible_runtimes = ["python3.8", "python3.9"] # Adjust as needed
  
  description = "Common Lambda Layer for shared dependencies"
}

# Create a zip file from the layer packages
data "archive_file" "layer_zip" {
  type        = "zip"
  source_dir  = "${path.module}/../lambda/layer/package"
  output_path = "${path.module}/../lambda/layer.zip"
}

resource "random_string" "bucket_suffix" {
  length  = 8
  special = false
  upper   = false
}

resource "random_string" "server_tool_jwt_secret" {
  length  = 8
  special = false
  upper   = false
}

# Create an S3 bucket
resource "aws_s3_bucket" "data_bucket" {
  bucket = "${var.project_id}-data-${random_string.bucket_suffix.result}"  # Replace with your desired bucket name
  force_destroy = true
}

# resource "random_string" "controller_auth_key" {
#   length  = 8
#   special = false
#   upper   = false
# }

resource "random_string" "controller_jwt_secret_key" {
  length  = 24
  special = false
  upper   = false
}

resource "aws_lambda_function" "main_controller_lambda" {
  filename         = data.archive_file.controller_lambda_zip.output_path
  function_name    = "${var.project_id}-controller"
  role             = aws_iam_role.dev_role.arn
  handler          = "main.lambda_handler"
  runtime          = "python3.12" # Or your preferred Python runtime
  source_code_hash = data.archive_file.controller_lambda_zip.output_base64sha256
  timeout          = 60

  layers = [aws_lambda_layer_version.common_layer.arn]

  # vpc_config {
  #   subnet_ids         = [aws_subnet.public.id]
  #   security_group_ids = [aws_security_group.controller_lambda_sg.id]
  # }

  # depends_on = [aws_s3_bucket.data_bucket]

  # environment {
  #   variables = {
  #     AUTH_KEY = random_string.controller_auth_key.result
  #     DATA_BUCKET_NAME = aws_s3_bucket.data_bucket.id
  #   }
  # }

  tags = {
    Name      = "${var.project_id}-controller"
    CreatedBy = "terraform"
  }
}


# resource "aws_security_group" "controller_lambda_sg" {
#   name        = "${var.project_id}-lambda-sg"
#   description = "Security group for Lambda function"
#   vpc_id      = aws_vpc.main.id

#   # Add any necessary ingress/egress rules
#   # For example:
#   egress {
#     from_port   = 0
#     to_port     = 0
#     protocol    = "-1"
#     cidr_blocks = ["0.0.0.0/0"]
#   }

#   tags = {
#     Name      = "${var.project_id}controller-lambda-sg"
#     CreatedBy = "terraform"
#   }
# }

resource "aws_lambda_function_url" "controller_lambda_url" {
  function_name      = aws_lambda_function.main_controller_lambda.function_name
  authorization_type = "NONE"

  cors {
    allow_credentials = true
    allow_origins     = ["*"]
    allow_methods     = ["*"]
    allow_headers     = ["date", "keep-alive"]
    expose_headers    = ["keep-alive", "date"]
    max_age           = 86400
  }
}










# 
# Data source to get the EC2 instance IDs based on a tag
data "aws_instances" "tagged_instances" {
  filter {
    name   = "tag:AutoStopStart"
    values = ["True"]
  }
  depends_on = [ aws_instance.main_instance ]
}

# IAM role for the EventBridge Scheduler
resource "aws_iam_role" "scheduler_role" {
  name = "${var.project_id}-ec2-scheduler-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "scheduler.amazonaws.com"
        }
      }
    ]
  })
}

# IAM policy to allow starting and stopping EC2 instances
resource "aws_iam_role_policy" "scheduler_policy" {
  name = "${var.project_id}-ec2-scheduler-policy"
  role = aws_iam_role.scheduler_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ec2:StartInstances",
          "ec2:StopInstances"
        ]
        Resource = "*"
      }
    ]
  })
}

# Scheduler schedule to stop EC2 instances at 12 PM (midnight)
resource "aws_scheduler_schedule" "stop_ec2" {
  name       = "${var.project_id}-stop-ec2-schedule"
  group_name = "default"

  flexible_time_window {
    mode = "OFF"
  }

  schedule_expression = "cron(0 0 * * ? *)"

  target {
    arn      = "arn:aws:scheduler:::aws-sdk:ec2:stopInstances"
    role_arn = aws_iam_role.scheduler_role.arn

    input = jsonencode({
      InstanceIds = data.aws_instances.tagged_instances.ids
    })
  }
}

# Scheduler schedule to start EC2 instances at 4 AM
resource "aws_scheduler_schedule" "start_ec2" {
  name       = "${var.project_id}-start-ec2-schedule"
  group_name = "default"
  state      = "DISABLED"  # This line ensures the scheduler is created in a disabled state

  flexible_time_window {
    mode = "OFF"
  }

  schedule_expression = "cron(0 4 * * ? *)"

  target {
    arn      = "arn:aws:scheduler:::aws-sdk:ec2:startInstances"
    role_arn = aws_iam_role.scheduler_role.arn

    input = jsonencode({
      InstanceIds = data.aws_instances.tagged_instances.ids
    })
  }
}
# 









output "subnet_id" {
  description = "The ID of the created public subnet"
  value       = aws_subnet.public.id
}

output "route_table_id" {
  description = "The ID of the created route table"
  value       = aws_route_table.public_rt.id
}

output "security_group_id" {
  description = "The ID of the created security group"
  value       = aws_security_group.allow_sources.id
}

output "iam_role_arn" {
  description = "The ARN of the created IAM role"
  value       = aws_iam_role.dev_role.arn
}

output "iam_policy_arn" {
  description = "The ARN of the created IAM policy"
  value       = aws_iam_policy.dev_role_policy.arn
}

output "instance_profile_arn" {
  description = "The ARN of the created IAM instance profile"
  value       = aws_iam_instance_profile.instance_profile.arn
}

output "key_pair_name" {
  description = "The name of the created key pair"
  value       = aws_key_pair.main_key.key_name
}

output "instance_id" {
  description = "The ID of the created EC2 instance"
  value       = aws_instance.main_instance.id
}

output "instance_public_ip" {
  description = "The public IP address of the created EC2 instance"
  value       = aws_instance.main_instance.public_ip
}

output "instance_private_ip" {
  description = "The private IP address of the created EC2 instance"
  value       = aws_instance.main_instance.private_ip
}

output "elastic_ip" {
  description = "The Elastic IP address associated with the EC2 instance"
  value       = aws_eip.dev_ec2_eip.public_ip
}

output "PROJECT_ID" {
  value = var.project_id
}

# Output the bucket name
output "bucket_name" {
  value       = aws_s3_bucket.data_bucket.id
  description = "The name of the S3 bucket"
}

output "my_public_ip" {
  value = data.http.my_public_ip.response_body
  description = "My public IP address"
}

output "controller_url" {
  value = aws_lambda_function_url.controller_lambda_url.function_url
}


output "vpc_id" {
  description = "The ID of the VPC"
  value       = aws_vpc.main.id
}

# output "ec2_ip_gpu" {
#   value       = var.create_gpu_instance ? aws_instance.gpu_instance[0].ip : null
# }

# output "ec2_dns_gpu" {
#   # value = aws_instance.gpu_instance[0].public_dns
#   value = aws_instance.gpu_instance.id
# }



resource "aws_ssm_parameter" "resource_ids" {
  name  = "/${var.project_id}/info"
  type  = "String"
  value = jsonencode({
    elasticIP                 = aws_eip.dev_ec2_eip.public_ip,
    elasticIPG = try(aws_eip.gpu_ec2_eip[0].public_ip, null),
    projectId                 = var.project_id,
    instanceId                = aws_instance.main_instance.id,
    instanceIdG               = try(aws_instance.gpu_instance[0].id, null),
    controllerUrl             = aws_lambda_function_url.controller_lambda_url.function_url,
    dataBucketName            = aws_s3_bucket.data_bucket.id,
    codeServerPassword        = var.code_server_password,
    serverToolPassword        = var.server_tool_password,
    serverToolJwtSecret       = random_string.server_tool_jwt_secret.result,
    liteLLMApiKey             = var.litellm_api_key,
    jupyterLabToken           = var.jupyter_lab_token,
    bedrockGatewayApiKey      = var.bedrock_gateway_api_key,
    controller_auth_key       = var.controller_auth_key,
    controller_jwt_secret_key = random_string.controller_jwt_secret_key.result,
    ec2SecurityGroupId        = aws_security_group.allow_sources.id,
    ec2PublicDns              = aws_instance.main_instance.public_dns,
    eipPublicDns              = aws_eip.dev_ec2_eip.public_dns,
    eipPublicDnsG             = try(aws_eip.gpu_ec2_eip[0].public_dns, null)
  })

  # Ensure this resource is created after all other resources
  depends_on = [
    aws_eip.dev_ec2_eip,
    aws_instance.main_instance,
    aws_lambda_function_url.controller_lambda_url,
    aws_s3_bucket.data_bucket,
    random_string.controller_jwt_secret_key
  ]
}

# Local file resource to create the output file
resource "local_file" "outputs" {
  filename = "${path.module}/set-tf-output-2-env-var.bat"
  content  = <<-EOT
set AWS_REGION=${data.aws_region.current.name}
set ELASTIC_IP=${aws_eip.dev_ec2_eip.public_ip}
set ELASTIC_IP_G=${try(aws_eip.gpu_ec2_eip[0].public_ip, "")}
set PROJECT_ID=${var.project_id}
set INSTANCE_ID=${aws_instance.main_instance.id}
set INSTANCE_ID_G=${try(aws_instance.gpu_instance[0].id, "")}
set EIP_PUBLIC_DNS=${aws_eip.dev_ec2_eip.public_dns}
set EIP_PUBLIC_DNS_G=${try(aws_eip.gpu_ec2_eip[0].public_dns, "")}
set EC2_PUBLIC_DNS=${aws_instance.main_instance.public_dns}
set CONTROLLER_URL=${aws_lambda_function_url.controller_lambda_url.function_url}
set DATA_BUCKET_NAME=${aws_s3_bucket.data_bucket.id}
set EC2_SECURITY_GROUP_ID=${aws_security_group.allow_sources.id}
EOT
}
# set CONTROLLER_AUTH_KEY=${random_string.controller_auth_key.result}
# set TEST=${var.code_server_password}

variable "region" {}
# variable "public_key_file_path" {}
variable "allowed_source_ips" {}
variable "vpc_id" {}
variable "subnet_cidr" {}
variable "project_id" {}
variable "ami" {}
variable "instance_type" {}

provider "aws" {
  region = var.region
}

data "aws_region" "current" {}
data "aws_caller_identity" "current" {}
data "aws_availability_zones" "available" {}
data "aws_internet_gateway" "main" {
  filter {
    name   = "attachment.vpc-id"
    values = [var.vpc_id]
  }
}


resource "aws_subnet" "public" {
  vpc_id                  = var.vpc_id
  cidr_block              = var.subnet_cidr
  availability_zone       = "us-east-1a"
  map_public_ip_on_launch = true
  tags = {
    Name      = "${var.project_id}"
    CreatedBy = "terraform"
  }
}

resource "aws_route_table" "public_rt" {
  vpc_id = var.vpc_id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = data.aws_internet_gateway.main.id
  }
  tags = {
    Name      = "${var.project_id}"
    CreatedBy = "terraform"
  }
}

resource "aws_route_table_association" "public_assoc" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public_rt.id
}


resource "aws_security_group" "allow_sources" {
  name        = "${var.project_id}_allow_sources"
  description = "Allow SSH, Jupyter inbound traffic"
  vpc_id      = var.vpc_id

  ingress {
    description = "SSH from VPC"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = var.allowed_source_ips
  }

  ingress {
    description = "All web apps"
    from_port   = 7100
    to_port     = 7200
    protocol    = "tcp"
    cidr_blocks = var.allowed_source_ips
  }

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

locals {
  litellm_config_yml = file("${path.module}/../docker/open-webui/litellm-config.yml")
  docker_compose_yml = file("${path.module}/../docker/open-webui/docker-compose.yml")
  portainer_compose_yml = file("${path.module}/../docker/portainer/docker-compose.yml")
  generate_app_urls_py = file("${path.module}/../scripts/generate-app-urls.py")
  caddyfile = file("${path.module}/../caddy/Caddyfile")
  user_data_script   = file("${path.module}/../ec2-setup/user-data.sh")
  ec2_user_data = <<-EOT
#!/bin/bash

PROJECT_ID=${var.project_id}

read -r -d '' LITELLM_CONFIG_CONTENT << 'EOF'
  ${local.litellm_config_yml}
EOF

read -r -d '' DOCKER_COMPOSE_CONTENT << 'EOF'
  ${local.docker_compose_yml}
EOF

read -r -d '' PORTAINER_COMPOSE_CONTENT << 'EOF'
  ${local.portainer_compose_yml}
EOF

read -r -d '' CADDYFILE_CONTENT << 'EOF'
  ${local.caddyfile}
EOF

DATA_BUCKET_NAME=${aws_s3_bucket.data_bucket.id}

read -r -d '' GENERATE_APP_URLS_PY_CONTENT << 'EOF'
  ${local.generate_app_urls_py}
EOF


${local.user_data_script}

EOT 

}

resource "aws_instance" "main_instance" {
  ami                         = var.ami
  instance_type               = var.instance_type
  subnet_id                   = aws_subnet.public.id
  key_name                    = aws_key_pair.main_key.key_name
  iam_instance_profile        = aws_iam_instance_profile.instance_profile.name
  vpc_security_group_ids      = [aws_security_group.allow_sources.id]
  associate_public_ip_address = true # Ensure public IP is associated

  user_data = local.ec2_user_data

  root_block_device {
    volume_type = "gp3"
    volume_size = 2048 # 2TB root volume
    # encrypted = false 
    # delete_on_termination = true
  }

  lifecycle {
    create_before_destroy = true
  }

  depends_on = [aws_s3_bucket.data_bucket]

  tags = {
    Name      = "${var.project_id}_main_server"
    CreatedBy = "terraform"
  }
}


resource "aws_eip" "dev_ec2_eip" {
  instance = aws_instance.main_instance.id
  tags = {
    Name      = "${var.project_id}_dev_ec2_eip"
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


resource "random_string" "bucket_suffix" {
  length  = 8
  special = false
  upper   = false
}

# Create an S3 bucket
resource "aws_s3_bucket" "data_bucket" {
  bucket = "${var.project_id}-data-${random_string.bucket_suffix.result}"  # Replace with your desired bucket name
}




# data "archive_file" "controller_lambda_zip" {
#   type        = "zip"
#   output_path = "${path.module}/../lambda/function.zip"

#   source {
#     content  = file("${path.module}/../lambda/controller/main.py")
#     filename = "main.py"
#   }

#   source {
#     content  = file("${path.module}/../lambda/controller/index.html")
#     filename = "index.html"
#   }

#   source {
#     content  = file("${path.module}/../lambda/controller/requirements.txt")
#     filename = "requirements.txt"
#   }

#   source {
#     content  = file("${path.module}/../lambda/controller/login.html")
#     filename = "login.html"
#   }
# }

resource "random_string" "controller_auth_key" {
  length  = 8
  special = false
  upper   = false
}

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


output "controller_url" {
  value = aws_lambda_function_url.controller_lambda_url.function_url
}

# Output the bucket name
output "bucket_name" {
  value       = aws_s3_bucket.data_bucket.id
  description = "The name of the S3 bucket"
}




# Attempt to fetch the existing parameter value
data "aws_ssm_parameter" "existing_info" {
  name = "/${var.project_id}/info"
  with_decryption = false
}

locals {
  # Merge is needed to keep apps value in the JSON. "apps" value is added by user-data.sh. If the user do terraform apply after EC2 is generated, we want to keep apps and only update other values.
  # Use an empty map if the parameter doesn't exist or can't be decoded
  existing_info = try(jsondecode(data.aws_ssm_parameter.existing_info.value), {})

  # New information to be added or updated
  new_info = {
    elasticIP = aws_eip.dev_ec2_eip.public_ip,
    projectId = var.project_id,
    instanceId = aws_instance.main_instance.id,
    controllerUrl = aws_lambda_function_url.controller_lambda_url.function_url,
    dataBucketName = aws_s3_bucket.data_bucket.id,
    controller_auth_key = random_string.controller_auth_key.result,
    controller_jwt_secret_key = random_string.controller_jwt_secret_key.result
  }

  # Merge existing and new information
  merged_info = merge(local.existing_info, local.new_info)
}

# Create or update the parameter
resource "aws_ssm_parameter" "resource_ids" {
  name  = "/${var.project_id}/info"
  type  = "String"
  value = jsonencode(local.merged_info)

  # Ensure this resource is created after all other resources
  depends_on = [
    aws_eip.dev_ec2_eip,
    aws_instance.main_instance,
    aws_lambda_function_url.controller_lambda_url,
    aws_s3_bucket.data_bucket,
    random_string.controller_auth_key
  ]
}




# Local file resource to create the output file
resource "local_file" "outputs" {
  filename = "${path.module}/set-tf-output-2-env-var.bat"
  content  = <<-EOT
set ELASTIC_IP=${aws_eip.dev_ec2_eip.public_ip}
set PROJECT_ID=${var.project_id}
set INSTANCE_ID=${aws_instance.main_instance.id}
set CONTROLLER_URL=${aws_lambda_function_url.controller_lambda_url.function_url}
set DATA_BUCKET_NAME=${aws_s3_bucket.data_bucket.id}
EOT
}
# set CONTROLLER_AUTH_KEY=${random_string.controller_auth_key.result}

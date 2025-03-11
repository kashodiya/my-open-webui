# my-open-webui
Install your own instance of Open WebUI for personal use

## Assumptions and pre-requisites
- You are using Windows machine
- You have access to an AWS account

## Guide to installing Open WebUI on EC2
### Install Terraform
- Download installer from (Use AMD64):  
https://developer.hashicorp.com/terraform/install
- Install terraform

### Install Git for Windows
- Download and install from:  
https://git-scm.com/downloads/win

### Install AWS CLI for Windows. Follow:
https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html

### Clone this project
git clone https://github.com/kashodiya/my-open-webui.git
cd my-open-webui

### Login to AWS
- Either set the AWS credentials env vars
- OR, setup profile and set AWS_DEFAULT_PROFILE
- Ensure env var AWS_REGION is set

### Find out your VPC Id using this command
aws ec2 describe-vpcs

### Ensure you have Internet Gateway associated with VPC
- Check if you already have Internet Gateway using this command:  
aws ec2 describe-internet-gateways
- If you do not have Internet Gatewy, create one using:  
aws ec2 create-internet-gateway  
- Note down internet gateway id and associate it to the VPC using this command:  
aws ec2 attach-internet-gateway --internet-gateway-id igw-xxxxxxxx --vpc-id vpc-xxxxxxxx

### Find our your IP address
- Go to:  
https://whatismyipaddress.com/
- Copy IPv4

### Update values in terraform\terraform.tfvars.json file
- Update allowed_source_ips array by replacing your IP address in there.
- Tips: If you also want to access Open WebUI from some other network make sure that you add that machine's public IP address to the array.
- Optional: Update these items if you want:
    - ami (this must be Amazon Linux os)
    - instance_type
    - project_id

### Set LiteLLM API Key
- Decide a key (random string)
- Edit docker\docker-compose.yml and update following 2 values.  
LITELLM_API_KEY  
OPENAI_API_KEY  
- Ensure that both the values are same

### Init and apply terraform
cd terraform  
terraform init  
terraform apply  
terraform output -json > output.json

### SSH into EC2
- Find Elastic IP address from terraform\output.json file.
- SSH into the EC2 server using this command:

set PROJECT_DIR=path/to/your/project/folder  
set ELASTIC_IP=your.elastic.ip.address  
ssh -i %PROJECT_DIR%\keys\private_key.pem ec2-user@%ELASTIC_IP%

### Verify the install
- See the user data script:
sudo tail -f /var/log/cloud-init-output.log

### Set admin user password for Open WebUI
- Run this command in cmd window:  
start http://%ELASTIC_IP%:8101
- Sign up for admin user

### Request access to bedrock models
- Open docker\litellm-config.yml and request model access for each models mentioned in the config.
- Login to AWS Console
- Request models access by going to:  
https://us-east-1.console.aws.amazon.com/bedrock/home?region=us-east-1#/modelaccess


### Setup Open WebUI connections 
TODO

## Maintenance and operations

### Stop EC2 server
aws ec2 stop-instances --instance-ids %INSTANCE_ID%

### Start EC2 server
aws ec2 start-instances --instance-ids %INSTANCE_ID%

### Delete everything on AWS that was created via this project
cd terraform  
terraform destroy  

### How to upgrade Open WebUI to new version?
TODO: Add more details 
- SSH into EC2
- Stop Docker containers using command:  
cd open-webui  
docker-compose down
- Delete Open WebUI image
- Start docker compose
docker-compose up -d

### How to add more Bedrock models?
- Make sure that you have request access to the model
- SSH into EC2 server
- Edit docker/litellm-config.yml
    - Add a model in the model list
- Restart LiteLLM container
cd docker
docker-compose restart litellm

### How to manage Open WebUI users?
TODO
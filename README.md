# my-open-webui
Install your own instance of Open WebUI for personal use along with a simple but effective and powerful workbench to do explore GenAI. 

## Assumptions and pre-requisites
- You are using Windows machine
- You have access to an AWS account
- You are using us-east-1 region

## Design principles
- Keep cost lowest
- KISS - Keep it simple, stupid 
- Scalability and performance are not primary focus. Primary focus is to get things done quickly.
- Security is tight. But only as much required. (Ex: using dummy certs to enable HTTPS)

## What will be installed?
- An EC2 will be created and following softwares will be installed in it:
    - Open WebUI
    - Portainer (Web based Docker management)
    - Code-server (VSCode on EC2 in your browser)
    - LiteLLM (Gateway to Bedrock)
    - Jupyter Lab
    - Caddy (reverse proxy and authetication server)

## Why should I use this?
- Enjoy full privacy. All your chats private. Bedrock does not store your chats and does not use it for retraining.
- Best use of your AWS account to learn and experiment GenAI.
- Get a powerful workbench on which you can build further capabilities.

## SETUP GUIDE
### Install Terraform
- Download from (Use AMD64):  
https://developer.hashicorp.com/terraform/install
- Unzip files to a folder
- Add the folder that contains terraform.exe file to the PATH

### Install Git for Windows
- Download and install from:  
https://git-scm.com/downloads/win

### Install AWS CLI for Windows. Follow:
https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html

### Clone this project
- Open cmd window and execute:
```bat
git clone https://github.com/kashodiya/my-open-webui.git
cd my-open-webui
```

### Login to AWS
- Either set the AWS credentials env vars
- OR, setup profile and set AWS_DEFAULT_PROFILE
- Ensure env var AWS_REGION is set


### Check if you have VPC
- From cmd window, run
```bat
aws ec2 describe-vpcs
```
- If you see your VPC, note down VPC ID
- If you do not see VPC, please create one
- From cmd window, run
```bat
aws ec2 create-vpc --cidr-block 10.0.0.0/16
```

### Set your VPC ID for terraform
- Find out your VPC Id using this command 
```bat
aws ec2 describe-vpcs  
```
- Create new file: terraform\terraform.tfvars.json
- Here is a sample:
```json
{
    "vpc_id": "vpc-your-vpc-id-here",
    "subnet_cidr": "10.0.2.0/26",
    "allowed_source_ips": [
        "replace.this.with.your-ip"
    ]
}
```
- All the values in "terraform.tfvars" are over-written by values in "terraform\terraform.tfvars" at runtime.
- Update your VPC Id in vpc_id
- The script will create a new subnet. You need to provide a CIDR range (with /32) for new subnet. Set a unused CIDR range "subnet_cidr" field. 
- See tips section to find out how to find unused CIDR. 
- Set "allowed_source_ips": 
    - Go to and copy IPv4: https://whatismyipaddress.com/
    - Add '/32' after the IP
    - Set that ip range in "allowed_source_ips"
    - The EC2 will allow traffic coming in from only these IP addresses. 

### Ensure you have Internet Gateway associated with VPC
- Check if you already have Internet Gateway using this command:  
```bat
aws ec2 describe-internet-gateways
```
- If you do not have Internet Gatewy, create one using:  
```bat
aws ec2 create-internet-gateway  
```
- Note down internet gateway id and associate it to the VPC using this command:  
```bat
aws ec2 attach-internet-gateway --internet-gateway-id igw-xxxxxxxx --vpc-id vpc-xxxxxxxx
```

### Init and apply terraform
```bat
cd terraform  
terraform init  
terraform apply  
```
- Check the plan and when ask for Enter a value, enter yes, hit Enter key
- This may take a few min when you run first time


### Create Launcher
- Open cmd window, if not already open.
- Make sure you do one of the following:
    - Set AWS_DEFAULT_PROFILE
    - Set AWS_ACCESS_KEY_ID, AWS_SECRET_ACCESS_KEY and AWS_SESSION_TOKEN environment variable. 
- Cd to the project folder (cd my-open-webui)
- Run following command
```bat
scripts\create-launcher.bat
```
- "launcher.bat" file is created in local folder.
- Windows Explorer is opened.
- Double click "launcher.bat" file.
- All the following instructions must be executed from the launcher.
- NOTE: If you use AWS_DEFAULT_PROFILE you have create launcher only once. If you use AWS_ACCESS_KEY_ID etc. env vars, you have to create launcher everytime you login.

### OLD Create Launcher - DELETE THIS
- Create a bat file (launch.bat or whatever you like) on your desktop with following content. Do not forget to replace place holder values, profile and path:  
```bat
@echo off  
set AWS_DEFAULT_PROFILE=your-aws-profile  
start cmd /k "cd /d D:\Users\full-path-to-project-code && call scripts\start-dev.bat"  
```
- If you are not using profile and want to cut-paste credentials, your launch should look like this. Do not forget to replace the place holders:
```bat
@echo off  
SET AWS_ACCESS_KEY_ID=access-key-id-here
SET AWS_SECRET_ACCESS_KEY=secret-access-key-here
SET AWS_SESSION_TOKEN=very-long-token-string-here
start cmd /k "cd /d D:\Users\full-path-to-project-code && call scripts\start-dev.bat"  
```

- Whenever you want to start working on this project, just double click this bat file!  
- Read the info presented in the cmd window!  
- It offers following shortcuts:  
```ini
tfa = Terraform apply  
sshe = SSH into EC2  
ec2 = Start EC2  
ec2x = Stop EC2  
open-webui = Opens Open WebUI in Browser  
portainer = Opens Portainer in Browser  
code-server = Opens code-server in Browser  
litellm = Opens LiteLLM in Browser  
rkh = Remove known SSH host  
```

### SSH into EC2 (easy way)
- Run scripts\start-dev.bat
- Use this shortcut from the Launcher (read - ssh to ec2): sshe  

### SSH into EC2 (hard way)
- Find Elastic IP address from terraform\set-tf-output-2-env-var.bat file.
- SSH into the EC2 using shortcut from launcher OR,
- SSH into the EC2 server using this command:
```bat
set PROJECT_DIR=path/to/your/project/folder  
set ELASTIC_IP=your.elastic.ip.address  
ssh -i %PROJECT_DIR%\keys\private_key.pem ec2-user@%ELASTIC_IP%
```

### Track the setup of software in EC2
- SSH into the EC2 (using 'sshe' shortcut command from the Launcher), and execute:
```bash
tail_setup_log
```
- This should be the last line in the log:
All installations completed.
- Press Ctrl+C to exit.
- To see complete user data script log:  
sudo less +G /var/log/user-data.log

### Set admin user password for Open WebUI
- Use shortcut "open-webui" from launcher to start Open WebUI in the browser.
- Since we are using self-signed certificates, bypass the warning by clicking Advance and then Continue. 
- Sign up for admin user

### Request access to bedrock models
- Open docker\open-webui\litellm-config.yml and request model access for each models mentioned in the config.
- Login to AWS Console
- Request models access by going to:  
    - TIP: You only pay for what you use. You can request access to all the models. Click checkbox at the top on the model selection page. 
https://us-east-1.console.aws.amazon.com/bedrock/home?region=us-east-1#/modelaccess

### Use Open WebUI
- Open open-webui in browser using shortcut: open-webui  
- Click on "Get started"
- Register yourself with name, email and password. You can use fake email.
- Ensure that you can see models at top left
- Type a question and hit Enter. Ensure that you get the answer

### CONGRATULATIONS! At this point your Open WebUI install is done. Follow remaining if you want to do more with your EC2.

### If you want to install Controller (a Lambda bsed web utility that allow you to manage the env)
- Install Python or Miniconda
- Run following commands:
```bat
cd lambda\controller
pip install -r requirements.txt -t package
cd ..
deploy.bat controller
```
- To open controller from Launcher run shortcut: controller

### Find auto-generated passwords and tokens
- SSH into the EC2 (using 'sshe' shortcut command from the Launcher), and execute:
```bash
show_passwords
```
- Note down passwords and token to be used with Jupyter Lab and Code-server


### Use code server (VSCode to EC2 server in your Browser!)
- To open code-server, use shortcut command: code-server

### Use Jupyter Lab
- To open Jupyter Lab, use shortcut command: jupyterlab

### Use Portainer (if you want to work with Docker using UI)
- To open Portainer, use shortcut command: portainer
- When you access it for first time, it was ask you to register as admin, follow the instructions.



## Maintenance and operations

### Stop EC2 server
aws ec2 stop-instances --instance-ids %INSTANCE_ID%

### Start EC2 server
aws ec2 start-instances --instance-ids %INSTANCE_ID%

### Delete everything on AWS that was created via this project
```bat
cd terraform  
terraform destroy  
```

### How to upgrade Open WebUI to new version?
- SSH into EC2
- Delete Docker containers using command:  
```bash
cd open-webui  
docker-compose down
```
- Delete Open WebUI image
```bash
docker rmi ghcr.io/open-webui/open-webui:main
```
- Create docker containers
```bash
docker-compose up -d
```
- Latest image will be automatically downloaded and used


### How to add more Bedrock models?
- Make sure that you have requested access to the model
- SSH into EC2 server
- Edit docker/litellm-config.yml
    - Add a model in the model list
- Restart LiteLLM container  
```bash
cd docker  
docker-compose restart litellm  
```

### How to manage Open WebUI users?
TODO



### How to check server (running in Docker) logs?
- SSH into EC2 server  
```bash
cd docker
docker logs -f open-webui
docker logs -f litellm
```
### Jupyter Lab service related commands:
```bash
sudo systemctl status jupyter-lab.service
sudo systemctl stop jupyter-lab.service
sudo systemctl start jupyter-lab.service
sudo systemctl restart jupyter-lab.service
sudo systemctl enable jupyter-lab.service
sudo journalctl -u jupyter-lab.service
sudo journalctl -fu jupyter-lab.service
```

### Caddy service related commands:
```bash
sudo systemctl status caddy
sudo systemctl daemon-reload
sudo systemctl enable caddy
sudo systemctl start caddy
sudo systemctl reload caddy
caddy validate --config /etc/caddy/Caddyfile
cat /etc/caddy/Caddyfile
```

### How to recreate EC2?
- WARNING: This will delete your EC2 and all data inside it!
- Execute following commands  
```bat
cd terraform  
terraform taint aws_instance.main_instance  
```
- After you create new EC2, before doing SSH into EC2, do this:
```bat
ssh-keygen -R %ELASTIC_IP%  
```


### How to change code-server password
- Open code-server (using Launcher shortcut)
- Edit: /home/ec2-user/.config/code-server/config.yaml 
- Set new password
- SSH into EC2 and restart code-server
```bash
sudo systemctl restart code-server@$USER
```

### Commands related to the code-server
```bash
sudo systemctl status code-server@$USER
sudo systemctl stop code-server@$USER
sudo cat /usr/lib/systemd/system/code-server@.service
sudo vi /usr/lib/systemd/system/code-server@.service
sudo systemctl daemon-reload
sudo systemctl restart code-server@$USER
```

- Read password
cat /home/ec2-user/.config/code-server/config.yaml


## Tips and tricks

### Careful before changing project_id
- If you have already deployed this product and change project_id and deploy again, it will destroy previous deployment. 

### Stop EC2 when not used without worry
- When you start the EC2 (use shortcut "ec2") all your apps are started by default!

### How to find out unused cidr for new subnet
- Run this command in cmd. Make sure you replace VPC ID in the command with your VPC ID.
```bat
cd scripts
powershell.exe -ExecutionPolicy Bypass -File find-next-available-cidr.ps1 "vpc-your-vpc-id-here"
```

### Tip for setting your development environment
- Prefer to use AWS profile instead of directly using AWS credentials in enviroment variables
- Create a bat file on your desktop with this content:  
```bat
@echo off  
set AWS_DEFAULT_PROFILE=your-aws-profile  
start cmd /k "cd /d D:\Users\full-path-to-project-code && call scripts\start-dev.bat"  
```
- Whenever you want to start working on this project, just double click this bat file!  
- Read the info presented in the cmd window!  
- It offers following shortcuts:  
```ini
tfa = Terraform apply  
sshe = SSH into EC2  
ec2 = Start EC2  
ec2x = Stop EC2  
open-webui = Opens Open WebUI in Browser  
portainer = Opens Portainer in Browser  
code-server = Opens code-server in Browser  
litellm = Opens LiteLLM in Browser  
rkh = Remove known SSH host  
```

### How to allow my team members to use my Open WebUI server?
- Login to Open WebUI
- Click on top right avatar icon
- Settings -> Admin Settings -> General
- Turn on - Enable New Sign Ups
- Ensure that Default User Role is 'pending'
- If your team member is on other network, find out its public facing address, add it to the allowed_source_ips JSON array in terraform\terraform.tfvars.json file
- Do terraform apply
- Give them the URL of the Open WebUI
- Ask them to self sign
- Once they self sign, enable their access by:
    - Click on top right avatar icon
    - Click Admin Panel
    - Click PENDING once to make it USER
- Ask your user to login or refresh their page



## Resources and references
### Open WebUI
- [Docs](https://docs.openwebui.com/)
- [Home page](https://openwebui.com/)

### LiteLLM
- [Docs](https://docs.litellm.ai/docs/)
- [Home page](https://www.litellm.ai/)

### Code server
- [GitHub page](https://github.com/coder/code-server)

### Portainer
- [GitHub page](https://github.com/portainer/portainer)
- [Home page](https://www.portainer.io/)

### Caddy
- [Home page](https://caddyserver.com/docs/quick-starts/reverse-proxy)

## Troubleshooting

### I messed up the install. How can I restart?
- If you have done terraform apply...
    - In cmd window cd to terraform folder and do "terraform destroy"
    - Git clone in new folder, and follow instructions
- If yoh have not done terraform apply...
    - Git clone in new folder, and follow instructions
- See section: How to recreate EC2?

### When doing terraform apply: Error: No matching Internet Gateway found
- You should create Internet gatewat and attach to your VPC (see the instructions above)

### When I go to portainer using browser, I get error: New Portainer installation Your Portainer instance timed out for security purposes. To re-enable your Portainer instance, you will need to restart Portainer.
- To resolve this, SSH into EC2 server
- Run this command
```bash
docker restart portainer
```
- Refresh browser
- Set password (min length 12 characters)



## Internal design/architecture

### Is this a good architecture?
- Yes and No!
- Do not use any design pattern used here in production systems.
- This is good desgn for quick and dirty setup for learning and experimentation.

### To avoid cost...
- We are not using Route53, API Gateay and ALBs
- All the work is done on single EC2
- Shortcuts are provided to start and stop EC2 easily

### How Caddy server is used?
- All the port numbers starting from 7100 are used by Caddy to serve apps running on ports from 8100 respectively. 
- Caddy config is stored at /etc/caddy/Caddyfile
- It uses a dummy cert to serve HTTPS
- Caddy can manage users and password and offer authentication. This is useful for appss that do not have native/local user management, like demo apps you may create etc.

### How server prodcuts are instaled on EC2?
- Server is setup using user-data script when creating EC2
- User data script is dynamically generated in terraform main.tf
- Files from docker etc folder are read by terraform and injected into user-data script along with ec2-setup/user-data.sh file. 
- See user-data.sh file to find how things are installed.
- Most of the products are run as Docker containers

### How Open WebUI is configured?
- For details look at these files:
    - docker\open-webui\docker-compose.yml
    - docker\open-webui\litellm-config.yml
- Open WebUI talks to LiteLLM and LiteLLM talks to Bedrock based on litellm-config.yml
- Open WebUI is using sqlite3 as the database
    - Location of sqlite3 db file: 


### How launcher works?
- Launcher is a bat file that you create on dektop so that you can work with this project.
- Launcher knows about the EC2, its IP address, etc.
- Launcher also offers you several shortcuts
- How do Launcher knows about this project?
    - When you do terraform apply, the script generates a bat file terraform\set-tf-output-2-env-var.bat
    - This bat file has information like Elastic IP, EC2 ID etc. 
    - The launcher read this file so it can use those information.
    - Shortcuts offered by Launcher is printed to the console when you launch it, so you not need to remember it!


## If you want to taint controller lambda, you have to taint url also
```bat
terraform taint aws_lambda_function.main_controller_lambda 
terraform taint aws_lambda_function_url.controller_lambda_url
```



### How to update and deploy Controller Lambda
- To deploy lambda (after you modify):
```bat
cd lambda
deploy controller
```

### How to update Controller Lambda key?
- Open launcher, and run this commands:
```bat
set CONTROLLER_AUTH_KEY=<new-key>
cd lambda
deploy.bat controller
```


## TODO:
How to change passwords
How to restart portainer when timed out
Telll them open webui is contained and your data is not shread
Add model, restart litellm
Mention that your data is contained

Remove 
set CONTROLLER_AUTH_KEY=${random_string.controller_auth_key.result}
from main.tf

When tfa is done again , lambda auth key is overwrittend (it it was changed manually by lambda update) - in lambda update update the tf state?
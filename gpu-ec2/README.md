# What is GPU EC2
- It is a EC2 with GPU
- To experiment with projects requiring GPU

## How EC2 is created
- See terraform\main.tf

## Initial setup
- After the EC2 is created
cd setup
run-setup.bat

cd ..\ansible
init-ansible.bat
do-ansible.bat install_portainer.yml
do-ansible.bat install_jupyter_lab.yml


## Run COmfyUI
cd /home/ubuntu/projects/comfy/ComfyUI
python main.py --port 9104
admin
testtest



## Recreate GPU EC2
terraform taint aws_instance.gpu_instance
terraform apply
terraform output -json > outputs.json


## Apps installed
- As system service
code-server
- In Docker
portainer
- Run on 



## Troubleshooting

### Jupyterlab
sudo cat /etc/systemd/system/jupyterlab.service

### Caddy
sudo systemctl status caddy
caddy validate --config /etc/caddy/Caddyfile

cat /etc/caddy/Caddyfile

sudo systemctl daemon-reload
sudo systemctl enable caddy
sudo systemctl start caddy


sudo systemctl status caddy


sudo systemctl reload caddy

## Pinokio
- Download from https://github.com/pinokiocomputer/pinokio/releases/tag/3.6.23
cd temp
wget https://github.com/pinokiocomputer/pinokio/releases/download/3.6.23/Pinokio_3.6.23_amd64.deb
sudo dpkg -i Pinokio_3.6.23_amd64.deb



















# === === === == ===
# Remaining will be deteld, outdated

## First time setup
- Install conda
- Run setup/setup.sh
- Run ansibles
gpu-ec2\ansible\install_jupyter.yml
gpu-ec2\ansible\install-caddy.yml
- Run dockers
n8n



## ConfyUI setup
### Git page: https://github.com/comfyanonymous/ComfyUI
### Install steps
mkdir temp
cd temp
wget https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh
bash Miniconda3-latest-Linux-x86_64.sh

- Re-login

mkdir projects
cd projects
mkdir comfy
comfy
git clone https://github.com/comfyanonymous/ComfyUI.git
cd ComfyUI
pip install -r requirements.txt
python main.py --listen 0.0.0.0

python main.py --listen 0.0.0.0 --port 9104


## Generate Caddyfile user and password
- caddy hash-password
- Edit Caddyfile  
- Add user with password hash

## ComfyUI additional
### Install manager (this is must)
goto ComfyUI/custom_nodes dir in terminal
git clone https://github.com/ltdrdata/ComfyUI-Manager comfyui-manager
Restart ComfyUI
- Read here: https://github.com/ltdrdata/ComfyUI-Manager

## TODO:
- ComfyUI related
    - Do you need to instal lcomfyui manager custom node?

    - Check civitai site, imgsys, openpose

- Controller Lambda page
    - Show if the EC2 GPU is running
    - Allow to start/stop EC2 GPU


## Copy file 
### Local to EC2
set LOCAL_PATH=D:\Users\kaushik.ashodiya\Documents\MyProjects\myllm\gpu-ec2\setup\setup.sh
set EC2_PATH=/home/ec2-user/
scp -i %PDIR%keys\main.pem %LOCAL_PATH% ec2-user@%EC2_IP_GPU%:%EC2_PATH%

### EC2 to Local
set LOCAL_PATH=
set EC2_PATH=
scp -i %PDIR%keys\main.pem ec2-user@%EC2_IP_GPU%:%EC2_PATH% %LOCAL_PATH% 


## Install docker compose
sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose
docker-compose --version


## n8n
docker volume create n8n_data
docker run -it --rm --name n8n -p 9103:5678 -v n8n_data:/home/node/.n8n docker.n8n.io/n8nio/n8n
- Access is via Caddy on 7103


## Install dify
git clone https://github.com/langgenius/dify.git
cd dify/docker
cp .env.example .env
docker-compose -p dify up -d
### Use LiteLLM
Bearer testtest
http://host.docker.internal:9108

Bedrock Anthropic Claude v3.5
anthropic.claude-3-5-sonnet-20240620-v1:0
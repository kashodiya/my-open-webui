# Developers guide


## EC2 setup 
- EC2 setup is done using user-data script.
- User data script is stored in ec2-user\user-data.sh file.
- Terraform adds some values as bash env variables at the top of the user-data.sh.
    - Check local.ec2_user_data in terraform\main.tf
- A S3 bucket is created with name <project_id>-data-<random_string>
- You can find the generated S3 bucket in terraform\set-tf-output-2-env-var.bat as DATA_BUCKET_NAME value.
- Computed ec2-serup.sh is copied to S3 data bucket by Terraform. 
    - In the user data script that file is copied to /root/ec2-setup.sh and executed.
- Terraform zips some of the folders like docker, caddy etc. and upload to S3 data bucket.
- These zip are downloaded on EC2 in ~/code folder. They are copied to ~/docket etc. folders before being used. 


## Monitoring EC2 setup
- When the setup starts it creates a flag file on S3 data bucket
    - myowu-ec2-setup-started
- When the setup ends it creates a flag file on S3 data bucket
    - myowu-ec2-setup-ended
- Thes flag files are used by the Controller lambda to let user know the status.
- To see live log of setup use:
    - scripts\ec2-setup-logs.bat
    - Or use Launcher shortcut ``esl``.
- You can see logs from EC2 by using ``tail_setup_log`` command.


## Controller Lambda
### How to tail the logs
- Use launcher shortcut:  
controller-tail  
- OR, Use this AWS CLI command  
aws logs tail /aws/lambda/myowu-controller --follow  


## IP address scheme
- All the ports between 7000 and 7999 are exposed authomatically by the EC2 security group
- For local ports that you do not want to expose use 8000 and onwards
- When using Caddy keep the port in sync, like this example:
    - Use Caddy to expose 7102 for app running on 8102 locally on EC2.
    - Using this scheme you will be able to guess the Caddy and the application ports, if you know any one of them!


## How to add a docker container
- Check a sample container included in this repo in: docker\n8n folder.
- To use this docker container run in CMD window:
```bat
cd docker
do.bat n8n up -d
```
- Once you see message ``Container n8n  Running``, press Ctrl+C
- Optional: 
    - Using Portainer verify that the container is running.
    - Using Code-server verify ~/docker/n8n folder and files.
- From CMD Launcher window run:
```bat
start http://%EIP_PUBLIC_DNS%:7107
```
- To remove containers (example):
```bat
do.bat n8n down
```
- Why to chamge files locally instead of on EC2?
    - In case we delete EC2 (in some case admins delete them every month), we have the source code and can create EC2 again easily.


## How to expose app using Caddy
- Lets assume that you are running an app on HTTP port 8107 on EC2
- The app is called my-app
- Create a file caddy\apps\my-app.Caddyfile
- Write following content in the file:
```text
# My App
:7107 {
    import common
    reverse_proxy localhost:8107
}
```
- Notice the ports pattern (replace 7 with 8)
- Keep the pattern of first and second line as it is, ecause this files are programatically read by scripts\generate-app-urls.py
- Run this command to update Caddy configurtion on EC2
```bat
cd caddy\apps
update.bat my-app.Caddyfile
```
- You will see the Caddy status. Verify that status is active.
- To test your app 
```bat
start http://%EIP_PUBLIC_DNS%:8107
```
- If your app is already running on HTTPS and you want to use Caddy, see the example: caddy\apps\portainer.Caddyfile

## How to create a Flask web app?
- Best example is web-apps\server-tool. Study that.
- Decide a app name. Let's say - my-app
- Create folder web-apps\my-app. 
- Create following files in that folder.
- Create app.py
    - Write a Flask app
- Create index.html
    - Write frontend
- Write my-app.Caddyfile
    - Decide the Caddy port and application port
- Go to ansible folder and create new folder my-app by copying server-app
    - Change the file server-app.yml to my-app.yml
- Run this commands in CMD:
```bat
cd ..\web-apps
update my-app
cd ..
cd ansible
run my-app
```


## ttyd
- What is ttyd?
    - Expose HTTP session over HTTP/web
    - You can also share a session in read only mode! Good for sharing live logs etc. 
- Source: https://github.com/tsl0922/ttyd
- Docs: https://github.com/tsl0922/ttyd/wiki/Example-Usage
- Do following on EC2
```bash
cd /tmp
git clone https://github.com/tsl0922/ttyd.git
cd ttyd
sudo bash scripts/cross-build.sh
cd build
sudo cp ttyd /usr/local/bin
```
- Run on HTTP (unsafe)
```bash
ttyd -W -p 7200 /usr/bin/bash
```
- Run as Docker (not useful as it SSH into docker container, and not EC2)
```bash
docker run -it --rm -p 7201:7681 tsl0922/ttyd
```
- TODO: Add Caddy to make it run on HTTPS


## Agno
- Intro: https://docs.agno.com/introduction
- Source: https://github.com/agno-agi/agno
- best tutorial: https://www.youtube.com/watch?v=s7Kkc6vA2K0
- Install
```cmd
cd caddy\apps
update.bat agno-ui.Caddyfile
cd ..\..
cd ansible
run agno-agent-ui
```
- Access agno on 7019 port


## How to create caddy user
- Create file: caddy/users.txt
- Generate pasword using ``caddy hash-password``
- Create entries in users.txt
caddy hash-password


## Seafile
me@example.com 
asecret 
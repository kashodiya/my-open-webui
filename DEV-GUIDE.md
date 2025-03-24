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
do.bat n8n up
```
- Once you see message ``Container n8n  Running``, press Ctrl+C
- Optional: 
    - Using Portainer verify that the container is running.
    - Using Code-server verify ~/docker/n8n folder and files.
- From CMD Launcher window run:
```bat
start http://%EIP_PUBLIC_DNS%:7107
```


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



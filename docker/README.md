


## How to use do.bat
### Add a docker contrainer
- Create a folder here
- Create a docker-compose.yml file in it
- To run it on the EC2, run following cmd from docker folder
```bat
do.bat <FOLDER-NAME> up
```
- To stop container
do.bat <FOLDER-NAME> down

## Best practice
- Always change the docker-compose.yml files locally. Do not modify on the EC2. 
    - This is because in case EC2 is deleted you have the source to start the docker again! 


## Special docker compose YML files
- Compose files in following folders contains placeholders:
    - bedrock-gateway
    - open-webui
    - portainer
- The placeholders are replaced by Terraform when creating user-data script for EC2.
- If you want to make changes and apply again on EC2:
    - Use Code-Server to copy contents of each compose files from ~/docker folder from EC2 server.
    - Paste the content in each respective docker-compose.yml files.
    - Now use can change the files and apply using do.bat file.



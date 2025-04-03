


## Install commands
- Source info: https://docs.dify.ai/getting-started/install-self-hosted/docker-compose
- SSH into EC2
cd docker
git clone https://github.com/langgenius/dify.git
cd dify/docker
cp .env.example .env

- Edit .env
Change EXPOSE_NGINX_PORT=9110

- Ensure Caddyfile has
:7110 {
    import common
    reverse_proxy localhost:9110
}

- Start containers
docker compose up -d

- To bring down (delete container)
docker compose down

- Access the app:
https://<url>:7110

## How to setup
- Login
First time enter uid/pwd
Login

## How to set LLM provider
- Go to: Admin -> Settings -> Model Providers
- Select: OpenAI-API-compatible
- Install 


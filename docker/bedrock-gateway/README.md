

## Build image before using it
- Run following script on the EC2
```bash
mkdir -p ~/temp
cd ~/temp
git clone https://github.com/aws-samples/bedrock-access-gateway.git
cd bedrock-access-gateway/src
docker build -t bedrock-gateway -f Dockerfile_ecs
cd ../..
rm -rf bedrock-access-gateway
```

- In Open WebUI
Settings => Admin Settings => Connections
Add OpenAI connection
http://host.docker.internal:8106/api/v1
123123




## Other


http://host.docker.internal:8106

http://bedrock-gateway:80

docker buildx build --platform linux/amd64

docker buildx build --platform linux/amd64 -f Do


docker build -t bedrock-gateway -f 





cd src
pip3 install -r requirements.txt -U --no-cache-dir

cd ~/temp/bedrock-access-gateway/src/

uvicorn api.app:app --host 0.0.0.0 --port 8000

export API_KEY_PARAM_NAME=BedrockProxyAPIKey
export OPENAI_API_KEY=123123
export OPENAI_BASE_URL=http://localhost:8000
export MODEL=anthropic.claude-3-5-sonnet-20240620-v1:0

curl $OPENAI_BASE_URL/chat/completions \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $OPENAI_API_KEY" \
  -d '{
    "model": "$MODEL$",
    "messages": [
      {
        "role": "user",
        "content": "Hello!"
      }
    ]
  }'
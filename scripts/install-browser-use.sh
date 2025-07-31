rm -rf ~/docker/web-ui
cd ~/docker
git clone https://github.com/browser-use/web-ui.git
cd web-ui
cp .env.example .env

EIP_PUBLIC_DNS=$(aws ssm get-parameter --name "/myowu/info" --query "Parameter.Value" --output text | jq -r ".eipPublicDns")
ADMIN_PASSWORD=$(aws ssm get-parameter --name "/myowu/info" --query "Parameter.Value" --output text 2>/dev/null | jq -r ".adminPassword" 2>/dev/null)

sed -i "s|^OPENAI_ENDPOINT=.*|OPENAI_ENDPOINT=http://$EIP_PUBLIC_DNS:8105|" .env
sed -i "s|^OPENAI_API_KEY=.*|OPENAI_API_KEY=$ADMIN_PASSWORD|" .env
sed -i "s|^VNC_PASSWORD=.*|VNC_PASSWORD=$ADMIN_PASSWORD|" .env

sed -i 's/7788:/8188:/' docker-compose.yml
sed -i 's/6080:/7189:/' docker-compose.yml

echo "Building image..."
docker build .
docker-compose up -d

echo "Updating SSM Parameter Store apps name..."
# Ensure jq is installed
# Get current parameter value
CURRENT_VALUE=$(aws ssm get-parameter --name "/myowu/apps" --query "Parameter.Value" --output text)

# Update the JSON using jq
UPDATED_VALUE=$(echo "$CURRENT_VALUE" | jq '(.[] | select(.id == "browser-use") | .name) = "Browser Use Web UI"')

# Put the updated parameter back
aws ssm put-parameter \
    --name "/myowu/apps" \
    --value "$UPDATED_VALUE" \
    --type "String" \
    --overwrite

echo "Parameter updated successfully!"

echo "Browser-Use Web UI installed and running at https://$EIP_PUBLIC_DNS:7188"
echo "VNC access at http://$EIP_PUBLIC_DNS:7189 with password: $ADMIN_PASSWORD"

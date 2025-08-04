# Check if the Perplexica directory exists
if [ -d ~/docker/Perplexica ]; then
    # If it exists, stop any running containers first
    echo "Found existing Perplexica installation, stopping containers..."
    cd ~/docker/Perplexica
    docker-compose down
    cd ~/
fi

# Now remove the directory and continue with setup
sudo rm -rf ~/docker/Perplexica
cd ~/docker
git clone https://github.com/ItzCrazyKns/Perplexica.git
cd Perplexica
cp sample.config.toml config.toml
sed -i 's/3000:/8130:/' docker-compose.yaml
echo "Running docker compose..."
docker-compose up -d
echo "App is running on 8130, access it via 7130"
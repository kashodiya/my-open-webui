


sudo systemctl start caddy
sudo systemctl stop caddy
sudo systemctl restart caddy
sudo systemctl status caddy
sudo systemctl enable caddy
sudo systemctl disable caddy

sudo systemctl reload caddy
sudo caddy reload --config /etc/caddy/Caddyfile

sudo caddy validate --config /etc/caddy/Caddyfile

sudo journalctl -u caddy


sudo cat /etc/caddy/Caddyfile
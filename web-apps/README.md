
## This is a quick and non-dirty web app and API server
- The server is run using 2 files (the ultimate minimalism)
    - app.py -> Server
    - index.html -> Client
    - Server as well client do not need compilation steps
- What do I mean by 'non-dirty'?
    - The client uses VueJs + Vuetify.
    - Even though it is single HTML file, the app is a rich SPA (Single Page Application)

## To install packages locally on windows
```bash
pip install -r requirements.txt
```

## To run
- Use --debug so that when you change any file, server reloads!
```bash
flask run --debug
```

## Manage system service
```bash
sudo systemctl restart server-tool
sudo systemctl status server-tool
sudo systemctl stop server-tool
sudo journalctl -u server-tool
sudo journalctl -fu server-tool

```

## When you change the requirements.txt (and also very first time)
- Run ansible
```bat
cd ansible
run <app-name>
```
- This will install python package on EC2
- Copy Caddyfile
- Generate app.json
- Create systemd service

## Tips
- For development run this app on Windows workspace. 
- When testing is over copy and run on server.
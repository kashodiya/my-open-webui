# Code server extensions

## What is this?
- Code server is VSCode running in your browser.
- Code server extension allows you to add functionality to code server.
- My utilities is a extension written in the most minimalistic way.
- There are only two files that make up this extension.
- One is configuration file and another JavaScript file.


## When you make any changes to the extension, run:
```bat
cd code-server-extensions
update <extension name>
```
- This command will copy your extension cord to EC2 server and deploy it.
- To test the extension open code-server in your browser. If it is already open, then just refresh the window.






## TODO:
- sudo dnf install nodejs -y
- sudo npm install -g vsce
- Zip code-server-extensions S3 unzip

- 
sudo journalctl -fu code-server@ec2-user


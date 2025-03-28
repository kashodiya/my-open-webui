const vscode = require('vscode');
const fs = require('fs');
const path = require('path');

// Define the path to the JSON file
const systemServicesFile = '/home/ec2-user/scripts/system-services.json';


function readJsonFile(filePath) {
	fs.readFile(filePath, 'utf8', (err, data) => {
		if (err) {
			console.error('Error reading the file:', err);
			return;
		}

		try {
			// Parse the JSON data
			const jsonData = JSON.parse(data);

			// Now you can work with the parsed JSON data
			console.log('Parsed JSON data:', jsonData);

			return jsonData

		} catch (parseError) {
			console.error('Error parsing JSON:', parseError);
		}
	});
}

// This method is called when your extension is activated
// Your extension is activated the very first time the command is executed
/**
 * @param {vscode.ExtensionContext} context
 */
function activate(context) {
	console.log('Activating my-utils extension.');

	// console.log(`my-utils: Reading: ${systemServicesFile}`);
	// let systemServices = readJsonFile(systemServicesFile);
	// systemServices.forEach(servince => {
	// });


// 	"command": "my-utils.show-jupyter-lab-logs",
// 	"title": "My Utils: Show Jupyter Lab logs"
//   },{
// 	"command": "my-utils.show-code-server-logs",

	const showCaddyLogs = vscode.commands.registerCommand('my-utils.show-caddy-logs', function () {
		executeInTerminal('sudo journalctl -fu caddy');
	});
	context.subscriptions.push(showCaddyLogs);

	const showJupyterLabLogs = vscode.commands.registerCommand('my-utils.show-jupyter-lab-logs', function () {
		executeInTerminal('sudo journalctl -fu jupyter-lab');
	});
	context.subscriptions.push(showJupyterLabLogs);

	const showCodeServerLogs = vscode.commands.registerCommand('my-utils.show-code-server-logs', function () {
		executeInTerminal('sudo journalctl -fu code-server@ec2-user');
	});
	context.subscriptions.push(showCodeServerLogs);

	const disposable1 = vscode.commands.registerCommand('my-utils.test', function () {
		vscode.window.showInformationMessage(readJsonFile(systemServicesFile));
	});

	context.subscriptions.push(disposable1);
}

function executeInTerminal(command) {
	let terminal = vscode.window.activeTerminal;

	if (!terminal) {
		// If there's no active terminal, create a new one
		terminal = vscode.window.createTerminal(`My Utils`);
	}

	terminal.show();
	terminal.sendText(command);
}

// This method is called when your extension is deactivated
function deactivate() { }

module.exports = {
	activate,
	deactivate
}

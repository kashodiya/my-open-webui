# Open WebUI Guide

## Figureout yourself how to do:
- Ask a question to a specific model.
- Ask a followup quetion.
- Regenerate an answer. How to view original answer?
- Ask Open WebUI to continue the an answer.
- Search a chat from chat history.
- Open and close left navigation panel.
- Pin, Rename, Delete, Download a chat from history.



## Exercises to learn Open WebUI
### Use more than one models simultaneoulsy
- Open Open WebUI
- Click New Chat
- Click '+' sign next to the model name
- Select another model
- Ask a quetion
- At the bottom right of the answers, click icon (Merge Response)
- Verify results
#### Challenge exercise
- Come up with innovative ideas to use this feature
- Discuss this ideas with Open WebUI

### Organize existing chats in custom folders
- Hover over "Chats" on left navigation panel
- Click '+' icon
- Double click Untitled
- Enter name of the folder, hit Enter
- Drag and drop an existing chat in this folder
#### Figureout yourself how to do:
- Move folders up or down
- Move a folder under another 
- Delete a folder
- Rename a folder


### Ask question to a web page


### A question with System Prompt
- Open Open WebUI
- Click New Chat
- Click top right icon for Controls
- System prompt: You are a biologist
- Question: What is a bug?
- Review the answer
- Change system prompt: You are a computer programmer
- Click icon for Regenerate at the bottom of the answer
- Review the answer
#### Challenge exercise
- What is the importance of a System Prompt?
- Chat with Open WebUI to explore more about System Prompt


## Cool experiments exercises

### Generate ERD diagram from DDL script
- Go to: https://learndatamodeling.com/blog/ddl-scripts-from-a-data-model/
- Copy DDL commands (text in yellow box)
- Open Open WebUI
- Type: Create ERD diagram from this DDL script:
- Press Ctrl+V to paste DDL
- Hit Enter
- Review the reply
- Ask: Generate Mermaid diagram
- Review the diagram
- Explore how to interact with diagram: Zoom in, out, download, refresh, copy etc.
#### Challenge exercise
- Come up with the ideas on how to use this feature?
- Chat with Open WebUI to explore more about your ideas



### Get insight from an ERD (Entity Relationship) diagram 
- Open this image in new browser tab
https://docs.yugabyte.com/images/sample-data/chinook/chinook-er-diagram.png
- Right click and copy image
- Open Open WebUI
- Select model: Claude 3 Haiku By Anthropic
- New chat
- Put your curser in question box
- Press Ctrl+V
- Type: Describe this ERD diagram:
- Hit Enter
- Review and verify the results.
#### Challenge exercise
- Come up with the ideas on how to use this feature?
- Chat with Open WebUI to explore more about your ideas

### Understand how Python execution and interpretation works
- Open Open WebUI
- New chat
- Select model: Claude 3 Haiku By Anthropic
- Click "Code Interpreter" button
- Enter question: Get current time
- Hit Enter
- Expand: Analyzed dropdown
- Check the time printed in "STDOUT/STDERR"
- Check the answer, it is the time of your laptop!
- Review the code
- Click Run button 
- Check the time printed in "STDOUT/STDERR"
- This is the time on the server!
- This code was executed on the Jupyter Lab running on the EC2 server!
#### Challenge exercise
- Come up with innovative ideas to use Pytyon code execution
- Discuss this ideas with Open WebUI
#### Challenge exercise 2
- Without writing single line of Python code get following things done just using Prompt Engineering:






## Misc
Write Jupyter Python code to run system command to copy "/var/lib/docker/volumes/open-webui_open-webui/_data/webui.db" file to "/tmp/webui.db" using sudo command.
Open that copied Sqlite file. 
Create Mermaid ERD diagram.

List records form user table.
List tables.

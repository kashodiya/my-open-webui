# Open WebUI Guide
## Figure out yourself how to do:
- Ask a question to a specific model.
- Ask a follow-up question.
- Regenerate an answer. How to view the original answer?
- Ask Open WebUI to continue an answer.
- Search a chat from chat history.
- Open and close the left navigation panel.
- Pin, Rename, Delete, Download a chat from history.

## Exercises to learn Open WebUI
### Use more than one model simultaneously
- Open Open WebUI
- Click New Chat
- Click '+' sign next to the model name
- Select another model
- Ask a question
- At the bottom right of the answers, click icon (Merge Response)
- Verify results
#### Challenge exercise
- Come up with innovative ideas to use this feature
- Discuss these ideas with Open WebUI
### Organize existing chats in custom folders
- Hover over "Chats" on left navigation panel
- Click '+' icon
- Double click Untitled
- Enter name of the folder, hit Enter
- Drag and drop an existing chat in this folder
#### Figure out yourself how to do:
- Move folders up or down
- Move a folder under another 
- Delete a folder
- Rename a folder

### Ask question to a web page
- Open this page in the browser: https://en.wikipedia.org/wiki/Apollo_11
- Copy URL
- Open Open WebUI
- Click New Chat
- In question box enter #
- Press Ctrl+V
- Hit Enter
- Type an Apollo 11 related question
#### Challenge exercise
- Use different models to try out the same questions
- Try out any other URLs
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
- Come up with ideas on how to use this feature?
- Chat with Open WebUI to explore more about your ideas

### Get insight from an ERD (Entity Relationship) diagram 
- Open this image in new browser tab
https://docs.yugabyte.com/images/sample-data/chinook/chinook-er-diagram.png
- Right click and copy image
- Open Open WebUI
- Select model: Claude 3 Haiku By Anthropic
- New chat
- Put your cursor in question box
- Press Ctrl+V
- Type: Describe this ERD diagram:
- Hit Enter
- Review and verify the results.
#### Challenge exercise
- Come up with ideas on how to use this feature?
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
- Come up with innovative ideas to use Python code execution
- Discuss these ideas with Open WebUI
#### Challenge exercise 2
- Without writing a single line of Python code, get the following things done just using Prompt Engineering:



## LiteLLM Exercise

### Explore LiteLLM APIs
- Open LiteLLM via Controller
- Click Authorize
- Enter your key
- Try out /models API
- Verify that you can see the list of models
#### Challenge exercise
- Explore other APIs


### Use LiteLLM to talk to Bedrock
- Open Jupyter Lab
- Navigate to /home/ec2-user
- Create new Notebook
- Paste following code and replace your key on line 3.
```python
import requests

url = "http://localhost:8105/v1/completions"
litellm_key = "YOUR-KEY-HERE"
headers = {"Authorization": f"Bearer {litellm_key}", "Content-Type": "application/json"}
question = "What is the capital of India?"
data = {
    "model": "Claude 3 Haiku By Anthropic", 
    "prompt": question,
    "max_tokens": 50
}

response = requests.post(url, headers=headers, json=data)
if response.status_code == 200:
    response = response.json().get("choices", [{}])[0].get("text", "No response")
    print(response)
else:
    print(f"Error: {response.status_code}, {response.text}")
```
- Run code
- Review code


### Use LangChain to talk to Bedrock via LiteLLM
- Open Jupyter Lab
- Navigate to /home/ec2-user
- Create new Notebook
- Run: pip install langchain langchain-community
- Paste following code and replace your key on line 3.
```python
from langchain.llms import OpenAI

llm = OpenAI(
    openai_api_base="http://localhost:8105/v1",  # Your LiteLLM server
    openai_api_key="YOUR-KEY-HERE",  # Required by LangChain but ignored by LiteLLM
    model_name="Claude 3 Haiku By Anthropic"
)
question = "What is the capital of India?"
response = llm.predict(question)
print(response)

```
- Run code
- Review code




## TODOs
- Add KB exercise
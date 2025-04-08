# Open WebUI Guide
## Figure out yourself how to do:
- Ask a question to a specific model.
- Ask a follow-up question.
- Regenerate an answer. How to view the original answer?
- Ask Open WebUI to continue an answer.
- Search a chat from chat history.
- Open and close the left navigation panel.
- Pin, Rename, Delete, Download a chat from history.
- How to set System Prompt for a chat? (Controls icon top right)
- How to set System Prompt (Settings->General)
- How to set model specific System Prompt (Settings->Admin Settings->Models->edit a model)
- Change theme (Settings->General)
- Create shortcut prompts. (Workspace->Prompts->Click '+')
- How to download a chat conversation? (top right ... icon)
- How to read aloud (text to audio) a answer?


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
- Enter question: Write python code to get current time
- OR: Write python code to get user name
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


## Advance Open WebUI features
### Tools
- Click Workspaces->Tools
- Click '+' icon on the top right
- Tool Name: My Tools
- Description: My tools
- Click Save
- Start new chat
- Click + sign in text box
- Switch on: My Tools
- Ask: What is my user name
- Ask: What is current user's email
#### Challenge exercise
- Click Workspaces->Tools
- Click Discover a tool
- Scroll down and explore some community tool
- Get inspired and create your own tool


### Pie that will echo your question
- Settings => Admin Settings => Functions
- Click '+' icon on top right.
- Name: Echo Pipe, Description: Echo the question
```python
from pydantic import BaseModel, Field


class Pipe:
    class Valves(BaseModel):
        MODEL_ID: str = Field(default="")

    def __init__(self):
        self.valves = self.Valves()

    def pipe(self, body: dict):
        # Logic goes here
        print(
            self.valves, body
        )  # This will print the configuration options and the input body

        question = body["messages"][0]["content"]

        return f"Body: {body}\nQuestion: {question}"
```
- Save
- On Functions page, enable Echo Pipe
- New chat
- Refresh page
- Select model - Echo Pipe
- Ask a question
#### Challenge exercise
- Create a Image Generation pipe
- Use this sample code to generate image:
https://docs.aws.amazon.com/bedrock/latest/userguide/bedrock-runtime_example_bedrock-runtime_InvokeModel_StableDiffusion_section.html
- Get inspired by: https://openwebui.com/f/bgeneto/dall_e 


## Use Ollama via Open WebUI
- Ollama is a server which can serve local LLM models
- You can also use Haggingface models
### Download and use Ollama model
- Open WebUI
- Go to top right icon -> Settings -> Admin Settings -> Connections
- In Manage Ollama API Connections section click Manage icon on the right side
- Enter model tag: mistral:7b
- Once donloaded, close the box
- New chat
- Select mistral:7b model
- Ask question
#### Challenge exercise
- Ask google and find other Ollam models
- Download a model
- Use it
- What difference you find?
- Why the model response is slow? 


## LiteLLM Exercise

### Explore LiteLLM APIs
- Open LiteLLM via Controller
- Click Authorize
- Enter your key
- Try out /models API
- Verify that you can see the list of models
#### Challenge exercise
- Explore other APIs


### Use LiteLLM proxy to talk to Bedrock
- Open Jupyter Lab
- Navigate to /home/ec2-user
- Create new Notebook
- Paste following code and replace your key on line 3.
```python
import os
import requests

url = "http://localhost:8105/v1/completions"
litellm_key = os.getenv('LITELLM_API_KEY')
headers = {"Authorization": f"Bearer {litellm_key}", "Content-Type": "application/json"}
question = "What is the capital of India?"
data = {
    "model": "Claude 3 Haiku By Anthropic (Served via LiteLLM)", 
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


### Use LangChain to talk to Bedrock via LiteLLM proxy
- Open Jupyter Lab
- Navigate to /home/ec2-user
- Create new Notebook
- Run: pip install langchain langchain-community
- Paste following code and replace your key on line 3.
```python
import os
from langchain.llms import OpenAI

openai_api_key = os.getenv('LITELLM_API_KEY')

llm = OpenAI(
    openai_api_base="http://localhost:8105/v1",  # Your LiteLLM server
    openai_api_key="YOUR-KEY-HERE",  # Required by LangChain but ignored by LiteLLM
    model_name="Claude 3 Haiku By Anthropic (Served via LiteLLM)"
)
question = "What is the capital of India?"
response = llm.predict(question)
print(response)
```
- Run code
- Review code


### Use LiteLLM python package directly
- Use Jupyter Lab to run following code.
    - Note that it expects "bedrock/anthropic.claude-3-haiku-20240307-v1:0" to be approved. Or use any text model that you have access. 
    - Edit code to use the real key.
```python
from litellm import completion

model="bedrock/anthropic.claude-3-haiku-20240307-v1:0"
prompt = "What is the capital of India"

response = completion(
  model=model, 
  messages=[{ "content": prompt,"role": "user"}]
)    

print(response.choices[0].message.content)
```


## EC2 and other tools guide
### Code-server
- File editor - VSCode
- Extensions
- Mutiple terminals
- Proxy server

### Jupyter
- Python development
- Terminal
- Extensions
- Open WebUI Python execution environment

### Portainer
- Manage docker containers, images, volumes remotely using GUI 
- Ease of trying out any Docker based solutions

### LiteLLM
- Explore and learn APIs
- Try API using key

### Caddy
- Reverse proxy
- HTTPS
- Authentication server

## TODOs
- Add RAG exercise
- Show Ollama?

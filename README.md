### Financial Data Extraction Tool Using LLM API (OpenAI / Groq)

This tool is a streamlit based app that uses openai api to extract key financial measures such as company name, stock symbol, revenue, net income etc. from a news article. The news article is typically an article about company's finance reporting. 

![Alt Text](./tool.png)


### Installation

#### 1. Clone the repository
```bash
https://github.com/sumitdas1984/financial_data_extraction_tool.git
```

#### 2. Create a Python environment
Python 3.8 or higher using `pyenv`. 

``` bash
cd gen-ai-experiments
python3 -m venv .venv
source .venv/bin/activate
```

#### 3. Install the required dependencies
```bash
pip install -r requirements.txt
```

#### 4. Set up the keys in a .env file
First, create a `.env` file in the root directory of the project. Inside the file, add your OpenAI and Groq API key:
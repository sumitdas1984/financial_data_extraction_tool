import os
# from dotenv import load_dotenv
from openai import OpenAI
from groq import Groq
import json
import pandas as pd
import re

# load_dotenv()  # Load environment variables from .env file

def extract_financial_data(text, llm_name="groq"):
    print("Extracting financial data using " + llm_name + " LLM")
    prompt = get_prompt_financial() + text
    # check if the llm is groq or openai
    if llm_name == "openai":
        client = OpenAI(api_key=os.environ.get("OPENAI_API_KEY"))
        response = client.chat.completions.create(
            model="gpt-3.5-turbo",
            messages=[
                {"role": "user","content": prompt}
            ]
        )
    else:
        client = Groq(api_key=os.environ.get("GROQ_API_KEY"))
        response = client.chat.completions.create(
            model="llama-3.3-70b-versatile",
            messages=[
                {"role": "user","content": prompt}
            ]
        )
        
    content = response.choices[0].message.content

    try:
        data = extract_json_from_llm_output(content)
        print("\nJSON data:\n" + str(data) + "\n-----\n")
        return pd.DataFrame(data.items(), columns=["Measure", "Value"])

    except (json.JSONDecodeError, IndexError):
        pass

    # Return empty DataFrame if JSON parsing fails
    return pd.DataFrame({
        "Measure": ["Company Name", "Stock Symbol", "Revenue", "Net Income", "EPS"],
        "Value": ["", "", "", "", ""]
    })


def extract_json_from_llm_output(text):
    # Remove triple backticks and optional language tag like ```json
    cleaned = re.sub(r"^```json\s*|```$", "", text.strip(), flags=re.IGNORECASE | re.MULTILINE)
    return json.loads(cleaned)


def get_prompt_financial():
    return '''Please retrieve company name, revenue, net income and earnings per share (a.k.a. EPS)
    from the following news article. If you can't find the information from this article 
    then return "". Do not make things up.    
    Then retrieve a stock symbol corresponding to that company. For this you can use
    your general knowledge (it doesn't have to be from this article). Always return your
    response as a valid JSON string. The format of that string should be this, 
    {
        "Company Name": "Walmart",
        "Stock Symbol": "WMT",
        "Revenue": "12.34 million",
        "Net Income": "34.78 million",
        "EPS": "2.1 $"
    }
    News Article:
    ============

    '''

# Press the green button in the gutter to run the script.
if __name__ == '__main__':
    llm_name = "groq"  # Change to "openai / groq"
    text = '''
    Tesla's Earning news in text format: Tesla's earning this quarter blew all the estimates. They reported 4.5 billion $ profit against a revenue of 30 billion $. Their earnings per share was 2.3 $
    '''
    df = extract_financial_data(text, llm_name)
    print(df.to_string())
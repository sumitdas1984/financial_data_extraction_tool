from dotenv import load_dotenv
import streamlit as st
import pandas as pd
import llm_helper

load_dotenv()  # Load environment variables from .env file

col1, col2 = st.columns([4,2])

financial_data_df = pd.DataFrame({
        "Measure": ["Company Name", "Stock Symbol", "Revenue", "Net Income", "EPS"],
        "Value": ["", "", "", "", ""]
    })

with col1:
    st.title("Data Extraction Tool")
    news_article = st.text_area("Paste your financial news article here", height=300)

    # Create a dropdown for selecting the LLM
    llm_options = ["Groq", "OpenAI"]
    selected_llm = st.selectbox("Select LLM:", llm_options, index=0)  # Groq is default

    if st.button("Extract"):
        # st.write(f"You selected: {selected_llm}")
        financial_data_df = llm_helper.extract_financial_data(news_article)

with col2:
    st.markdown("<br/>" * 5, unsafe_allow_html=True)  # Creates 5 lines of vertical space
    st.dataframe(
        financial_data_df,
        column_config={
            "Measure": st.column_config.Column(width=150),
            "Value": st.column_config.Column(width=150)
        },
        hide_index=True
    )
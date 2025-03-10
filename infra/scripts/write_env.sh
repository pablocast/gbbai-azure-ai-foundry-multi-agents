#!/bin/bash

# Define the .env file path
envFilePath=".env"

# Clear the contents of the .env file
> "$envFilePath"

# Append new values to the .env file
echo "PROJECT_CONNECTION_STRING=$(azd env get-value PROJECT_CONNECTION_STRING)" >> "$envFilePath"
echo "AZURE_SEARCH_ENDPOINT=$(azd env get-value AZURE_SEARCH_ENDPOINT)" >> "$envFilePath"
echo "AZURE_STORAGE_CONNECTION_STRING=$(azd env get-value AZURE_STORAGE_CONNECTION_STRING)" >> "$envFilePath"
echo "AZURE_STORAGE_CONTAINER_NAME=$(azd env get-value AZURE_STORAGE_CONTAINER_NAME)" >> "$envFilePath"
echo "AZURE_OPENAI_ENDPOINT=$(azd env get-value AZURE_OPENAI_ENDPOINT)" >> "$envFilePath"
echo "AZURE_OPENAI_EMBEDDING_MODEL_NAME=$(azd env get-value AZURE_OPENAI_EMBEDDING_MODEL_NAME)" >> "$envFilePath"
echo "AZURE_OPENAI_EMBEDDING_MODEL_VERSION=$(azd env get-value AZURE_OPENAI_EMBEDDING_MODEL_VERSION)" >> "$envFilePath"
echo "AZURE_OPENAI_4o_MODEL_NAME=$(azd env get-value AZURE_OPENAI_4o_MODEL_NAME)" >> "$envFilePath"
echo "TEMPLATE_DIR_PROMPTS=prompts/" >> "$envFilePath"
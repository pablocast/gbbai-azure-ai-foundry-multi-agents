Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass

$envFilePath = ".env"

If (Test-Path $envFilePath) {
    Remove-Item $envFilePath -Force
}
New-Item -Path $envFilePath -ItemType File -Force | Out-Null

Add-Content -Path $envFilePath -Value ("PROJECT_CONNECTION_STRING=" + (azd env get-value PROJECT_CONNECTION_STRING))
Add-Content -Path $envFilePath -Value ("AZURE_SEARCH_ENDPOINT=" + (azd env get-value AZURE_SEARCH_ENDPOINT))
Add-Content -Path $envFilePath -Value ("AZURE_STORAGE_CONNECTION_STRING=" + (azd env get-value AZURE_STORAGE_CONNECTION_STRING))
Add-Content -Path $envFilePath -Value ("AZURE_STORAGE_CONTAINER_NAME=" + (azd env get-value AZURE_STORAGE_CONTAINER_NAME))
Add-Content -Path $envFilePath -Value ("AZURE_OPENAI_ENDPOINT=" + (azd env get-value AZURE_OPENAI_ENDPOINT))
Add-Content -Path $envFilePath -Value ("AZURE_OPENAI_EMBEDDING_MODEL_NAME=" + (azd env get-value AZURE_OPENAI_EMBEDDING_MODEL_NAME))
Add-Content -Path $envFilePath -Value ("AZURE_OPENAI_EMBEDDING_MODEL_VERSION=" + (azd env get-value AZURE_OPENAI_EMBEDDING_MODEL_VERSION))
add-Content -Path $envFilePath -Value ("AZURE_OPENAI_API_KEY=" + (azd env get-value AZURE_OPENAI_API_KEY))
Add-Content -Path $envFilePath -Value ("AZURE_OPENAI_4o_MODEL_NAME=" + (azd env get-value AZURE_OPENAI_4o_MODEL_NAME))
# <img src="./utils/media/ai-foundry.jpg" alt="Azure Foundry" style="width:80px;height:30px"/> Azure AI Foundry Agent Service with Semantic Kernel

This directory contains Jupyter notebooks for hands-on exercises with Azure AI Foundry.

## 🔧 1.Prerequisites

+ [azd](https://learn.microsoft.com/azure/developer/azure-developer-cli/install-azd), used to deploy all Azure resources and assets used in this sample.

+ [azure functions core tools](https://learn.microsoft.com/en-us/azure/azure-functions/functions-run-local?tabs=windows%2Cisolated-process%2Cnode-v4%2Cpython-v2%2Chttp-trigger%2Ccontainer-apps&pivots=programming-language-csharp)

+ [PowerShell Core pwsh](https://github.com/PowerShell/powershell/releases) if using Windows

+ [Python 3.11](https://www.python.org/downloads/release/python-3110/)

## 🔧 2. Infrastructure Creation

This sample uses [`azd`](https://learn.microsoft.com/azure/developer/azure-developer-cli/) and a bicep template to deploy all Azure resources:

1. Login to your Azure account: `azd auth login`

2. Create an environment: `azd env new`

3. Place documents for testing inside [data](./data/) folder 

4. Run `azd up`.

   + Choose your Azure subscription.
   + Enter a region for the resources.

   The deployment creates multiple Azure resources and runs multiple jobs. It takes several minutes to complete. The deployment is complete when you get a command line notification stating "SUCCESS: Your up workflow to provision and deploy to Azure completed."


## 🚀 3. Run the Notebooks
- Execute the [1-create-index.ipynb](notebooks/1-create-infra.ipynb) to create the index that will be used be the Agents.
- Execute the [2-ai-agents.ipynb](notebooks/2-ai-agents.ipynb) to run the multi-agent example



## 💣 4.Deleting Infrastructure

You can delete the infrastruture created before by using `azd down --purge`
  

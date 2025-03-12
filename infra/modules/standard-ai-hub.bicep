// Creates an Azure AI resource with proxied endpoints for the Azure AI services provider

@description('Azure region of the deployment')
param location string

@description('Tags to add to the resources')
param tags object

@description('AI hub name')
param aiHubName string

@description('AI hub display name')
param aiHubFriendlyName string = aiHubName

@description('AI hub description')
param aiHubDescription string

@description('Resource ID of the key vault resource for storing connection strings')
param keyVaultId string

@description('Resource ID of the storage account resource for storing experimentation outputs')
param storageAccountId string

@description('Resource ID of the AI Services resource')
param aiServicesId string

@description('Resource ID of the AI Services endpoint')
param aiServicesTarget string

@description('Name AI Services resource')
param aiServicesName string

@description('Resource Group name of the AI Services resource')
param aiServiceAccountResourceGroupName string

@description('Subscription ID of the AI Services resource')
param aiServiceAccountSubscriptionId string

@description('Name AI Search resource')
param aiSearchName string

@description('Resource ID of the AI Search resource')
param aiSearchId string

@description('Resource ID of the Application Insights resource')
param appInsightsId string

@description('Resource Group name of the AI Search resource')
param aiSearchServiceResourceGroupName string

@description('Subscription ID of the AI Search resource')
param aiSearchServiceSubscriptionId string

@description('Name of the Bing Search resource')
param bingSearchName string

/* @description('Name for capabilityHost.')
param capabilityHostName string  */

@description('AI Service Account kind: either OpenAI or AIServices')
param aiServiceKind string 

var acsConnectionName = '${aiHubName}-connection-AISearch'

var aoaiConnection  = '${aiHubName}-connection-AIServices_aoai'

var bingConnectionName = '${aiHubName}-connection-BingSearch'

var kindAIServicesExists = aiServiceKind == 'AIServices'

var aiServiceConnectionName = kindAIServicesExists ? '${aiHubName}-connection-AIServices' : aoaiConnection

resource aiServices 'Microsoft.CognitiveServices/accounts@2024-10-01' existing = {
  name: aiServicesName
  scope: resourceGroup(aiServiceAccountSubscriptionId, aiServiceAccountResourceGroupName)
}

resource searchService 'Microsoft.Search/searchServices@2024-06-01-preview' existing = {
  name: aiSearchName
  scope: resourceGroup(aiSearchServiceSubscriptionId, aiSearchServiceResourceGroupName)
}

resource bingSearch 'Microsoft.Bing/accounts@2020-06-10' existing = {
  name: bingSearchName
  scope: resourceGroup(aiSearchServiceSubscriptionId, aiSearchServiceResourceGroupName)
}	


resource aiHub 'Microsoft.MachineLearningServices/workspaces@2024-10-01-preview' = {
  name: aiHubName
  location: location
  tags: tags
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    // organization
    friendlyName: aiHubFriendlyName
    description: aiHubDescription

    // dependent resources
    keyVault: keyVaultId
    applicationInsights: appInsightsId
    storageAccount: storageAccountId
    systemDatastoresAuthMode: 'identity'
  }
  kind: 'hub'

  resource aiServicesConnection 'connections@2024-07-01-preview' = {
    name: aiServiceConnectionName
    properties: {
      category: aiServiceKind // either AIServices or AzureOpenAI
      target: aiServicesTarget
      authType: 'AAD'
      isSharedToAll: true
      metadata: {
        ApiType: 'Azure'
        ResourceId: aiServicesId
        location: aiServices.location
      }
    }
  }

  resource hub_connection_azureai_search 'connections@2024-07-01-preview' = {
    name: acsConnectionName
    properties: {
      category: 'CognitiveSearch'
      target: 'https://${aiSearchName}.search.windows.net'
      authType: 'AAD'
      //useWorkspaceManagedIdentity: false
      isSharedToAll: true
      metadata: {
        ApiType: 'Azure'
        ResourceId: aiSearchId
        location: searchService.location
      }
    }
  }

  resource hub_connection_bing_search 'connections@2024-07-01-preview' = {
    name: bingConnectionName
    properties: {
      category: 'ApiKey'
      target: 'https://api.bing.microsoft.com/'
      authType: 'ApiKey'
      isSharedToAll: true
      metadata: {
        ApiVersion: '2024-02-01'
        ApiType: 'Azure'
        ResourceId: bingSearch.id
        location: 'global'
      }
      credentials: {
        key: bingSearch.listKeys().key1
      }
    }
  }
}

output aiHubID string = aiHub.id
output aiHubName string = aiHub.name
output aoaiConnectionName string = aoaiConnection
output acsConnectionName string = acsConnectionName

// Creates Azure dependent resources for Azure AI Agent Service standard agent setup

@description('Azure region of the deployment')
param location string = resourceGroup().location

@description('Tags to add to the resources')
param tags object = {}

@description('AI services name')
param aiServicesName string

@description('The name of the Key Vault')
param keyvaultName string

@description('The name of the AI Search resource')
param aiSearchName string

@description('Name of the storage account')
param storageName string

var storageNameCleaned = replace(storageName, '-', '')

@description('Model name for deployment')
param modelName string 

@description('Model format for deployment')
param modelFormat string 

@description('Model version for deployment')
param modelVersion string 

@description('Model deployment SKU name')
param modelSkuName string 

@description('Model deployment capacity')
param modelCapacity int 

@description('Embedding model name for deployment')
param embeddingModelName string

@description('Embedding model format for deployment')
param embeddingModelFormat string

@description('Embedding model version for deployment')
param embeddingModelVersion string

@description('Embedding model SKU name')
param embeddingModelSkuName string

@description('Embedding model capacity')
param embeddingModelCapacity int

@description('Model/AI Resource deployment location')
param modelLocation string 

@description('The AI Service Account full ARM Resource ID. This is an optional field, and if not provided, the resource will be created.')
param aiServiceAccountResourceId string

@description('The AI Search Service full ARM Resource ID. This is an optional field, and if not provided, the resource will be created.')
param aiSearchServiceResourceId string 

@description('The AI Storage Account full ARM Resource ID. This is an optional field, and if not provided, the resource will be created.')
param aiStorageAccountResourceId string 

@description('The name of the Bing Search resource')
param bingSearchName string

@description('The name of the Log Analytics workspace')
param logAnalyticsName string 

@description('The name of the Application Insights resource')
param insightsName string 

var aiServiceExists = aiServiceAccountResourceId != ''
var acsExists = aiSearchServiceResourceId != ''
var aiStorageExists = aiStorageAccountResourceId != ''

resource keyVault 'Microsoft.KeyVault/vaults@2022-07-01' = {
  name: keyvaultName
  location: location
  tags: tags
  properties: {
    createMode: 'default'
    enabledForDeployment: false
    enabledForDiskEncryption: false
    enabledForTemplateDeployment: false
    enableSoftDelete: true
    enableRbacAuthorization: true
    enablePurgeProtection: true
    networkAcls: {
      bypass: 'AzureServices'
      defaultAction: 'Deny'
    }
    sku: {
      family: 'A'
      name: 'standard'
    }
    softDeleteRetentionInDays: 7
    tenantId: subscription().tenantId
  }
}


var aiServiceParts = split(aiServiceAccountResourceId, '/')

resource existingAIServiceAccount 'Microsoft.CognitiveServices/accounts@2024-10-01' existing = if (aiServiceExists) {
  name: aiServiceParts[8]
  scope: resourceGroup(aiServiceParts[2], aiServiceParts[4])
}

resource aiServices 'Microsoft.CognitiveServices/accounts@2024-10-01' = if(!aiServiceExists) {
  name: aiServicesName
  location: modelLocation
  sku: {
    name: 'S0'
  }
  kind: 'AIServices' // or 'OpenAI'
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    customSubDomainName: toLower('${(aiServicesName)}')
    apiProperties: {
      statisticsEnabled: false
    }
    publicNetworkAccess: 'Enabled'
  }
}

// Generative
resource modelDeployment 'Microsoft.CognitiveServices/accounts/deployments@2024-10-01'= if(!aiServiceExists){
  parent: aiServices
  name: modelName
  sku : {
    capacity: modelCapacity
    name: modelSkuName
  }
  properties: {
    model:{
      name: modelName
      format: modelFormat
      version: modelVersion
    }
  }
}

// Embedding
resource embeddingDeployment 'Microsoft.CognitiveServices/accounts/deployments@2024-10-01'= if(!aiServiceExists){
  parent: aiServices
  name: embeddingModelName
  sku : {
    capacity: embeddingModelCapacity
    name: embeddingModelSkuName
  }
  properties: {
    model:{
      name: embeddingModelName
      format: embeddingModelFormat
      version: embeddingModelVersion
    }
  }
  dependsOn: [modelDeployment]
}

var acsParts = split(aiSearchServiceResourceId, '/')

resource existingSearchService 'Microsoft.Search/searchServices@2024-06-01-preview' existing = if (acsExists) {
  name: acsParts[8]
  scope: resourceGroup(acsParts[2], acsParts[4])
}
resource aiSearch 'Microsoft.Search/searchServices@2024-06-01-preview' = if(!acsExists) {
  name: aiSearchName
  location: location
  tags: tags
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    disableLocalAuth: false
    authOptions: { aadOrApiKey: { aadAuthFailureMode: 'http401WithBearerChallenge'}}
    encryptionWithCmk: {
      enforcement: 'Unspecified'
    }
    hostingMode: 'default'
    partitionCount: 1
    publicNetworkAccess: 'enabled'
    replicaCount: 1
    semanticSearch: 'Standard'
  }
  sku: {
    name: 'standard'
  }
}

resource bingSearch 'Microsoft.Bing/accounts@2020-06-10' = {
  name: bingSearchName
  location: 'global'
  kind: 'Bing.Grounding'
  sku: {
    name: 'G1'
  }
}


var aiStorageParts = split(aiStorageAccountResourceId, '/')

resource existingAIStorageAccount 'Microsoft.Storage/storageAccounts@2023-05-01' existing = if (aiStorageExists) {
  name: aiStorageParts[8]
  scope: resourceGroup(aiStorageParts[2], aiStorageParts[4])
}

// Some regions doesn't support Standard Zone-Redundant storage, need to use Geo-redundant storage
param noZRSRegions array = ['southindia', 'westus']
param sku object = contains(noZRSRegions, location) ? { name: 'Standard_GRS' } : { name: 'Standard_ZRS' }

resource storage 'Microsoft.Storage/storageAccounts@2023-05-01' = if(!aiStorageExists) {
  name: storageNameCleaned
  location: location
  kind: 'StorageV2'
  sku: sku
  properties: {
    minimumTlsVersion: 'TLS1_2'
    allowBlobPublicAccess: false
    publicNetworkAccess: 'Enabled'
    networkAcls: {
      bypass: 'AzureServices'
      defaultAction: 'Allow'
      virtualNetworkRules: []
    }
    allowSharedKeyAccess: true
  }
}

resource blobService 'Microsoft.Storage/storageAccounts/blobServices@2023-01-01' = {
  parent: storage
  name: 'default'
  properties: {
    deleteRetentionPolicy: {
      enabled: true
      days: 7
    }
  }
}

resource logAnalytics 'Microsoft.OperationalInsights/workspaces@2023-09-01' = {
  name: logAnalyticsName
  location: location
  properties: any({
    retentionInDays: 30
    features: {
      searchVersion: 1
    }
    sku: {
      name: 'PerGB2018'
    }
  })
}


resource applicationInsights 'Microsoft.Insights/components@2020-02-02' = {
  name: insightsName
  location: location
  tags: {}
  kind: 'web'
  properties: {
    Application_Type: 'web'
    WorkspaceResourceId: logAnalytics.id
    CustomMetricsOptedInType: 'WithDimensions'
  }
}

output aiServicesName string =  aiServiceExists ? existingAIServiceAccount.name : aiServicesName
output aiservicesID string = aiServiceExists ? existingAIServiceAccount.id : aiServices.id
output aiservicesTarget string = aiServiceExists ? existingAIServiceAccount.properties.endpoint : aiServices.properties.endpoint
output aiServiceAccountResourceGroupName string = aiServiceExists ? aiServiceParts[4] : resourceGroup().name
output aiServiceAccountSubscriptionId string = aiServiceExists ? aiServiceParts[2] : subscription().subscriptionId 

output aiSearchName string = acsExists ? existingSearchService.name : aiSearch.name
output aisearchID string = acsExists ? existingSearchService.id : aiSearch.id
output aiSearchServiceResourceGroupName string = acsExists ? acsParts[4] : resourceGroup().name
output aiSearchServiceSubscriptionId string = acsExists ? acsParts[2] : subscription().subscriptionId

output storageAccountName string = aiStorageExists ? existingAIStorageAccount.name :  storage.name
output storageId string =  aiStorageExists ? existingAIStorageAccount.id :  storage.id
output storageAccountResourceGroupName string = aiStorageExists ? aiStorageParts[4] : resourceGroup().name
output storageAccountSubscriptionId string = aiStorageExists ? aiStorageParts[2] : subscription().subscriptionId

var storageKeys = storage.listKeys()
var primaryKey = storageKeys.keys[0].value
output storageAccountConnectionString string = 'DefaultEndpointsProtocol=https;AccountName=${storage.name};AccountKey=${primaryKey};EndpointSuffix=core.windows.net'

output openAIEndpoint string = 'https://${aiServices.name}.openai.azure.com'
var aiServicesKeys = aiServices.listKeys()
output openAIKey string = aiServicesKeys.key1

output bingSearchName string = bingSearch.name
var bingSearchKeys = bingSearch.listKeys()
output bingSearchKey string = bingSearchKeys.key1

output keyvaultId string = keyVault.id

output applicationInsightsId string = applicationInsights.id

output applicationInsightsConnectionString string = 'InstrumentationKey=${applicationInsights.properties.InstrumentationKey};IngestionEndpoint=https://eastus-8.in.applicationinsights.azure.com/;LiveEndpoint=https://eastus.livediagnostics.monitor.azure.com/;ApplicationId=${applicationInsights.properties.AppId}'

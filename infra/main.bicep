// Execute this main file to deploy Standard Agent setup resources

// Parameters
@description('The principal ID of the user or service principal that will be assigned the role.')
param principalId string

@minLength(2)
@maxLength(12)
@description('Name for the AI resource and used to derive name of dependent resources.')
param aiHubName string = 'hub-demo'

@description('Friendly name for your Hub resource')
param aiHubFriendlyName string = 'Agents Hub resource'

@description('Description of your Azure AI resource displayed in AI studio')
param aiHubDescription string = 'This is an example AI resource for use in Azure AI Studio.'

@description('Name for the AI project resources.')
param aiProjectName string = 'project-demo'

@description('Friendly name for your Azure AI resource')
param aiProjectFriendlyName string = 'Agents Project resource'

@description('Description of your Azure AI resource displayed in AI studio')
param aiProjectDescription string = 'This is an example AI Project resource for use in Azure AI Studio.'

@description('Azure region used for the deployment of all resources.')
param location string = resourceGroup().location

@description('Set of tags to apply to all resources.')
param tags object = {}

@description('Name of the Azure AI Search account')
param aiSearchName string = 'agent-ai-search'

@description('Name for capabilityHost.')
param capabilityHostName string = 'caphost1'

@description('Name of the storage account')
param storageName string = 'agent-storage'

@description('Name of the Azure AI Services account')
param aiServicesName string = 'agent-ai-services'

@description('Model name for deployment')
param modelName string = 'gpt-4o'

@description('Model format for deployment')
param modelFormat string = 'OpenAI'

@description('Model version for deployment')
param modelVersion string = '2024-08-06'

@description('Model deployment SKU name')
param modelSkuName string = 'GlobalStandard'

@description('Model deployment capacity')
param modelCapacity int = 50

@description('Embedding model name for deployment')
param embeddingModelName string = 'text-embedding-3-large'

@description('Embedding model format for deployment')
param embeddingModelFormat string = 'OpenAI'

@description('Embedding model version for deployment')
param embeddingModelVersion string = '1'

@description('Embedding model deployment SKU name')
param embeddingModelSkuName string = 'Standard'

@description('Embedding model deployment capacity')
param embeddingModelCapacity int = 100


@description('Model deployment location. If you want to deploy an Azure AI resource/model in different location than the rest of the resources created.')
param modelLocation string = 'eastus'

@description('AI Service Account kind: either AzureOpenAI or AIServices')
param aiServiceKind string = 'AIServices'

@description('The AI Service Account full ARM Resource ID. This is an optional field, and if not provided, the resource will be created.')
param aiServiceAccountResourceId string = ''

@description('The Ai Search Service full ARM Resource ID. This is an optional field, and if not provided, the resource will be created.')
param aiSearchServiceResourceId string = ''

@description('The Ai Storage Account full ARM Resource ID. This is an optional field, and if not provided, the resource will be created.')
param aiStorageAccountResourceId string = ''

// Variables
var name = toLower('${aiHubName}')
var projectName = toLower('${aiProjectName}')

// Create a short, unique suffix, that will be unique to each resource group
// var uniqueSuffix = substring(uniqueString(resourceGroup().id), 0, 4)
param deploymentTimestamp string = utcNow('yyyyMMddHHmmss')
var uniqueSuffix = substring(uniqueString('${resourceGroup().id}-${deploymentTimestamp}'), 0, 4)

var aiServiceExists = aiServiceAccountResourceId != ''
var acsExists = aiSearchServiceResourceId != ''

var aiServiceParts = split(aiServiceAccountResourceId, '/')
var aiServiceAccountSubscriptionId = aiServiceExists ? aiServiceParts[2] : subscription().subscriptionId 
var aiServiceAccountResourceGroupName = aiServiceExists ? aiServiceParts[4] : resourceGroup().name

var acsParts = split(aiSearchServiceResourceId, '/')
var aiSearchServiceSubscriptionId = acsExists ? acsParts[2] : subscription().subscriptionId
var aiSearchServiceResourceGroupName = acsExists ? acsParts[4] : resourceGroup().name

// Dependent resources for the Azure Machine Learning workspace
module aiDependencies 'modules/standard-dependent-resources.bicep' = {
  name: 'dependencies-${name}-${uniqueSuffix}-deployment'
  params: {
    location: location
    storageName: '${storageName}${uniqueSuffix}'
    keyvaultName: 'kv-${name}-${uniqueSuffix}'
    aiServicesName: '${aiServicesName}${uniqueSuffix}'
    aiSearchName: '${aiSearchName}-${uniqueSuffix}'
    tags: tags

     // Model deployment parameters - Completion model
     modelName: modelName
     modelFormat: modelFormat
     modelVersion: modelVersion
     modelSkuName: modelSkuName
     modelCapacity: modelCapacity  
     modelLocation: modelLocation

    // Model deployment parameters - Embedding model
    embeddingModelName: embeddingModelName
    embeddingModelFormat: embeddingModelFormat
    embeddingModelVersion: embeddingModelVersion
    embeddingModelSkuName: embeddingModelSkuName
    embeddingModelCapacity: embeddingModelCapacity

     aiServiceAccountResourceId: aiServiceAccountResourceId
     aiSearchServiceResourceId: aiSearchServiceResourceId
     aiStorageAccountResourceId: aiStorageAccountResourceId

     // Bing search
      bingSearchName: 'bingsearch-${uniqueSuffix}'
    }
}

module aiHub 'modules/standard-ai-hub.bicep' = {
  name: '${name}-${uniqueSuffix}-deployment'
  params: {
    // workspace organization
    aiHubName: '${name}-${uniqueSuffix}'
    aiHubFriendlyName: aiHubFriendlyName
    aiHubDescription: aiHubDescription
    location: location
    tags: tags

    aiSearchName: aiDependencies.outputs.aiSearchName
    aiSearchId: aiDependencies.outputs.aisearchID
    aiSearchServiceResourceGroupName: aiDependencies.outputs.aiSearchServiceResourceGroupName
    aiSearchServiceSubscriptionId: aiDependencies.outputs.aiSearchServiceSubscriptionId

    aiServicesName: aiDependencies.outputs.aiServicesName
    aiServiceKind: aiServiceKind
    aiServicesId: aiDependencies.outputs.aiservicesID
    aiServicesTarget: aiDependencies.outputs.aiservicesTarget
    aiServiceAccountResourceGroupName:aiDependencies.outputs.aiServiceAccountResourceGroupName
    aiServiceAccountSubscriptionId:aiDependencies.outputs.aiServiceAccountSubscriptionId
    
    keyVaultId: aiDependencies.outputs.keyvaultId
    storageAccountId: aiDependencies.outputs.storageId

    bingSearchName: aiDependencies.outputs.bingSearchName
  }
}

module aiProject 'modules/standard-ai-project.bicep' = {
  name: '${projectName}-${uniqueSuffix}-deployment'
  params: {
    // workspace organization
    aiProjectName: '${projectName}-${uniqueSuffix}'
    aiProjectFriendlyName: aiProjectFriendlyName
    aiProjectDescription: aiProjectDescription
    location: location
    tags: tags
    aiHubId: aiHub.outputs.aiHubID
  }
}

module aiServiceRoleAssignments 'modules/ai-service-role-assignments.bicep' = {
  name: 'ai-service-role-assignments-${projectName}-${uniqueSuffix}-deployment'
  scope: resourceGroup(aiServiceAccountSubscriptionId, aiServiceAccountResourceGroupName)
  params: {
    aiServicesName: aiDependencies.outputs.aiServicesName
    aiProjectPrincipalId: aiProject.outputs.aiProjectPrincipalId
    aiProjectId: aiProject.outputs.aiProjectResourceId
  }
}

module aiSearchRoleAssignments 'modules/ai-search-role-assignments.bicep' = {
  name: 'ai-search-role-assignments-${projectName}-${uniqueSuffix}-deployment'
  scope: resourceGroup(aiSearchServiceSubscriptionId, aiSearchServiceResourceGroupName)
  params: {
    aiSearchName: aiDependencies.outputs.aiSearchName
    aiProjectPrincipalId: aiProject.outputs.aiProjectPrincipalId
    aiProjectId: aiProject.outputs.aiProjectResourceId
  }
}

module storageRoleAssignments 'modules/storage-role-assignments.bicep' = {
  name: 'storage-role-assignments-${projectName}-${uniqueSuffix}-deployment'
  scope: resourceGroup(aiServiceAccountSubscriptionId, aiServiceAccountResourceGroupName)
  params: {
    storageAccountName: aiDependencies.outputs.storageAccountName
    principalId: principalId
  }
}

module addCapabilityHost 'modules/add-capability-host.bicep' = {
  name: 'capabilityHost-configuration--${uniqueSuffix}-deployment'
  params: {
    capabilityHostName: '${uniqueSuffix}-${capabilityHostName}'
    aiHubName: aiHub.outputs.aiHubName
    aiProjectName: aiProject.outputs.aiProjectName
    acsConnectionName: aiHub.outputs.acsConnectionName
    aoaiConnectionName: aiHub.outputs.aoaiConnectionName
  }
  dependsOn: [
    aiSearchRoleAssignments,aiServiceRoleAssignments
  ]
}

output PROJECT_CONNECTION_STRING string = aiProject.outputs.projectConnectionString
output AZURE_SEARCH_ENDPOINT string = 'https://${aiDependencies.outputs.aiSearchName}.search.windows.net'
output AZURE_STORAGE_CONNECTION_STRING string = aiDependencies.outputs.storageAccountConnectionString
output AZURE_STORAGE_CONTAINER_NAME string = aiDependencies.outputs.storageAccountContainerName
output AZURE_OPENAI_ENDPOINT string = aiDependencies.outputs.openAIEndpoint
output AZURE_OPENAI_EMBEDDING_MODEL_NAME string = embeddingModelName
output AZURE_OPENAI_EMBEDDING_MODEL_VERSION string = embeddingModelVersion
output AZURE_OPENAI_4o_MODEL_NAME string = modelName
output AZURE_OPENAI_API_KEY string = aiDependencies.outputs.openAIKey
output AZURE_BING_API_KEY string = aiDependencies.outputs.bingSearchKey

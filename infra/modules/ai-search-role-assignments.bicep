// Assigns the necessary roles to the AI project

@description('Name of the AI Search resource')
param aiSearchName string

@description('Principal ID of the AI project')
param aiProjectPrincipalId string

@description('Resource ID of the AI project')
param aiProjectId string

resource searchService 'Microsoft.Search/searchServices@2024-06-01-preview' existing = {
  name: aiSearchName
  scope: resourceGroup()
}

// search roles
resource searchIndexDataContributorRole 'Microsoft.Authorization/roleDefinitions@2022-04-01' existing = {
  name: '8ebe5a00-799e-43f5-93ac-243d3dce84a7'
  scope: resourceGroup()
}

resource searchIndexDataContributorAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  scope: searchService
  name: guid(aiProjectId, searchIndexDataContributorRole.id, searchService.id)
  properties: {
    principalId: aiProjectPrincipalId
    roleDefinitionId: searchIndexDataContributorRole.id
    principalType: 'ServicePrincipal'
  }
}

resource searchServiceContributorRole 'Microsoft.Authorization/roleDefinitions@2022-04-01' existing = {
  name: '7ca78c08-252a-4471-8644-bb5ff32d4ba0'
  scope: resourceGroup()
}

resource searchServiceContributorRoleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  scope: searchService
  name: guid(aiProjectId, searchServiceContributorRole.id, searchService.id)
  properties: {
    principalId: aiProjectPrincipalId
    roleDefinitionId: searchServiceContributorRole.id
    principalType: 'ServicePrincipal'
  }
}

resource searchServiceStorageReaderRole 'Microsoft.Authorization/roleDefinitions@2022-04-01' existing = {
  name: '2a2b9908-6ea1-4ae2-8e65-a410df84e7d1'
  scope: resourceGroup()
}

// For integrated vectorization access to storage
resource storageRoleSearchService 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  scope: searchService
  name: guid(aiProjectId, searchServiceStorageReaderRole.id, searchService.id)
  properties: {
    principalId: aiProjectPrincipalId
    roleDefinitionId: searchServiceStorageReaderRole.id
    principalType: 'ServicePrincipal'
  }
}

// Search Index Data Contributor
var assignee = subscription().subscriptionId
resource roleAssignment 'Microsoft.Authorization/roleAssignments@2020-04-01-preview' = {
  name: guid(resourceGroup().id, assignee,  searchIndexDataContributorRole.id)
  scope: resourceGroup()
  properties: {
    principalId: assignee
    roleDefinitionId: searchIndexDataContributorRole.id
  }
}

targetScope = 'resourceGroup'

@minLength(1)
@maxLength(64)
@description('Name of the environment (used for resource naming)')
param environmentName string

@description('Primary Azure region for resources')
param location string

@description('Principal ID of the user who needs Foundry access (defaults to the deployer)')
param foundryUserPrincipalId string = deployer().objectId

@description('Deploy Azure AI Search and connect it to the Foundry project for the optional Foundry IQ exercise')
param deployAzureAiSearch bool = false

@description('App Service Plan SKU. Raise this if the target region reports no available instances for B1.')
@allowed(['B1', 'B2', 'B3', 'S1', 'S2', 'P0V3', 'P1V3', 'P2V3'])
param appServicePlanSku string = 'B1'

var tags = {
  'azd-env-name': environmentName
}

var resourceToken = toLower(uniqueString(resourceGroup().id, environmentName, location))

module appService 'modules/app-service.bicep' = {
  name: 'app-service'
  params: {
    appServicePlanName: 'plan-${resourceToken}'
    webAppName: 'app-${resourceToken}'
    location: location
    tags: tags
    appServicePlanSku: appServicePlanSku
  }
}

module foundry 'modules/foundry.bicep' = {
  name: 'foundry'
  params: {
    accountName: 'foundry-${resourceToken}'
    projectName: 'agents-lab'
    location: location
    tags: tags
  }
}

module azureAiSearch 'modules/azure-ai-search.bicep' = if (deployAzureAiSearch) {
  name: 'azure-ai-search'
  params: {
    searchServiceName: 'srch-${resourceToken}'
    foundryAccountName: foundry.outputs.accountName
    foundryProjectName: foundry.outputs.projectName
    foundryUserPrincipalId: foundryUserPrincipalId
    location: location
    tags: tags
  }
}

module observability 'modules/observability.bicep' = {
  name: 'observability'
  params: {
    logAnalyticsWorkspaceName: 'log-${resourceToken}'
    applicationInsightsName: 'appi-${resourceToken}'
    foundryAccountName: foundry.outputs.accountName
    foundryProjectName: foundry.outputs.projectName
    foundryUserPrincipalId: foundryUserPrincipalId
    location: location
    tags: tags
  }
}

module bingGrounding 'modules/bing-grounding.bicep' = {
  name: 'bing-grounding'
  params: {
    bingName: 'bing-${resourceToken}'
    foundryName: foundry.outputs.accountName
    foundryProjectName: foundry.outputs.projectName
    tags: tags
  }
}

module roleAssignments 'modules/role-assignments.bicep' = {
  name: 'role-assignments'
  params: {
    principalId: appService.outputs.webAppPrincipalId
    foundryId: foundry.outputs.accountId
  }
}

module userRoleAssignments 'modules/role-assignments.bicep' = {
  name: 'user-role-assignments'
  params: {
    principalId: foundryUserPrincipalId
    principalType: 'User'
    foundryId: foundry.outputs.accountId
  }
}

output AZURE_RESOURCE_GROUP string = resourceGroup().name
output AZURE_WEBAPP_NAME string = appService.outputs.webAppName
output AZURE_WEBAPP_URL string = appService.outputs.webAppUrl
output AZURE_FOUNDRY_NAME string = foundry.outputs.accountName
output AZURE_FOUNDRY_ENDPOINT string = foundry.outputs.accountEndpoint
output AZURE_BING_NAME string = bingGrounding.outputs.bingName
output AZURE_BING_CONNECTION_NAME string = bingGrounding.outputs.bingConnectionName
output AZURE_AI_SEARCH_NAME string = deployAzureAiSearch ? azureAiSearch.outputs.searchServiceName : ''
output AZURE_AI_SEARCH_ENDPOINT string = deployAzureAiSearch ? azureAiSearch.outputs.searchServiceEndpoint : ''
output AZURE_AI_SEARCH_CONNECTION_NAME string = deployAzureAiSearch ? azureAiSearch.outputs.searchConnectionName : ''
output AZURE_APPLICATION_INSIGHTS_NAME string = observability.outputs.applicationInsightsName
output AZURE_LOG_ANALYTICS_WORKSPACE_NAME string = observability.outputs.logAnalyticsWorkspaceName

@description('Name of the Grounding with Bing resource')
param bingName string

@description('Tags to apply to resources')
param tags object = {}

@description('Name of the Foundry resource')
param foundryName string

@description('Name of the Foundry project')
param foundryProjectName string

var connectionName = 'grounding-with-bing'

#disable-next-line BCP081
resource foundryAccount 'Microsoft.CognitiveServices/accounts@2025-04-01-preview' existing = {
  name: foundryName
  scope: resourceGroup()
}

#disable-next-line BCP081
resource foundryProject 'Microsoft.CognitiveServices/accounts/projects@2025-04-01-preview' existing = {
  parent: foundryAccount
  name: foundryProjectName
}

resource bingGrounding 'Microsoft.Bing/accounts@2025-05-01-preview' = {
  name: bingName
  location: 'global'
  tags: tags
  kind: 'Bing.Grounding'
  sku: {
    name: 'G1'
  }
  properties: {}
}

#disable-next-line BCP081
resource bingConnection 'Microsoft.CognitiveServices/accounts/projects/connections@2025-04-01-preview' = {
  name: connectionName
  parent: foundryProject
  properties: {
    category: 'ApiKey'
    target: bingGrounding.properties.endpoint
    authType: 'ApiKey'
    credentials: {
      key: '${listKeys(bingGrounding.id, '2020-06-10').key1}'
    }
    isSharedToAll: true
    metadata: {
      ApiType: 'Azure'
      location: bingGrounding.location
      ResourceId: bingGrounding.id
    }
  }
}

output bingName string = bingGrounding.name
output bingId string = bingGrounding.id
output bingConnectionName string = bingConnection.name

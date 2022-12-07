targetScope = 'resourceGroup'

param envName string
param sku string = 'P1v2'                                   // The SKU of App Service Plan
param linuxFxVersion string = 'DOTNETCORE|6.0'              // The runtime stack of web app
param location string = resourceGroup().location            // Location for all resources

//
// Log Analytics & App Insights
//

resource logAnalyticsWorkspace 'Microsoft.OperationalInsights/workspaces@2020-08-01' = {
  name: '${envName}-logs'
  location: location
  properties: {
    sku: {
      name: 'PerGB2018'
    }
    retentionInDays: 30
    features: {
      searchVersion: 1
      legacy: 0
      enableLogAccessUsingOnlyResourcePermissions: true
    }
  }
}

resource appInsights 'Microsoft.Insights/components@2020-02-02' = {
  name: '${envName}-appinsights'
  location: location
  kind: 'string'
  tags: {
    displayName: 'AppInsight'
    ProjectName: envName
  }
  properties: {
    Application_Type: 'web'
    WorkspaceResourceId:  logAnalyticsWorkspace.id
  }
}

//
// App Service
// 

resource appServicePlan 'Microsoft.Web/serverfarms@2022-03-01' = {
  name: '${envName}-plan'
  location: location
  properties: {
    reserved: true
    perSiteScaling: true
    targetWorkerCount: 1
    zoneRedundant: true
  }
  sku: {
    name: sku
    capacity: 3    
  }
  kind: 'linux'
}

resource appService 'Microsoft.Web/sites@2020-06-01' = [ for i in range(0, 3): {
  name: '${envName}-app-${i}'
  location: location
  properties: {
    serverFarmId: appServicePlan.id
    siteConfig: {
      linuxFxVersion: linuxFxVersion
      appSettings: [
        {
          name: 'WEBSITE_RUN_FROM_PACKAGE'
          value: '1'
        }
        {
          name: 'SLEEP_DURATION_SEC'
          value: '5'
        }
        {
          name: 'WORKER_NAME'
          value: 'worker_${i}'
        }
        {
          name: 'APPINSIGHTS_INSTRUMENTATIONKEY'
          value: appInsights.properties.InstrumentationKey
        }
      ]
      healthCheckPath: '/health'
    }
  }
  dependsOn: [
    logAnalyticsWorkspace
  ]
}]

resource appServiceAppSettings 'Microsoft.Web/sites/config@2020-06-01' = [ for i in range(0, 3): {
  parent: appService[i]
  name: 'logs'
  properties: {
    applicationLogs: {
      fileSystem: {
        level: 'Information'
      }
    }
    httpLogs: {
      fileSystem: {
        retentionInMb: 40
        enabled: true
      }
    }
    failedRequestsTracing: {
      enabled: true
    }
    detailedErrorMessages: {
      enabled: true
    }
  }
}]

resource appServiceDiagnosticSettings 'microsoft.insights/diagnosticSettings@2017-05-01-preview' = [ for i in range(0, 3): {
  scope: appService[i]
  name: 'logs'
  properties: {
    workspaceId: logAnalyticsWorkspace.id
    logs: [
        {
          enabled: true
          category: 'AppServiceConsoleLogs'
        }
        {
          enabled: true
          category: 'AppServiceAppLogs'
        }
        {
          enabled: true
          category: 'AppServicePlatformLogs'
        }
      ]
    metrics: [
        {
          enabled: true
          category: 'AllMetrics'
        }
      ]
    }
}]


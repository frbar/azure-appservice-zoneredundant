# Purpose

Bicep template to setup an App Service Plan with Zone-Redundancy, and play with some flags to condition Web Apps.

Comes with Application Insights and Log Analytics Workspace, collecting various logs & metrics. 

# Infrastructure & App deployment

```powershell
az login
$subscription = "Training Subscription"
az account set --subscription $subscription

$rgName = "asp-zr-poc"
$envName = "hey22"
$location = "West Europe"

az group create --name $rgName --location $location
az deployment group create --resource-group $rgName --template-file infra.bicep --mode complete --parameters envName=$envName

dotnet publish .\src\Frbar.AzurePoc.BackendApi\ -r linux-x64 --self-contained -o publish
Compress-Archive publish\* publish.zip -Force
az webapp deployment source config-zip --src .\publish.zip -n "$($envName)-app-0" -g $rgName
az webapp deployment source config-zip --src .\publish.zip -n "$($envName)-app-1" -g $rgName
az webapp deployment source config-zip --src .\publish.zip -n "$($envName)-app-2" -g $rgName
 
```

# Tear down

```powershell
az group delete --name $rgName
```


[![Deploy To Azure](https://aka.ms/deploytoazurebutton)](https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2FSecureHats%2FSentinel-playground%2Fmain%2FDataConnectors%2FAzureDevOps%2Fazuredeploy.json/createUIDefinitionUri/https%3A%2F%2Fraw.githubusercontent.com%2FSecureHats%2FSentinel-playground%2Fmain%2FDataConnectors%2FAzureDevOps%2FUiDefinition.json)

# Azure DevOps Microsoft Sentinel Connector

Author: Rogier Dijkman

The Azure DevOps Auditing Sentinel connector provides the capability to ingest [Azure DevOps](https://docs.microsoft.com/en-us/azure/devops/organizations/audit/auditing-streaming?view=azure-devops#set-up-an-azure-monitor-log-stream) events in Microsoft Sentinel. 
It helps you gain visibility into what is happening in your environment, such as who is connected, which applications are installed and running, and much more.

## Prerequisites

Personal Access Token (pattoken) with the following permissions:
- Manage Audit Streams
- Read Audit Log
- Role Assignment Permissions in Azure (this is used to create the managed identity)

![image](https://user-images.githubusercontent.com/40334679/165294198-6085099f-47f4-43e9-bc75-dfd4fa1ee39f.png)

## Created Resources
This deployment will create the following resources tot configure Audit Streams in Azure DevOps

- Managed Identity
- Azure Key Vault
- Deployment Script

### Azure Key Vault

The template will deploy an Azure Key Vault to securely store the provided Personal Access Token. This token will later be used to configure the audit stream.

### Managed Identity

A Managed Identity is created within the subscription for the purpose of running a deployment script within Microsoft Azure.
After the deployment of de data connector has completed, the Managed Identity can be removed.

### Deployment Script

During the deployment of the ARM template, a degployment script will be created.
This deploymentscript has the logic for creating and coniguring streams within Azure DevOps.

## Validate Stream

After configuring the Audit Streams in Azure DevOps the audit connectivity should be visible in the Microsoft Sentinel Portal

![image](https://user-images.githubusercontent.com/40334679/165304433-cd3a5a65-66cf-463e-8e2c-bc5d175d808e.png)

## Detection Rules

Microsoft already has some build-in detection and hunting rules for Azure DevOps which can be found in the [Microsoft Sentinel GitHub](https://github.com/Azure/Azure-Sentinel/tree/master/Detections/AzureDevOpsAuditing) repository.


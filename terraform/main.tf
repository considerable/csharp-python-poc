terraform {
  required_version = ">= 1.9.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
  }
}

provider "azurerm" {
  features {}
}

variable "azure_devops_service_principal_object_id" {
  description = "Object ID of the service principal used by the Azure DevOps service connection"
  type        = string
}

locals {
  resource_group_name  = "rg-csharp-python-poc"
  function_app_name    = "helloapifunc-demo"
  storage_account_name = "sthelloapifuncdemo2026"
  log_name             = "workspace-rgcsharppythonpocwn9h"
  app_insights_name    = "helloapifunc-demo"
}

resource "azurerm_resource_group" "demo" {
  name     = local.resource_group_name
  location = "eastus"

  tags = {
    environment = "demo"
    managed_by  = "terraform"
    purpose     = "csharp-python-poc"
  }
}

resource "azurerm_role_assignment" "azure_devops_contributor" {
  scope                = azurerm_resource_group.demo.id
  role_definition_name = "Contributor"
  principal_id         = var.azure_devops_service_principal_object_id
}

resource "azurerm_storage_account" "func_storage" {
  name                     = local.storage_account_name
  resource_group_name      = azurerm_resource_group.demo.name
  location                 = azurerm_resource_group.demo.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  account_kind             = "StorageV2"
  min_tls_version          = "TLS1_2"

  tags = {
    environment = "demo"
  }
}

resource "azurerm_storage_container" "func_code" {
  name                  = "function-code"
  storage_account_id    = azurerm_storage_account.func_storage.id
  container_access_type = "private"
}

resource "azurerm_service_plan" "func_plan" {
  name                = "ASP-${local.resource_group_name}"
  resource_group_name = azurerm_resource_group.demo.name
  location            = azurerm_resource_group.demo.location
  os_type             = "Linux"
  sku_name            = "FC1"

  tags = {
    environment = "demo"
  }
}

resource "azurerm_log_analytics_workspace" "func_logs" {
  name                = local.log_name
  location            = azurerm_resource_group.demo.location
  resource_group_name = azurerm_resource_group.demo.name
  sku                 = "PerGB2018"
  retention_in_days   = 30

  tags = {
    environment = "demo"
  }
}

resource "azurerm_application_insights" "func_appinsights" {
  name                = local.app_insights_name
  location            = azurerm_resource_group.demo.location
  resource_group_name = azurerm_resource_group.demo.name
  workspace_id        = azurerm_log_analytics_workspace.func_logs.id
  application_type    = "web"

  tags = {
    environment = "demo"
  }
}

resource "azurerm_function_app_flex_consumption" "func_app" {
  name                        = local.function_app_name
  location                    = azurerm_resource_group.demo.location
  resource_group_name         = azurerm_resource_group.demo.name
  service_plan_id             = azurerm_service_plan.func_plan.id
  storage_container_endpoint  = "https://${azurerm_storage_account.func_storage.name}.blob.core.windows.net/${azurerm_storage_container.func_code.name}"
  storage_container_type      = "blobContainer"
  storage_authentication_type = "StorageAccountConnectionString"
  storage_access_key          = azurerm_storage_account.func_storage.primary_access_key

  runtime_name    = "dotnet-isolated"
  runtime_version = "10.0"

  https_only = true

  identity {
    type = "SystemAssigned"
  }

  app_settings = {
    AzureWebJobsStorage                   = azurerm_storage_account.func_storage.primary_connection_string
    APPLICATIONINSIGHTS_CONNECTION_STRING = azurerm_application_insights.func_appinsights.connection_string
    AzureWebJobsSecretStorageType         = "files"
  }

  site_config {
    http2_enabled       = true
    minimum_tls_version = "1.2"
  }

  tags = {
    environment = "demo"
  }
}
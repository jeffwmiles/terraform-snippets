resource "azurerm_resource_group" "trainlab-rg" {
  name     = "trainlab-rg"
  location = var.location # Define a location variable for this
}

resource "azurerm_app_service_plan" "webapp-serviceplan" {
  name                = "webapp-serviceplan"
  location            = azurerm_resource_group.trainlab-rg.location
  resource_group_name = azurerm_resource_group.trainlab-rg.name

  sku {
    tier = "Free"
    size = "F1"
  }
}
resource "azurerm_app_service" "webapp-appsvc" {
  name                = "webapp-appsvc"
  location            = azurerm_resource_group.trainlab-rg.location
  resource_group_name = azurerm_resource_group.trainlab-rg.name
  app_service_plan_id = azurerm_app_service_plan.webapp-serviceplan.id

  site_config {
    http2_enabled             = true
    always_on                 = false
    use_32_bit_worker_process = true
  }
}
resource "azurerm_template_deployment" "webapp-corestack" {
  # This will make it .NET CORE for Stack property, and add the dotnet core logging extension
  name                = "AspNetCoreStack"
  resource_group_name = azurerm_resource_group.trainlab-rg.name
  template_body       = <<DEPLOY
{
    "$schema": "https://schema.management.azure.com/schemas/2019-04-01/deploymentTemplate.json#",
    "contentVersion": "1.0.0.0",
    "parameters": {
        "siteName": {
            "type": "string",
            "metadata": {
                "description": "The Azure App Service Name"
            }
        },
        "extensionName": {
            "type": "string",
            "metadata": {
                "description": "The Site Extension Name."
            }
        },
        "extensionVersion": {
            "type": "string",
            "metadata": {
                "description": "The Extension Version"
            }
        }
    },
    "resources": [
        {
            "apiVersion": "2018-02-01",
            "name": "[parameters('siteName')]",
            "type": "Microsoft.Web/sites",
            "location": "[resourceGroup().location]",
            "properties": {
                "name": "[parameters('siteName')]",
                "siteConfig": {
                    "appSettings": [],
                    "metadata": [
                        {
                            "name": "CURRENT_STACK",
                            "value": "dotnetcore"
                        }
                    ]
                }
            }
        },
        {
            "type": "Microsoft.Web/sites/siteextensions",
            "name": "[concat(parameters('siteName'), '/', parameters('extensionName'))]",
            "apiVersion": "2018-11-01",
            "location": "[resourceGroup().location]",
            "properties": {
                "version": "[parameters('extensionVersion')]"
            }
        }
    ]
}
  DEPLOY
  parameters = {
    "siteName"         = azurerm_app_service.webapp-appsvc.name
    "extensionName"    = "Microsoft.AspNetCore.AzureAppServices.SiteExtension"
    "extensionVersion" = "3.1.7"
  }
  deployment_mode = "Incremental"
  depends_on      = [azurerm_app_service.webapp-appsvc]
}
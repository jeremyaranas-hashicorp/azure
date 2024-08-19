# Access AzureAD provider
data "azuread_client_config" "current" {}

# Create app registration
resource "azuread_application" "azure_app" {
  display_name = "azure-app"
  owners       = [data.azuread_client_config.current.object_id]

  password {
    display_name = "azure-vmss-secret"
  }
}

# Create service principal for application
resource "azuread_service_principal" "azure_sp" {
  client_id                    = azuread_application.azure_app.client_id
  app_role_assignment_required = false
  owners                       = [data.azuread_client_config.current.object_id]
}

output "azure_sp_client_id" {
  value     = azuread_service_principal.azure_sp.client_id
}

output "azure_app_pw" {
  sensitive = true
  value     = tolist(azuread_application.azure_app.password).0.value
}

data "azurerm_subscription" "current" {
}

output "current_subscription_display_name" {
    value = data.azurerm_subscription.current.subscription_id
}


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

# Output client ID
output "azure_sp_client_id" {
  value     = azuread_service_principal.azure_sp.client_id
}

# Output client secret
output "azure_app_pw" {
  sensitive = true
  value     = tolist(azuread_application.azure_app.password).0.value
}

data "azurerm_subscription" "current" {
}

output "current_subscription_display_name" {
    value = data.azurerm_subscription.current.subscription_id
}

# Configure a role assignment for azure-app service principal with Owner permissions to subscription
resource "azurerm_role_assignment" "role_assignment" {
  scope                = data.azurerm_subscription.current.id
  role_definition_name = "Owner"
  principal_id         = azuread_service_principal.azure_sp.object_id
  skip_service_principal_aad_check = true
}

output "service_account_object_id" {
    value = azuread_service_principal.azure_sp.object_id
}
data "azurerm_subscription" "current" {
}

output "current_subscription_display_name" {
    value = data.azurerm_subscription.current.subscription_id
}


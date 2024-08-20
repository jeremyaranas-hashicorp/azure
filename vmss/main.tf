# Import providers
terraform {
  required_providers {
    random  = "~> 3.1.2"
    azurerm = "~> 3.116.0"
    azuread = "~> 2.53.1"
  }
}

provider "azurerm" {
  features {
    key_vault {
      purge_soft_deleted_keys_on_destroy = true
      recover_soft_deleted_keys          = true
    }
  }
}

# Import modules 
module "app_registration" {
  source = "./modules"
}

# Set random ID
resource "random_id" "vault" {
  byte_length = 4
}

# Setup Azure resource group
resource "azurerm_resource_group" "vmss_resource_group" {
  name     = "vmss-rg"
  location = "West US"
}

# Setup Azure virtual network
resource "azurerm_virtual_network" "vmss_network" {
  name                = "vmss-net"
  resource_group_name = azurerm_resource_group.vmss_resource_group.name
  location            = azurerm_resource_group.vmss_resource_group.location
  address_space       = ["10.0.0.0/16"]
}

# Setup Azure subnet
resource "azurerm_subnet" "vmss_internal_subnet" {
  name                 = "vmss-internal-snet"
  resource_group_name  = azurerm_resource_group.vmss_resource_group.name
  virtual_network_name = azurerm_virtual_network.vmss_network.name
  address_prefixes     = ["10.0.2.0/24"]
}

# Azure Key Vault
resource "azurerm_key_vault" "vault" {
  name                = "vault-${random_id.vault.hex}"
  location            = azurerm_resource_group.vmss_resource_group.location
  resource_group_name = azurerm_resource_group.vmss_resource_group.name
  tenant_id           = var.azure_tenant_id
  enabled_for_deployment = true

  sku_name = "standard"

  # Access policy for service principal
  # Need to fix permissions
  access_policy {
    tenant_id = var.azure_tenant_id
    object_id = module.app_registration.service_account_object_id

    key_permissions = [
      "Backup",
      "Create",
      "Decrypt",
      "Delete",
      "Encrypt",
      "Get",
      "Import",
      "List",
      "Purge",
      "Recover",
      "Release",
      "Restore",
      "Rotate",
      "Sign",
      "UnwrapKey",
      "Update",
      "Verify",
      "WrapKey",
      "GetRotationPolicy",
      "SetRotationPolicy"
    ]
  }

  # Access policy for the user running Terraform
  # Need to fix permissions
  access_policy {
    tenant_id = var.azure_tenant_id
    object_id = data.azurerm_client_config.current.object_id

        key_permissions = [
      "Backup",
      "Create",
      "Decrypt",
      "Delete",
      "Encrypt",
      "Get",
      "Import",
      "List",
      "Purge",
      "Recover",
      "Release",
      "Restore",
      "Rotate",
      "Sign",
      "UnwrapKey",
      "Update",
      "Verify",
      "WrapKey",
      "GetRotationPolicy",
      "SetRotationPolicy"
    ]
  }
}

data "azurerm_client_config" "current" {
}

# Azure key to wrap/encrypt its master key
resource "azurerm_key_vault_key" "azure_hc_vault" {
  name         = var.key_name
  key_vault_id = azurerm_key_vault.vault.id
  key_type     = "RSA"
  key_size     = 2048

  key_opts = [
    "decrypt",
    "encrypt",
    "sign",
    "unwrapKey",
    "verify",
    "wrapKey",
  ]
}

output "key_vault_name" {
  value = azurerm_key_vault.vault.name
}

# Setup Azure VMSS
resource "azurerm_linux_virtual_machine_scale_set" "azure_vmss" {
  name                = "vmss-terraform"
  resource_group_name = azurerm_resource_group.vmss_resource_group.name
  user_data = base64encode(templatefile("templates/user_data.tpl", {
    vault_version = var.vault_version
    vault_license = var.vault_license
    azure_sub_id = module.app_registration.current_subscription_display_name
    azure_rg = var.azure_rg
    azure_vmss = var.azure_vmss
    azure_tenant_id = var.azure_tenant_id
    azure_sp_client_id = module.app_registration.azure_sp_client_id
    azure_secret = module.app_registration.azure_app_pw
    vault_name = azurerm_key_vault.vault.name
    key_name = var.key_name
      }))

  location            = azurerm_resource_group.vmss_resource_group.location
  sku                 = "Standard_F2"
  instances           = var.instances
  admin_username      = "azure-user"

  # Setup SSH to VM
  admin_ssh_key {
    username   = "azure-user"
    public_key = var.public_key
  }

  # Setup image to use for VM
  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts"
    version   = "latest"
  }
  
  # Setup OS disk
  os_disk {
    storage_account_type = "Standard_LRS"
    caching              = "ReadWrite"
  }

  # Setup Azure network interface
  network_interface {
    name    = "vmss-ni"
    primary = true

    ip_configuration {
      name      = "internal-ip"
      primary   = true
      subnet_id = azurerm_subnet.vmss_internal_subnet.id

      public_ip_address {
        name                   = "vmss-public-ip"
      }
    }
  }
}



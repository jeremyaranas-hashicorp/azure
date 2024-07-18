# Import azurerm provider
provider "azurerm" {
  features {}
}

# Setup Azure resource group
resource "azurerm_resource_group" "vmss_resource_group" {
  name     = "vmss-resources"
  location = "West US"
}

# Setup Azure virtual network
resource "azurerm_virtual_network" "vmss_network" {
  name                = "vmss-network"
  resource_group_name = azurerm_resource_group.vmss_resource_group.name
  location            = azurerm_resource_group.vmss_resource_group.location
  address_space       = ["10.0.0.0/16"]
}

# Setup Azure subnet
resource "azurerm_subnet" "internal" {
  name                 = "internal"
  resource_group_name  = azurerm_resource_group.vmss_resource_group.name
  virtual_network_name = azurerm_virtual_network.vmss_network.name
  address_prefixes     = ["10.0.2.0/24"]
}

# Setup Azure VMSS
resource "azurerm_linux_virtual_machine_scale_set" "azure_linux_vmss" {
  name                = "vmss"
  resource_group_name = azurerm_resource_group.vmss_resource_group.name
  user_data = base64encode(templatefile("templates/user_data.tpl", {
    vault_version = var.vault_version
    vault_license = var.vault_license
      }))

  location            = azurerm_resource_group.vmss_resource_group.location
  sku                 = "Standard_F2"
  instances           = 1
  admin_username      = "adminuser"

  # Setup SSH to VM
  admin_ssh_key {
    username   = "adminuser"
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
      name      = "internal"
      primary   = true
      subnet_id = azurerm_subnet.internal.id

      public_ip_address {
        name                   = "vmss-public-ip"
      }
    }
  }
}
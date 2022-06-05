terraform {
  required_providers {
    azurerm = {
      source = "hashicorp/azurerm"
      version = "=2.96.0"
    }
  }
}

provider "azurerm" {
    features {}
}

resource "azurerm_resource_group" "mcserver" {
    name     = "rg-mcserver001"
    location = "West Europe"
}

resource "azurerm_virtual_network" "mcserver" {
    name                  = "vnet-mcserver001"
    address_space         = ["10.0.0.0/16"]
    resource_group_name   = azurerm_resource_group.mcserver.name
    location              = azurerm_resource_group.mcserver.location
}

resource "azurerm_subnet" "public-mcserver" {
    name                 = "publicsubnet-001"
    resource_group_name  = azurerm_resource_group.mcserver.name
    virtual_network_name = azurerm_virtual_network.mcserver.name
    address_prefixes     = ["10.0.1.0/24"]
}

resource "azurerm_storage_account" "mcserver" {
    name                     = "samcserver001"
    account_tier             = "Standard"
    account_replication_type = "LRS"
    location                 = azurerm_resource_group.mcserver.location
    resource_group_name      = azurerm_resource_group.mcserver.name
}

resource "azurerm_network_interface" "mcserver" {
  name                = "nic-mcserver001"
  location            = azurerm_resource_group.mcserver.location
  resource_group_name = azurerm_resource_group.mcserver.name

  ip_configuration {
    name                          = "nic-mcserver001"
    subnet_id                     = azurerm_subnet.public-mcserver.id
    private_ip_address_allocation = "Static"
    private_ip_address            = "10.0.1.10"
  }
}

resource "azurerm_ssh_public_key" "mcserver" {
  name                = "mykey"
  resource_group_name = azurerm_resource_group.mcserver.name
  location            = azurerm_resource_group.mcserver.location
  public_key          = file("~/.ssh/mykey.pub")
}

resource "azurerm_virtual_machine" "mcserver" {
    name                            = "vm-mcserver001"
    location                        = azurerm_resource_group.mcserver.location
    resource_group_name             = azurerm_resource_group.mcserver.name
    network_interface_ids           = [azurerm_network_interface.mcserver.id]
    vm_size                         = "Standard_DS1_v2"

    storage_image_reference {
      publisher = "Canonical"
      offer     = "UbuntuServer"
      sku       = "20.04-LTS"
      version   = "latest"
    }

    storage_os_disk {
      name              = "mcserver001-disk"
      caching           = "ReadWrite"
      create_option     = "FromImage"
      managed_disk_type = "Standard_LRS"
    }

    os_profile {
      computer_name  = "mcserver"
      admin_username = "pbl"
    }

    os_profile_linux_config {
      disable_password_authentication = true
      ssh_keys {
        path = "/home/pbl/.ssh/mykey.pub"
        key_data = azurerm_ssh_public_key.mcserver.public_key
      }
    }


}

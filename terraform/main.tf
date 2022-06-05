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

resource "azurerm_resource_group" "mcserver2" {
    name     = "rg-mcserver002"
    location = "West Europe"
}

resource "azurerm_virtual_network" "mcserver2" {
    name                  = "vnet-mcserver002"
    address_space         = ["10.0.0.0/16"]
    resource_group_name   = azurerm_resource_group.mcserver2.name
    location              = azurerm_resource_group.mcserver2.location
}

resource "azurerm_subnet" "public-mcserver2" {
    name                 = "public-subnet-002"
    resource_group_name  = azurerm_resource_group.mcserver2.name
    virtual_network_name = azurerm_virtual_network.mcserver2.name
    address_prefixes     = ["10.0.1.0/24"]
}

resource "azurerm_storage_account" "mcserver2" {
    name                     = "samcserver002"
    account_tier             = "Standard"
    account_replication_type = "LRS"
    location                 = azurerm_resource_group.mcserver2.location
    resource_group_name      = azurerm_resource_group.mcserver2.name
}

resource "azurerm_public_ip" "public_ip" {
  name                = "ip-mcserver002"
  resource_group_name = azurerm_resource_group.mcserver2.name
  location            = azurerm_resource_group.mcserver2.location
  allocation_method   = "Dynamic"
}

resource "azurerm_network_interface" "mcserver2" {
  name                = "nic-mcserver002"
  location            = azurerm_resource_group.mcserver2.location
  resource_group_name = azurerm_resource_group.mcserver2.name

  ip_configuration {
    name                          = "nic-mcserver001"
    subnet_id                     = azurerm_subnet.public-mcserver2.id
    private_ip_address_allocation = "Static"
    private_ip_address            = "10.0.1.10"
    public_ip_address_id          = azurerm_public_ip.public_ip.id
  }
}

resource "azurerm_ssh_public_key" "mcserver2" {
  name                = "mykey"
  resource_group_name = azurerm_resource_group.mcserver2.name
  location            = azurerm_resource_group.mcserver2.location
  public_key          = file("~/.ssh/mykey.pub")
}

resource "azurerm_linux_virtual_machine" "mcserver2" {
    name                   = "vm-mcserver002"
    location               = azurerm_resource_group.mcserver2.location
    resource_group_name    = azurerm_resource_group.mcserver2.name
    network_interface_ids  = [azurerm_network_interface.mcserver2.id]
    size                   = "Standard_B2s"

    
    admin_username         = "pbl"
    computer_name          = "mcserver"  

    source_image_reference {
      publisher = "Canonical"
      offer     = "0001-com-ubuntu-server-focal"
      sku       = "20_04-lts-gen2"
      version   = "latest"
    }

    os_disk {
      name                 = "mcserver002-disk"
      caching              = "ReadWrite"
      storage_account_type = "StandardSSD_LRS"
    }

    admin_ssh_key {
      username = "pbl"
      public_key = azurerm_ssh_public_key.mcserver2.public_key
    }
    disable_password_authentication = true
}

output "server_ip" {
  value = azurerm_linux_virtual_machine.mcserver2.public_ip_address
}
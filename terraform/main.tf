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

variable "vm_size" {
  type        = string
  description = "VM size for the instance"
  default = "Standard_B2s"
}

variable "key_name" {
  type        = string
  description = "Name of the public key to connect to the instance"
  default = "mykey"
}

variable "admin" {
  type        = string
  description = "Name for the admin user"

  # Value set in deploy script
  default = "pbl" 
}

resource "azurerm_resource_group" "mcserver" {
    name     = "rg-mcserver01"
    location = "West Europe"
}

resource "azurerm_virtual_network" "mcserver" {
    name                  = "vnet-mcserver01"
    address_space         = ["10.0.0.0/16"]
    resource_group_name   = azurerm_resource_group.mcserver.name
    location              = azurerm_resource_group.mcserver.location
}

resource "azurerm_network_security_group" "mcserver" {
  name                = "mcserver-nsg"
  location            = azurerm_resource_group.mcserver.location
  resource_group_name = azurerm_resource_group.mcserver.name
}

resource "azurerm_application_security_group" "mcserver" {
  name                 = "mcserver-asg"
  location             = azurerm_resource_group.mcserver.location
  resource_group_name  = azurerm_resource_group.mcserver.name
}

resource "azurerm_network_security_rule" "mcserver_endpoint" {
  name                        = "mcserver-endpoint"
  priority                    = 100
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "25565"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  resource_group_name         = azurerm_resource_group.mcserver.name
  network_security_group_name = azurerm_network_security_group.mcserver.name
}

resource "azurerm_network_security_rule" "mcserver_ssh" {
  name                        = "mcserver-ssh"
  priority                    = 101
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "22"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  resource_group_name         = azurerm_resource_group.mcserver.name
  network_security_group_name = azurerm_network_security_group.mcserver.name
}

resource "azurerm_network_security_rule" "mcserver_grafana" {
  name                        = "mcserver-grafana"
  priority                    = 102
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "3000"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  resource_group_name         = azurerm_resource_group.mcserver.name
  network_security_group_name = azurerm_network_security_group.mcserver.name
}

resource "azurerm_subnet" "public-mcserver" {
    name                 = "public-subnet-01"
    resource_group_name  = azurerm_resource_group.mcserver.name
    virtual_network_name = azurerm_virtual_network.mcserver.name
    address_prefixes     = ["10.0.1.0/24"]
}

resource "azurerm_subnet_network_security_group_association" "mcserver" {
  subnet_id                 = azurerm_subnet.public-mcserver.id
  network_security_group_id = azurerm_network_security_group.mcserver.id
}

resource "azurerm_storage_account" "mcserver" {
    name                     = "staccmcserver01"
    account_tier             = "Standard"
    account_replication_type = "LRS"
    location                 = azurerm_resource_group.mcserver.location
    resource_group_name      = azurerm_resource_group.mcserver.name
}

resource "azurerm_public_ip" "public_ip" {
  name                = "ip-mcserver01"
  resource_group_name = azurerm_resource_group.mcserver.name
  location            = azurerm_resource_group.mcserver.location
  allocation_method   = "Dynamic"
}

resource "azurerm_network_interface" "mcserver" {
  name                = "nic-mcserver01"
  location            = azurerm_resource_group.mcserver.location
  resource_group_name = azurerm_resource_group.mcserver.name

  ip_configuration {
    name                          = "nic-mcserver01"
    subnet_id                     = azurerm_subnet.public-mcserver.id
    private_ip_address_allocation = "Static"
    private_ip_address            = "10.0.1.10"
    public_ip_address_id          = azurerm_public_ip.public_ip.id
  }
}

resource "azurerm_network_interface_application_security_group_association" "mcserver" {
  network_interface_id          = azurerm_network_interface.mcserver.id
  application_security_group_id = azurerm_application_security_group.mcserver.id
}

resource "azurerm_ssh_public_key" "mcserver" {
  name                = var.key_name
  resource_group_name = azurerm_resource_group.mcserver.name
  location            = azurerm_resource_group.mcserver.location
  public_key          = file("~/.ssh/${var.key_name}.pub")
}

resource "azurerm_linux_virtual_machine" "mcserver" {
    name                   = "vm-mcserver01"
    location               = azurerm_resource_group.mcserver.location
    resource_group_name    = azurerm_resource_group.mcserver.name
    network_interface_ids  = [azurerm_network_interface.mcserver.id]
    size                   = var.vm_size
    admin_username         = var.admin
    computer_name          = "mcserver"  

    source_image_reference {
      publisher = "Canonical"
      offer     = "0001-com-ubuntu-server-focal"
      sku       = "20_04-lts-gen2"
      version   = "latest"
    }

    os_disk {
      name                 = "mcserver01-disk"
      caching              = "ReadWrite"
      storage_account_type = "StandardSSD_LRS"
    }

    admin_ssh_key {
      username = var.admin
      public_key = azurerm_ssh_public_key.mcserver.public_key
    }
    disable_password_authentication = true
}

output "server_ip" {
  value = azurerm_linux_virtual_machine.mcserver.public_ip_address
}
# ==============================================================================
# Resource Group
# ==============================================================================
resource "azurerm_resource_group" "rg" {
  name     = var.resource_group_name
  location = var.location
  tags     = var.tags
}

# ==============================================================================
# Virtual Network & Subnets
# ==============================================================================
resource "azurerm_virtual_network" "vnet" {
  name                = var.vnet_name
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  address_space       = var.vnet_address_space
  tags                = var.tags
}

resource "azurerm_subnet" "external" {
  name                 = var.external_subnet_name
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = var.external_subnet_prefix
}

resource "azurerm_subnet" "internal" {
  name                 = var.internal_subnet_name
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = var.internal_subnet_prefix
}

# ==============================================================================
# Network Security Groups
# ==============================================================================

# 1. External NSG: Opening external SSH access
resource "azurerm_network_security_group" "ext_ssh" {
  name                = var.external_nsg_name
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  tags                = var.tags

  security_rule {
    name                       = "Allow-External-SSH"
    priority                   = 1001
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = var.ssh_source_address_prefix
    destination_address_prefix = "*"
  }
}

# 2. Internal NSG: Allowing SSH from the virtual network
resource "azurerm_network_security_group" "int_ssh" {
  name                = var.internal_nsg_name
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  tags                = var.tags

  security_rule {
    name                       = "Allow-SSH-From-VirtualNetwork"
    priority                   = 1001
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = var.internal_ssh_source_address_prefix
    destination_address_prefix = "*"
  }
}

# Subnet association for internal subnet (covers all internal VMs on this subnet)
resource "azurerm_subnet_network_security_group_association" "internal_subnet_assoc" {
  subnet_id                 = azurerm_subnet.internal.id
  network_security_group_id = azurerm_network_security_group.int_ssh.id
}
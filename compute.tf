# ==============================================================================
# SSH Key Management
# ==============================================================================
# Generates an RSA 4096-bit private key if no custom ssh_public_key is provided
resource "tls_private_key" "ssh" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

locals {
  admin_ssh_public_key = var.ssh_public_key != null && var.ssh_public_key != "" ? var.ssh_public_key : tls_private_key.ssh.public_key_openssh
}

# Automatically save the private key locally for easy SSH access
resource "local_file" "ssh_private_key" {
  count           = var.ssh_public_key == null || var.ssh_public_key == "" ? 1 : 0
  content         = tls_private_key.ssh.private_key_pem
  filename        = "${path.module}/id_rsa"
  file_permission = "0600"
}

# ==============================================================================
# Public IP (Attached to External VM)
# ==============================================================================
resource "azurerm_public_ip" "external" {
  name                = "pip-${var.external_vm_name}"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = "Static"
  sku                 = "Standard"
  tags                = var.tags
}

# ==============================================================================
# External Virtual Machine & Network Interface
# ==============================================================================
resource "azurerm_network_interface" "external" {
  name                = "${var.external_vm_name}-nic"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  tags                = var.tags

  ip_configuration {
    name                          = "ipconfig-external"
    subnet_id                     = azurerm_subnet.external.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.external.id
  }
}

# Attach NSG F26-ext-ssh to the external VM's network interface
resource "azurerm_network_interface_security_group_association" "external_nic_assoc" {
  network_interface_id      = azurerm_network_interface.external.id
  network_security_group_id = azurerm_network_security_group.ext_ssh.id
}

resource "azurerm_linux_virtual_machine" "external" {
  name                  = var.external_vm_name
  location              = azurerm_resource_group.rg.location
  resource_group_name   = azurerm_resource_group.rg.name
  size                  = var.vm_size
  admin_username        = var.admin_username
  network_interface_ids = [azurerm_network_interface.external.id]
  tags                  = var.tags

  admin_ssh_key {
    username   = var.admin_username
    public_key = local.admin_ssh_public_key
  }

  os_disk {
    name                 = "${var.external_vm_name}-osdisk"
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
    disk_size_gb         = var.os_disk_size_gb
  }

  source_image_reference {
    publisher = var.image_publisher
    offer     = var.image_offer
    sku       = var.image_sku
    version   = var.image_version
  }

  dynamic "plan" {
    for_each = var.enable_plan_block ? [1] : []
    content {
      name      = var.image_sku
      product   = var.image_offer
      publisher = var.image_publisher
    }
  }

}

# ==============================================================================
# Internal Virtual Machine & Network Interface
# ==============================================================================
resource "azurerm_network_interface" "internal" {
  name                = "${var.internal_vm_name}-nic"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  tags                = var.tags

  ip_configuration {
    name                          = "ipconfig-internal"
    subnet_id                     = azurerm_subnet.internal.id
    private_ip_address_allocation = "Dynamic"
  }
}

# Attach NSG f26-int-ssh to the internal VM's network interface
resource "azurerm_network_interface_security_group_association" "internal_nic_assoc" {
  network_interface_id      = azurerm_network_interface.internal.id
  network_security_group_id = azurerm_network_security_group.int_ssh.id
}

resource "azurerm_linux_virtual_machine" "internal" {
  name                  = var.internal_vm_name
  location              = azurerm_resource_group.rg.location
  resource_group_name   = azurerm_resource_group.rg.name
  size                  = var.vm_size
  admin_username        = var.admin_username
  network_interface_ids = [azurerm_network_interface.internal.id]
  tags                  = var.tags

  admin_ssh_key {
    username   = var.admin_username
    public_key = local.admin_ssh_public_key
  }

  os_disk {
    name                 = "${var.internal_vm_name}-osdisk"
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
    disk_size_gb         = var.os_disk_size_gb
  }

  source_image_reference {
    publisher = var.image_publisher
    offer     = var.image_offer
    sku       = var.image_sku
    version   = var.image_version
  }

  dynamic "plan" {
    for_each = var.enable_plan_block ? [1] : []
    content {
      name      = var.image_sku
      product   = var.image_offer
      publisher = var.image_publisher
    }
  }

  # The private IP is owned by the NIC. If a NIC is ever recreated, its IP
  # moves before the VM's state refreshes, producing a phantom in-place
  # update on a computed field. Ignore the VM's stale copy; the NIC resource
  # remains the source of truth.
  # NOTE: ignore_changes entries must be real arguments of this resource.
  # NSG bindings are NOT an attribute here -- they are managed by the
  # azurerm_network_interface_security_group_association resources.
  lifecycle {
    ignore_changes = [
      private_ip_address,
    ]
  }
}
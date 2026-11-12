output "resource_group_name" {
  description = "The name of the resource group"
  value       = azurerm_resource_group.rg.name
}

output "resource_group_location" {
  description = "The location of the resource group"
  value       = azurerm_resource_group.rg.location
}

output "virtual_network_name" {
  description = "The name of the virtual network"
  value       = azurerm_virtual_network.vnet.name
}

output "virtual_network_id" {
  description = "The ID of the virtual network"
  value       = azurerm_virtual_network.vnet.id
}

output "virtual_network_address_space" {
  description = "The address space of the virtual network"
  value       = azurerm_virtual_network.vnet.address_space
}

output "external_subnet_id" {
  description = "The ID of the external subnet"
  value       = azurerm_subnet.external.id
}

output "internal_subnet_id" {
  description = "The ID of the internal subnet"
  value       = azurerm_subnet.internal.id
}

output "external_public_ip" {
  description = "The public IP address attached to the external Linux VM"
  value       = azurerm_public_ip.external.ip_address
}

output "external_vm_name" {
  description = "The name of the external Linux VM"
  value       = azurerm_linux_virtual_machine.external.name
}

output "external_vm_private_ip" {
  description = "The private IP address of the external Linux VM"
  value       = azurerm_network_interface.external.private_ip_address
}

output "internal_vm_name" {
  description = "The name of the internal Linux VM"
  value       = azurerm_linux_virtual_machine.internal.name
}

output "internal_vm_private_ip" {
  description = "The private IP address of the internal Linux VM"
  value       = azurerm_network_interface.internal.private_ip_address
}

output "external_nsg_name" {
  description = "The name of the external NSG"
  value       = azurerm_network_security_group.ext_ssh.name
}

output "internal_nsg_name" {
  description = "The name of the internal NSG"
  value       = azurerm_network_security_group.int_ssh.name
}

output "ssh_private_key_file" {
  description = "Path to the generated SSH private key (if generated)"
  value       = var.ssh_public_key == null || var.ssh_public_key == "" ? "${path.module}/id_rsa" : "Custom public key supplied"
}

output "ssh_private_key_pem" {
  description = "The generated SSH private key PEM contents"
  value       = tls_private_key.ssh.private_key_pem
  sensitive   = true
}

output "ssh_external_vm_command" {
  description = "Command to SSH directly to the external VM"
  value       = "ssh -i id_rsa ${var.admin_username}@${azurerm_public_ip.external.ip_address}"
}

output "ssh_internal_vm_jump_command" {
  description = "Command to SSH into the internal VM using the external VM as a jump host"
  value       = "ssh -J ${var.admin_username}@${azurerm_public_ip.external.ip_address} -i id_rsa ${var.admin_username}@${azurerm_network_interface.internal.private_ip_address}"
}
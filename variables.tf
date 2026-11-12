variable "location" {
  description = "The Azure region where resources will be deployed"
  type        = string
  default     = "northcentralus"
}

variable "resource_group_name" {
  description = "Name of the Azure Resource Group"
  type        = string
  default     = "qwen-f26"
}

variable "vnet_name" {
  description = "Name of the Virtual Network"
  type        = string
  default     = "qwen-f26"
}

variable "vnet_address_space" {
  description = "Address space for the Virtual Network"
  type        = list(string)
  default     = ["172.21.0.0/16"]
}

variable "external_subnet_name" {
  description = "Name of the external subnet"
  type        = string
  default     = "f26-external"
}

variable "external_subnet_prefix" {
  description = "Address prefix for the external subnet"
  type        = list(string)
  default     = ["172.21.0.0/24"]
}

variable "internal_subnet_name" {
  description = "Name of the internal subnet"
  type        = string
  default     = "f26-internal"
}

variable "internal_subnet_prefix" {
  description = "Address prefix for the internal subnet"
  type        = list(string)
  default     = ["172.21.1.0/24"]
}

variable "vm_size" {
  description = "Azure VM size for both Linux VMs"
  type        = string
  default     = "Standard_B2ats_v2"
}

variable "os_disk_size_gb" {
  description = "Size of the OS disk in GiB. AlmaLinux marketplace images require a minimum of 30 GiB."
  type        = number
  default     = 30
}

variable "external_nsg_name" {
  description = "Name of the Network Security Group for the external VM"
  type        = string
  default     = "F26-ext-ssh"
}

variable "internal_nsg_name" {
  description = "Name of the Network Security Group for internal VMs"
  type        = string
  default     = "f26-int-ssh"
}

variable "external_vm_name" {
  description = "Name of the external Linux VM"
  type        = string
  default     = "f26-external-vm"
}

variable "internal_vm_name" {
  description = "Name of the internal Linux VM"
  type        = string
  default     = "f26-internal-vm"
}

variable "admin_username" {
  description = "Admin username for the Linux VMs"
  type        = string
  default     = "azureuser"
}

variable "ssh_public_key" {
  description = "Optional custom SSH public key string. If null, a new key pair will be generated automatically."
  type        = string
  default     = null
}

variable "ssh_source_address_prefix" {
  description = "Allowed CIDR or IP for external SSH access (e.g. '*' for all, or your specific IP)"
  type        = string
  default     = "*"
}

variable "internal_ssh_source_address_prefix" {
  description = "Allowed source prefix for internal SSH access. Matches VNet address space."
  type        = string
  default     = "172.21.0.0/16"
}

variable "image_publisher" {
  description = "Marketplace image publisher for AlmaLinux"
  type        = string
  default     = "almalinux"
}

variable "image_offer" {
  description = "Marketplace image offer for AlmaLinux"
  type        = string
  default     = "almalinux-x86_64"
}

variable "image_sku" {
  description = "Marketplace image SKU for AlmaLinux (e.g. 9-gen2)"
  type        = string
  default     = "9-gen2"
}

variable "image_version" {
  description = "Marketplace image version for AlmaLinux"
  type        = string
  default     = "latest"
}

variable "enable_plan_block" {
  description = "Enable marketplace plan block on virtual machine resources (AlmaLinux images do NOT require a plan; leave false)"
  type        = bool
  default     = false
}

variable "tags" {
  description = "Resource tags"
  type        = map(string)
  default = {
    Environment = "Fall-2026"
    Project     = "IT356"
    ManagedBy   = "Terraform"
  }
}
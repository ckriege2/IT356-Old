# Azure Terraform Environment: Fall-2026 (IT356)

This Terraform project provisions a small, secure two-tier Azure environment with an external-facing Linux VM and an internal Linux VM running AlmaLinux.

---

## Architecture Overview

```
                       +-------------------------------------------------------+
                       |               Azure Resource Group                    |
                       |                    qwen-f26                          |
                       |                                                       |
                       |     Virtual Network: qwen-f26 (172.21.0.0/16)        |
                       |                                                       |
                       |    +---------------------------------------------+    |
                       |    | Subnet: f26-external (172.21.0.0/24)        |    |
                       |    |                                             |    |
   Internet            |    |   +-------------------------------------+   |    |
      │ SSH (Port 22)  |    |   | VM: f26-external-vm                 |   |    |
      ▼                |    |   | Size: Standard_B2ats_v2             |   |    |
   [Public IP] ────────┼───>│   | OS: AlmaLinux 9 Gen2                |   |    |
                       |    |   | Disk: 30 GB                         |   |    |
                       |    |   | NSG: F26-ext-ssh (Allow 22 from *)  |   |    |
                       |    |   +------------------┬------------------+   |    |
                       |    +----------------------│----------------------+    |
                       |                           │ SSH (Port 22)             |
                       |                           │ (from 172.21.0.0/24)      |
                       |    +----------------------▼----------------------+    |
                       |    | Subnet: f26-internal (172.21.1.0/24)        |    |
                       |    |                                             |    |
                       |    |   +-------------------------------------+   |    |
                       |    |   | VM: f26-internal-vm                 |   |    |
                       |    |   | Size: Standard_B2ats_v2             |   |    |
                       |    |   | OS: AlmaLinux 9 Gen2                |   |    |
                       |    |   | Disk: 30 GB                         |   |    |
                       |    |   | NSG: f26-int-ssh (Allow 22 from ext)|   |    |
                       |    |   +-------------------------------------+   |    |
                       |    +---------------------------------------------+    |
                       +-------------------------------------------------------+
```

---

## Specifications & Resource Mapping

| Requirement | Resource Type | Resource Name | Details / Configuration |
| :--- | :--- | :--- | :--- |
| **Resource Group** | `azurerm_resource_group` | `qwen-f26` | Default region `northcentralus` |
| **Virtual Network** | `azurerm_virtual_network` | `qwen-f26` | Address space: `172.21.0.0/16` |
| **External Subnet** | `azurerm_subnet` | `f26-external` | Address prefix: `172.21.0.0/24` |
| **Internal Subnet** | `azurerm_subnet` | `f26-internal` | Address prefix: `172.21.1.0/24` |
| **External Linux VM** | `azurerm_linux_virtual_machine` | `f26-external-vm` | Size: `Standard_B2ats_v2`, AlmaLinux 9 Gen2, 30 GB disk |
| **External NSG** | `azurerm_network_security_group` | `F26-ext-ssh` | Allows inbound TCP 22 from external (`*` / Internet), attached to external VM NIC |
| **Internal Linux VM** | `azurerm_linux_virtual_machine` | `f26-internal-vm` | Size: `Standard_B2ats_v2`, AlmaLinux 9 Gen2, 30 GB disk |
| **Internal NSG** | `azurerm_network_security_group` | `f26-int-ssh` | Allows inbound TCP 22 from `172.21.0.0/24` (external subnet), attached to the internal subnet (covers all NICs in it) |
| **External Public IP** | `azurerm_public_ip` | `pip-f26-external-vm` | Standard SKU, Static allocation, attached to external VM NIC |

---

## Repository Files

```
it356-owen/
├── versions.tf               # Terraform and provider configurations (azurerm, tls, local)
├── variables.tf              # Input variables with lab defaults
├── main.tf                   # Resource group, virtual network, subnets, and NSGs
├── compute.tf                # Public IP, network interfaces, VMs, and SSH key management
├── outputs.tf                # Public IP, private IPs, and ready-to-run SSH connection commands
├── terraform.tfvars.example  # Example configuration overrides
├── .gitignore                # Prevents committing states, plans, and generated SSH keys
└── README.md                 # Project documentation
```

---

## Prerequisites

1. **Azure CLI**: Logged in to your target Azure subscription:
   ```bash
   az login
   az account set --subscription "<YOUR_SUBSCRIPTION_ID>"
   ```

2. **Terraform**: v1.3.0 or later installed.

3. **AlmaLinux Image (no Marketplace plan)**:
   The `almalinux-x86_64` image is a **community/platform** image and does **not** require a Marketplace `plan` block or pre-accepted terms. Do **not** add `plan` to the VM resources and do **not** run `az vm image terms accept` for this image — both cause the `ResourcePurchaseValidationFailed` (400) error. This configuration already ships with `enable_plan_block = false`.

---

## Deployment Instructions

### 1. Initialize Terraform
```bash
terraform init
```

### 2. Review the Plan
```bash
terraform plan
```

### 3. Deploy
```bash
terraform apply
```
> **SSH Key:** If no existing SSH public key is provided in `ssh_public_key`, Terraform will automatically generate a 4096-bit RSA key pair and write the private key to `./id_rsa` with `0600` permissions.

---

## Connecting via SSH

Once `terraform apply` finishes, connection details and helper commands are output automatically:

### 1. Direct SSH to External VM
```bash
ssh -i id_rsa azureuser@<EXTERNAL_PUBLIC_IP>
```

### 2. Jump Host SSH to Internal VM
The internal VM has no public IP and only allows SSH from the external subnet (`172.21.0.0/24`), i.e. via the jump host. You can connect to it securely using the external VM as a jump host (`ProxyJump` / `-J`):
```bash
ssh -J azureuser@<EXTERNAL_PUBLIC_IP> -i id_rsa azureuser@172.21.1.4
```
*(The exact command is populated dynamically in the Terraform output `ssh_internal_vm_jump_command`)*

---

## Important Note on Disk Sizing

The OS disk size defaults to **30 GiB** in both `variables.tf` and `terraform.tfvars.example`.

> **Azure Marketplace Note:** Official AlmaLinux cloud images on Azure have a baseline publisher VHD size of 30 GiB. Azure does not permit shrinking an OS disk below the publisher's base image size, so the default is set to 30 GiB. If you want a smaller footprint, you may pass a value at apply time (e.g. `terraform apply -var="os_disk_size_gb=30"`), but do not set it below 30 GiB or deployment will fail.

---

## Teardown / Cleanup

To delete all provisioned resources:
```bash
terraform destroy
```
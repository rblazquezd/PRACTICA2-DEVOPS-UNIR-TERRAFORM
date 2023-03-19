variable "resource_group_name" {
  default = "rs-practica2-1"
}

variable "location_name" {
  default = "uksouth"
}

variable "security_group_name" {
  default = "nsg_practica2-1"
}

variable "security_rule_name" {
  default = "inbound-http-rule"
}

variable "sshkey_name" {
  default = "sshkey-practica2-1"
}

variable "lb_name" {
  default = "lb-practica2-1"
}

variable "azurerm_virtual_network_name" {
  default = "azurerm_virtual_network_practica2-1"
}


variable "network_name" {
  default = "vnet1_practica2-1"
}

variable "subnet_name" {
  default = "subnet1_practica2-1"
}

variable "azurerm_network_interface" {
   default = "vnic1"
}


variable "vm_publickey" {
  default = "azure.pub"
}

variable "vm_username" {
 default = "operatorazure"
}

variable "vm1_hostname" {
  default = "vm1"
}

variable "vm2_hostname" {
  default = "vm2"
}

variable "vm_specs" {
  type = object({
    count          = number
    basename       = string
    size           = string
    admin_username = string
    username       = string
    public_key      = string
  })

  sensitive = true

  default = {
    count          = 3
    basename       = "vm0"
    size           = "Standard_B1s"
    admin_username = "azureuser"
    username       = "azureuser"
    public_key     = "azure.pub"
  }
}

variable "osimage_specs" {
  type = object({
    name      = string
    product   = string
    publisher = string
    offer     = string
    sku       = string
    version   = string
  })

  default = {
    name      = "20_04-lts-gen2"
    product   = "Canonical"
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-focal"
    sku       = "20_04-lts-gen2"
    version   = "20.04.202303020"
  }
}

variable "cluster_name" {
  default = "demok8s"
}


variable "dns_prefix" {
  default = "demok8s"
}

variable "agent_count" {
  default = 1
}

variable "admin_username" {
  default = "demo"
}

variable "ssh_public_key" {
  default = "azure.pub"
}

variable "aks_service_principal_app_id" {
  default = "123456789"
}

variable "aks_service_principal_client_secret" {
  default = "123456789"
}

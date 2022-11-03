variable "resource_groups" {
  type = map(object({
    location = string
  }))
}

variable "vnets" {
  type    = object({
    name                = string
    address_space       = list(string)
    location            = string
    resource_group_name = string
  })
  default = null
}

variable "subnets" {
  type    = any
  default = null
}

variable "pip" {
  type    = object({
    name                = string
    location            = string
    resource_group_name = string
    allocation_method   = string
    sku                 = string

  })
  default = null
}

variable "bastion" {
  type    = object({
    name                = string
    location            = string
    resource_group_name = string
    ip_configuration = object({
      name        = string
      subnet_name = string
    })
  })
  default = null
}

variable "nic" {
  type    = object({
    name                = string
    location            = string
    resource_group_name = string
    ip_configuration = object({
      name        = string
      subnet_name = string
      private_ip_address_allocation = string
    })
  })
  default = null
}

variable "virtual_machine" {
  type    = object({
    name                = string
    location            = string
    resource_group_name = string
    size                = string
    admin_username      = string

    os_disk = object({
      caching              = string
      storage_account_type = string
    })
    source_image_reference = object({
      publisher = string
      offer     = string
      sku       = string
      version   = string
    })
  })
  default = null
}

variable "storage_account" {
  type    = object({
    name                     = string
    resource_group_name      = string
    location                 = string
    account_tier             = string
    account_replication_type = string
  })
  default = null
}

variable "private_dns_zone" {
  type    = object({
    name                = string
    resource_group_name = string
  })
  default = null
}

variable "private_dns_zone_vnet_link" {
  type    = object({
    name                  = string
    resource_group_name   = string
    private_dns_zone_name = string
  })
  default = null
}

variable "private_endpoint" {
  type    = object({
    name                = string
    resource_group_name = string
    location            = string
    subnet_name         = string
    private_service_connection = object({
      name                 = string
      is_manual_connection = bool
      subresource_names    = list(string)
    })
    private_dns_zone_group = object({
      name = string
    })
  })
  default = null
}
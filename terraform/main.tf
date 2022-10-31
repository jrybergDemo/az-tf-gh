resource "azurerm_resource_group" "rg" {
  for_each = var.resource_groups

  name     = each.key
  location = each.value
}


resource "azurerm_virtual_network" "vnet" {

  name                = var.vnets.name
  address_space       = var.vnets.address_space
  location            = var.vnets.location
  resource_group_name = var.vnets.resource_group_name

  depends_on = [azurerm_resource_group.rg]
}



resource "azurerm_subnet" "subnet" {
  for_each = var.subnets

  name                 = each.key
  resource_group_name  = each.value.resource_group_name
  virtual_network_name = each.value.virtual_network_name
  address_prefixes     = each.value.address_prefixes
  private_endpoint_network_policies_enabled = try(each.value.private_endpoint_network_policies_enabled, null)

  depends_on = [
    azurerm_resource_group.rg,
    azurerm_virtual_network.vnet
  ]
}


resource "azurerm_public_ip" "pip" {
  name                = var.pip.name
  location            = var.pip.location
  resource_group_name = var.pip.resource_group_name
  allocation_method   = var.pip.allocation_method
  sku                 = var.pip.sku

  depends_on = [
    azurerm_resource_group.rg,
  ]
}

resource "azurerm_bastion_host" "bastion" {
  name                = var.bastion.name
  location            = var.bastion.location
  resource_group_name = var.bastion.resource_group_name

  ip_configuration {
    name                 = var.bastion.ip_configuration.name
    subnet_id            = azurerm_subnet.subnet[var.bastion.ip_configuration.subnet_name].id
    public_ip_address_id = azurerm_public_ip.pip.id
  }

  depends_on = [
    azurerm_resource_group.rg,
    azurerm_virtual_network.vnet,
    azurerm_subnet.subnet,
    azurerm_public_ip.pip
  ]
}

resource "azurerm_network_interface" "nic" {
  name                = var.nic.name
  location            = var.nic.location
  resource_group_name = var.nic.resource_group_name

  ip_configuration {
    name                          = var.nic.ip_configuration.name
    subnet_id                     = azurerm_subnet.subnet[var.nic.ip_configuration.subnet_name].id
    private_ip_address_allocation = var.nic.ip_configuration.private_ip_address_allocation
  }

  depends_on = [azurerm_resource_group.rg]
}

resource "azurerm_windows_virtual_machine" "vm" {
  name                = var.virtual_machine.name
  resource_group_name = var.virtual_machine.resource_group_name
  location            = var.virtual_machine.location
  size                = var.virtual_machine.size
  admin_username      = var.virtual_machine.admin_username
  admin_password      = var.virtual_machine.admin_password
  network_interface_ids = [
    azurerm_network_interface.nic.id,
  ]

  os_disk {
    caching              = var.virtual_machine.os_disk.caching
    storage_account_type = var.virtual_machine.os_disk.storage_account_type
  }

  source_image_reference {
    publisher = var.virtual_machine.source_image_reference.publisher
    offer     = var.virtual_machine.source_image_reference.offer
    sku       = var.virtual_machine.source_image_reference.sku
    version   = var.virtual_machine.source_image_reference.version
  }
  depends_on = [
    azurerm_resource_group.rg,
    azurerm_network_interface.nic
  ]
}

resource "azurerm_storage_account" "sa" { // Not the same storage account that holds your tfstate file.
  name                     = var.storage_account.name
  resource_group_name      = var.storage_account.resource_group_name
  location                 = var.storage_account.location
  account_tier             = var.storage_account.account_tier
  account_replication_type = var.storage_account.account_replication_type

  depends_on = [azurerm_resource_group.rg]
}

resource "azurerm_private_dns_zone" "pdns_zone" {
  name                = var.private_dns_zone.name
  resource_group_name = var.private_dns_zone.resource_group_name

  depends_on = [azurerm_resource_group.rg]
}

resource "azurerm_private_dns_zone_virtual_network_link" "pdns_vnet_link" {
  name                  = var.private_dns_zone_vnet_link.name
  resource_group_name   = var.private_dns_zone_vnet_link.resource_group_name
  private_dns_zone_name = var.private_dns_zone_vnet_link.private_dns_zone_name
  virtual_network_id    = azurerm_virtual_network.vnet.id

  depends_on = [
    azurerm_resource_group.rg,
    azurerm_virtual_network.vnet,
    azurerm_private_dns_zone.pdns_zone
  ]
}

resource "azurerm_private_endpoint" "pe" {
  name                = var.private_endpoint.name
  location            = var.private_endpoint.location
  resource_group_name = var.private_endpoint.resource_group_name
  subnet_id           = azurerm_subnet.subnet[var.private_endpoint.subnet_name].id

  private_service_connection {
    name                           = var.private_endpoint.private_service_connection.name
    private_connection_resource_id = azurerm_storage_account.sa.id
    is_manual_connection           = var.private_endpoint.private_service_connection.is_manual_connection
    subresource_names              = var.private_endpoint.private_service_connection.subresource_names
  }
  private_dns_zone_group {
    name                 = var.private_endpoint.private_service_connection.name
    private_dns_zone_ids = [azurerm_private_dns_zone.pdns_zone.id]
  }
  depends_on = [
    azurerm_resource_group.rg,
    azurerm_virtual_network.vnet,
    azurerm_subnet.subnet
  ]
}
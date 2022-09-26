resource "azurerm_resource_group" "list" {
  for_each = var.resource_groups

  name     = each.name
  location = each.location
}
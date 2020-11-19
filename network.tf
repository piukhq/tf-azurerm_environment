resource "azurerm_availability_set" "controller" {
    name = "${azurerm_resource_group.rg.name}-controller-as"
    location = azurerm_resource_group.rg.location
    resource_group_name = azurerm_resource_group.rg.name
    platform_fault_domain_count = 2
    managed = true

    tags = var.tags
}

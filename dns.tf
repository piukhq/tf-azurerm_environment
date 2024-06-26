resource "azurerm_user_assigned_identity" "cert_manager" {
    resource_group_name = azurerm_resource_group.rg.name
    location = azurerm_resource_group.rg.location

    name = "bink-${azurerm_resource_group.rg.name}-cert-manager"
}

resource "azurerm_role_assignment" "bink_sh" {
    scope = var.bink_sh_zone_id
    role_definition_name = "DNS Zone Contributor"
    principal_id = azurerm_user_assigned_identity.cert_manager.principal_id
}

resource "azurerm_role_assignment" "bink_host" {
    scope = var.bink_host_zone_id
    role_definition_name = "DNS Zone Contributor"
    principal_id = azurerm_user_assigned_identity.cert_manager.principal_id
}

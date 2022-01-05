resource "azurerm_log_analytics_workspace" "i" {
    name = azurerm_resource_group.rg.name
    location = azurerm_resource_group.rg.location
    resource_group_name = azurerm_resource_group.rg.name
    sku = "PerGB2018"
    retention_in_days = 90
}

resource "azurerm_role_assignment" "charlie" {
  scope                = azurerm_log_analytics_workspace.i.id
  role_definition_name = "Contributor"
  principal_id         = "2ef70efe-8675-419d-97cb-4775828383cd"
}

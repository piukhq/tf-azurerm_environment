data "azurerm_client_config" "current" {}

resource "azurerm_key_vault" "common" {
    name = "bink-${azurerm_resource_group.rg.name}-com"
    location = azurerm_resource_group.rg.location
    resource_group_name = azurerm_resource_group.rg.name
    tags = var.tags

    sku_name = "standard"
    enabled_for_disk_encryption = false
    tenant_id = data.azurerm_client_config.current.tenant_id
    purge_protection_enabled = false
}

resource "azurerm_role_assignment" "keyvault_iam" {
    for_each = var.keyvault_iam

    scope = azurerm_key_vault.common.id
    role_definition_name = each.value["role"]
    principal_id = each.value["object_id"]
}


resource "azurerm_monitor_diagnostic_setting" "common_keyvault" {
    name = "diags"
    target_resource_id = azurerm_key_vault.common.id
    log_analytics_workspace_id = var.loganalytics_id

    enabled_log { category = "AuditEvent" }
}

resource "azurerm_key_vault_access_policy" "admin" {
    for_each = local.admin_map

    key_vault_id = azurerm_key_vault.common.id

    tenant_id = data.azurerm_client_config.current.tenant_id
    object_id = each.value

    secret_permissions = local.adminaccess_list
}

resource "azurerm_key_vault_access_policy" "common" {
    for_each = local.normal_msi

    key_vault_id = azurerm_key_vault.common.id

    tenant_id = data.azurerm_client_config.current.tenant_id
    object_id = each.value.id

    secret_permissions = each.value.access
}

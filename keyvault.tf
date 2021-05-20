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

resource "azurerm_monitor_diagnostic_setting" "common_keyvault" {
    name = "logs"
    target_resource_id = azurerm_key_vault.common.id
    eventhub_name = "azurekeyvault"
    eventhub_authorization_rule_id = var.eventhub_authid

    log {
        category = "AuditEvent"
        enabled = true
        retention_policy {
            days = 0
            enabled = false
        }
    }

    metric {
        category = "AllMetrics"
        enabled = false
        retention_policy {
            days = 0
            enabled = false
        }
    }
}

resource "azurerm_key_vault_access_policy" "admin" {
    for_each = local.kv_admin_ids

    key_vault_id = azurerm_key_vault.common.id

    tenant_id = data.azurerm_client_config.current.tenant_id
    object_id = each.value

    secret_permissions = [
        "backup",
        "delete",
        "get",
        "list",
        "purge",
        "recover",
        "restore",
        "set",
    ]
}

resource "azurerm_key_vault_access_policy" "rw" {
    for_each = local.kv_rw_ids

    key_vault_id = azurerm_key_vault.common.id

    tenant_id = data.azurerm_client_config.current.tenant_id
    object_id = each.value

    secret_permissions = [
        "get",
        "list",
        "set",
        "delete"
    ]
}

resource "azurerm_key_vault_access_policy" "ro" {
    for_each = local.kv_ro_ids

    key_vault_id = azurerm_key_vault.common.id

    tenant_id = data.azurerm_client_config.current.tenant_id
    object_id = each.value

    secret_permissions = [
        "get",
        "list"
    ]
}

resource "azurerm_user_assigned_identity" "additional" {
    for_each = var.additional_managed_identities

    resource_group_name = azurerm_resource_group.rg.name
    location = azurerm_resource_group.rg.location

    # Additional is a horrible name to add but it prevents clashes
    # which cause bad things
    name = "bink-${azurerm_resource_group.rg.name}-additional-${each.key}"
}

resource "azurerm_key_vault_access_policy" "additional" {
    for_each = var.additional_managed_identities

    key_vault_id = azurerm_key_vault.common.id

    tenant_id = data.azurerm_client_config.current.tenant_id
    object_id = azurerm_user_assigned_identity.additional[each.key].principal_id

    secret_permissions = each.value["keyvault_permissions"]
}

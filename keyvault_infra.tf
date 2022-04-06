resource "azurerm_key_vault" "infra" {
    name = "bink-${azurerm_resource_group.rg.name}-inf"
    location = azurerm_resource_group.rg.location
    resource_group_name = azurerm_resource_group.rg.name
    tags = var.tags

    sku_name = "standard"
    # All don't need much accidental delete protection as TF populates this KV
    enabled_for_disk_encryption = false
    tenant_id = data.azurerm_client_config.current.tenant_id
    purge_protection_enabled = false
}

resource "azurerm_monitor_diagnostic_setting" "infra_keyvault" {
    name = "diags"
    target_resource_id = azurerm_key_vault.infra.id
    eventhub_name = "azurekeyvault"
    eventhub_authorization_rule_id = var.eventhub_authid
    log_analytics_workspace_id = var.loganalytics_id

    log {
        category = "AuditEvent"
        enabled = true
        retention_policy {
            days    = 0
            enabled = false
        }
    }

    log {
        category = "AzurePolicyEvaluationDetails"
        enabled  = false
        retention_policy {
            days    = 0
            enabled = false
        }
    }

    metric {
        category = "AllMetrics"
        enabled = false
        retention_policy {
            days    = 0
            enabled = false
        }
    }
}

resource "azurerm_key_vault_access_policy" "infra_terraform" {
    key_vault_id = azurerm_key_vault.infra.id

    tenant_id = data.azurerm_client_config.current.tenant_id
    object_id = "4869640a-3727-4496-a8eb-f7fae0872410"

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

# Need to do access policies separately if your going to add additional after
resource "azurerm_key_vault_access_policy" "infra_devops" {
    key_vault_id = azurerm_key_vault.infra.id

    tenant_id = data.azurerm_client_config.current.tenant_id
    object_id = "aac28b59-8ac3-4443-bccc-3fb820165a08"

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

resource "azurerm_key_vault_access_policy" "infra_additional" {
    for_each = var.infra_keyvault_users

    key_vault_id = azurerm_key_vault.infra.id

    tenant_id = data.azurerm_client_config.current.tenant_id
    object_id = each.value["object_id"]

    secret_permissions = each.value["permissions"]
}

resource "azurerm_user_assigned_identity" "infra_sync" {
    resource_group_name = azurerm_resource_group.rg.name
    location = azurerm_resource_group.rg.location

    name = "bink-${azurerm_resource_group.rg.name}-infra-sync"
}

resource "azurerm_key_vault_access_policy" "infra_sync" {
    key_vault_id = azurerm_key_vault.infra.id

    tenant_id = data.azurerm_client_config.current.tenant_id
    object_id = azurerm_user_assigned_identity.infra_sync.principal_id

    secret_permissions = [
        "get",
        "list"
    ]
}

resource "azurerm_key_vault_access_policy" "infra_apps" {
    for_each = local.normal_msi

    key_vault_id = azurerm_key_vault.infra.id

    tenant_id = data.azurerm_client_config.current.tenant_id
    object_id = each.value.id

    secret_permissions = each.value.access
}

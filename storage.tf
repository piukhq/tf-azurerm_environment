locals {
    storage_iam_foreach = {
        for role_id, role_data in var.storage_iam : "${role_data.storage_id}-${role_id}" => {
            storage_id = azurerm_storage_account.storage[role_data.storage_id].id
            object_id = role_data.object_id
            role = role_data.role
        }
    }
}


resource "azurerm_storage_account" "storage" {
    for_each = var.storage_config

    name = each.value["name"]
    resource_group_name = azurerm_resource_group.rg.name
    location = azurerm_resource_group.rg.location
    tags = var.tags

    cross_tenant_replication_enabled = false
    account_tier = lookup(each.value, "account_tier", "Standard")
    account_replication_type = lookup(each.value, "account_replication_type", "ZRS")
    min_tls_version = "TLS1_2"

    allow_nested_items_to_be_public = true
}

resource "azurerm_role_assignment" "storage_iam" {
    for_each = local.storage_iam_foreach

    scope = each.value.storage_id
    role_definition_name = each.value.role
    principal_id = each.value.object_id
}

resource "azurerm_storage_management_policy" "storage" {
    for_each = var.storage_management_policy_config

    storage_account_id = azurerm_storage_account.storage[each.key].id

    dynamic "rule" {
        for_each = each.value

        content {
            name = rule.value["name"]
            enabled = rule.value["enabled"]
            filters {
                prefix_match = rule.value["prefix_match"]
                blob_types = ["blockBlob"]
            }
            actions {
                base_blob {
                    delete_after_days_since_modification_greater_than = rule.value["delete_after_days"]
                }
            }
        }
    }
}

resource "azurerm_key_vault_secret" "storage_individual_pass" {
    for_each = var.storage_config

    name = "infra-storage-${each.key}"
    value = jsonencode({
        "account" : each.value["name"],
        "key" : azurerm_storage_account.storage[each.key].primary_access_key,
        "connection_string" : azurerm_storage_account.storage[each.key].primary_connection_string,
        "blob_connection_string" : azurerm_storage_account.storage[each.key].primary_blob_connection_string
    })
    content_type = "application/json"
    key_vault_id = azurerm_key_vault.infra.id

    tags = {
        k8s_secret_name = "azure-storage-${each.key}"
    }
}


resource "azurerm_monitor_diagnostic_setting" "storage" {
    for_each = var.storage_config

    name = "diags"
    target_resource_id = "${azurerm_storage_account.storage[each.key].id}/blobServices/default"
    log_analytics_workspace_id = var.loganalytics_id

    enabled_log { category = "StorageRead" }
    enabled_log { category = "StorageWrite" }
    enabled_log { category = "StorageDelete" }
    metric {
        category = "Capacity"
        enabled = false
    }
    metric {
        category = "Transaction"
        enabled = false
    }
}

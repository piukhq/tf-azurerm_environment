resource "azurerm_storage_account" "storage" {
    for_each = var.storage_config

    name = each.value["name"]
    resource_group_name = azurerm_resource_group.rg.name
    location = azurerm_resource_group.rg.location
    tags = var.tags

    account_tier = lookup(each.value, "account_tier", "Standard")
    account_replication_type = lookup(each.value, "account_replication_type", "ZRS")
    min_tls_version = "TLS1_2"

    allow_blob_public_access = true
}

locals {
    policy_rule_list = flatten([
        for storage_account_key, policies in var.storage_management_policy_config: [
            for policy in policies: {
                storage_account_key = storage_account_key
                name = policy.name
                enabled = policy.enabled
                prefix_match = policy.prefix_match
                delete_after_days = policy.delete_after_days
            }
        ]
    ])
}

resource "azurerm_storage_management_policy" "storage" {
    for_each = {
        for policy_key, policy_value in local.policy_rule_list : policy_key => policy_value
    }

    storage_account_id = azurerm_storage_account.storage[each.value.storage_account_key].id

    rule {
        name    = each.value.name
        enabled = each.value.enabled
        filters {
            prefix_match = each.value.prefix_match
            blob_types   = ["blockBlob"]
        }
        actions {
            base_blob {
                delete_after_days_since_modification_greater_than = each.value.delete_after_days
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
        k8s_namespaces = "default"
    }
}


resource "azurerm_monitor_diagnostic_setting" "storage" {
    for_each = var.storage_config

    name = "logs"
    target_resource_id = "${azurerm_storage_account.storage[each.key].id}/blobServices/default"
    eventhub_name = "azurestorage"
    eventhub_authorization_rule_id = var.eventhub_authid

    log {
        category = "StorageRead"
        enabled = true
        retention_policy {
            days = 0
            enabled = false
        }
    }
    log {
        category = "StorageWrite"
        enabled = true
        retention_policy {
            days = 0
            enabled = false
        }
    }
    log {
        category = "StorageDelete"
        enabled = true
        retention_policy {
            days = 0
            enabled = false
        }
    }

    metric {
        category = "Capacity"
        enabled = false
        retention_policy {
            days = 0
            enabled = false
        }
    }

    metric {
        category = "Transaction"
        enabled = false
        retention_policy {
            days = 0
            enabled = false
        }
    }
}

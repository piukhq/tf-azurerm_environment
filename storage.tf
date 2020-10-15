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

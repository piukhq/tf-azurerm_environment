# TODO: Terry to explain what the fuck this line of code does.

locals {
    dynamic_admins = [ for pair in setproduct(var.additional_keyvaults, values(local.kv_admin_ids)) : { 
            kv_name = pair[0]
            id = pair[1]
        }
    ]
    dynamic_rw = [ for pair in setproduct(var.additional_keyvaults, values(local.kv_rw_ids)) : { 
            kv_name = pair[0]
            id = pair[1]
        }
    ]
    dynamic_ro = [ for pair in setproduct(var.additional_keyvaults, values(local.kv_ro_ids)) : { 
            kv_name = pair[0]
            id = pair[1]
        }
    ]
}

resource "azurerm_key_vault" "add_kv" {
    for_each = {
        for item in var.additional_keyvaults : item => item 
    }

    name = each.value
    location = azurerm_resource_group.rg.location
    resource_group_name = azurerm_resource_group.rg.name
    tags = var.tags

    sku_name = "standard"
    enabled_for_disk_encryption = false
    tenant_id = data.azurerm_client_config.current.tenant_id
    purge_protection_enabled = false
}

resource "azurerm_key_vault_access_policy" "add_admin" {
    for_each = {
        for item in local.dynamic_admins : "${item.kv_name}.${item.id}" => item
    }

    key_vault_id = azurerm_key_vault.add_kv[each.value.kv_name].id

    tenant_id = data.azurerm_client_config.current.tenant_id
    object_id = each.value.id

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

resource "azurerm_key_vault_access_policy" "add_rw" {
    for_each = {
        for item in local.dynamic_rw : "${item.kv_name}.${item.id}" => item
    }

    key_vault_id = azurerm_key_vault.add_kv[each.value.kv_name].id

    tenant_id = data.azurerm_client_config.current.tenant_id
    object_id = each.value.id

    secret_permissions = [
        "get",
        "list",
        "set",
        "delete"
    ]
}

resource "azurerm_key_vault_access_policy" "add_ro" {
    for_each = {
        for item in local.dynamic_ro : "${item.kv_name}.${item.id}" => item
    }

    key_vault_id = azurerm_key_vault.add_kv[each.value.kv_name].id

    tenant_id = data.azurerm_client_config.current.tenant_id
    object_id = each.value.id

    secret_permissions = [
        "get",
        "list"
    ]
}

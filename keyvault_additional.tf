# TODO: Terry to explain what the fuck this line of code does.


locals {
    admin_map = merge(var.keyvault_users, local.kv_admin_ids)
    admin_list = [for name, id in local.admin_map : { name = name, id = id }]  # Convert to list
    msi_list = [for name, data in var.managed_identities : { name = name, id = azurerm_user_assigned_identity.app[name].principal_id, access = data.kv_access }]
    ro_list = ["Get", "List"]
    rw_list = ["Get", "List", "Set", "Delete"]
    adminaccess_list = ["Backup", "Delete", "Get", "List", "Purge", "Recover", "Restore", "Set"]

    # var.additional_keyvaults = ['keyvault1', 'keyvault2']
    # local.admin_list = [ {name = "jeff", id = "1234"}, {name = "bezos", id = "5678"}, ...]
    # local.msi_list = [ {name = "hermes", id = "/blah/1234", kv_access="ro"},  ...]

    # setproduct basically does a nested for loop, so for every item of the first list, it outputs a tuple of that item, and each item of the 2nd list
    # e.g setproduct([a,b], [c,d,e]) => [ [a,c], [a,d], [a,e], [b,c], [b,d], [b,e] ]

    dynamic_admins = { for pair in setproduct(var.additional_keyvaults, local.admin_list) : "${pair[0]}.${pair[1].name}" => {
        kv_name = pair[0]
        kv_id = azurerm_key_vault.add_kv[pair[0]].id
        name = pair[1].name
        id = pair[1].id
        access = local.adminaccess_list
        }
    }

    dynamic_msi = { for pair in setproduct(var.additional_keyvaults, local.msi_list) : "${pair[0]}.${pair[1].name}" => {
        kv_name = pair[0]
        kv_id = azurerm_key_vault.add_kv[pair[0]].id
        name = pair[1].name
        id = pair[1].id
        access = pair[1].access == "ro" ? local.ro_list : local.rw_list
        }
    }
    normal_msi = { for data in local.msi_list : data.name => {
        name = data.name
        id = data.id
        access = data.access == "ro" ? local.ro_list : local.rw_list
        }
    }


    dynamic_iam = flatten([ for keyvault_id in var.additional_keyvaults : [
        for iam_id, iam_data in var.keyvault_iam : {
            key = "${keyvault_id}_${iam_id}"
            kv_id = azurerm_key_vault.add_kv[keyvault_id].id
            role = iam_data.role
            object_id = iam_data.object_id
        }
    ]])
    dynamic_iam_foreach = { for item in local.dynamic_iam : item.key => item }
}

resource "azurerm_key_vault" "add_kv" {
    for_each = toset(var.additional_keyvaults)

    name = each.key
    location = azurerm_resource_group.rg.location
    resource_group_name = azurerm_resource_group.rg.name
    tags = var.tags

    sku_name = "standard"
    enabled_for_disk_encryption = false
    tenant_id = data.azurerm_client_config.current.tenant_id
    purge_protection_enabled = false
}


resource "azurerm_role_assignment" "add_keyvault_iam" {
    for_each = local.dynamic_iam_foreach

    scope = each.value.kv_id
    role_definition_name = each.value.role
    principal_id = each.value.object_id
}

resource "azurerm_monitor_diagnostic_setting" "add_kv" {
    for_each = toset(var.additional_keyvaults)

    name = "diags"
    target_resource_id = azurerm_key_vault.add_kv[each.key].id
    log_analytics_destination_type = "AzureDiagnostics"
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

resource "azurerm_key_vault_access_policy" "add_admin" {
    for_each = local.dynamic_admins

    key_vault_id = each.value.kv_id

    tenant_id = data.azurerm_client_config.current.tenant_id
    object_id = each.value.id

    secret_permissions = each.value.access
}

resource "azurerm_key_vault_access_policy" "add_msi" {
    for_each = local.dynamic_msi

    key_vault_id = each.value.kv_id

    tenant_id = data.azurerm_client_config.current.tenant_id
    object_id = each.value.id

    secret_permissions = each.value.access
}

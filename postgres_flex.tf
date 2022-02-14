locals {
    connection_strings = merge(flatten([[
        for k, v in var.postgres_flexible_config:
            { for db in v.databases: "${k}_${db}" => "postgresql://${random_pet.pgfs[k].id}:${random_password.pgfs[k].result}@${azurerm_postgresql_flexible_server.pgfs[k].fqdn}/${db}?sslmode=require" }
    ], [
        for k, v in var.postgres_flexible_config:
            {
                "${k}_username" = "${random_pet.pgfs[k].id}",
                "${k}_password" = "${random_password.pgfs[k].result}",
                "${k}_host" = "${azurerm_postgresql_flexible_server.pgfs[k].fqdn}",
            }
    ]])...)
    pgfs_iam_collection = flatten([for pg_id, pg_data in var.postgres_flexible_config : [
        for role_id, role_data in var.postgres_iam : {
            key = "${pg_id}-${role_id}"
            postgres_id = azurerm_postgresql_flexible_server.pgfs[pg_id].id
            object_id = role_data.object_id
            role = role_data.role
        }
        ]
    ])
    pgfs_iam_foreach = { for pg_item in local.pgfs_iam_collection : pg_item.key => pg_item }
}


resource "azurerm_private_dns_zone" "pgfs" {
    name = "private.postgres.database.azure.com"
    resource_group_name = azurerm_resource_group.rg.name
}

resource "azurerm_private_dns_zone_virtual_network_link" "pgfs" {
    name = "private.postgres.database.azure.com"
    private_dns_zone_name = azurerm_private_dns_zone.pgfs.name
    virtual_network_id = azurerm_virtual_network.vnet.id
    resource_group_name = azurerm_resource_group.rg.name
}

resource "random_pet" "pgfs" {
    for_each = var.postgres_flexible_config
    length = 1
}

resource "random_password" "pgfs" {
    for_each = var.postgres_flexible_config

    length = 24
    special = false
}

resource "azurerm_postgresql_flexible_server" "pgfs" {
    for_each = var.postgres_flexible_config

    name = each.value.name
    resource_group_name = azurerm_resource_group.rg.name
    location = azurerm_resource_group.rg.location
    version = each.value.version
    delegated_subnet_id = azurerm_subnet.postgres.id
    private_dns_zone_id = azurerm_private_dns_zone.pgfs.id
    administrator_login = random_pet.pgfs[each.key].id
    administrator_password = random_password.pgfs[each.key].result

    storage_mb = each.value.storage_mb

    dynamic "high_availability" {
        for_each = each.value.high_availability ? [1] : []
        content {
            mode = "ZoneRedundant"
        }
    }

    sku_name   = each.value.sku_name
    depends_on = [azurerm_private_dns_zone_virtual_network_link.pgfs]
    lifecycle {
        ignore_changes = [zone, high_availability.0.standby_availability_zone]
    }
}

resource "azurerm_monitor_diagnostic_setting" "pgfs" {
    for_each = var.postgres_flexible_config
    name = "diags"
    target_resource_id = azurerm_postgresql_flexible_server.pgfs[each.key].id
    log_analytics_workspace_id = azurerm_log_analytics_workspace.i.id

    log {
        category = "PostgreSQLLogs"
    }

    metric {
        category = "AllMetrics"
    }
}

resource "azurerm_postgresql_flexible_server_configuration" "pgbouncer" {
    for_each = var.postgres_flexible_config
    name = "pgbouncer.enabled"
    value = "True"
    server_id = azurerm_postgresql_flexible_server.pgfs[each.key].id
}

resource "azurerm_role_assignment" "pgfs" {
    for_each = local.pgfs_iam_foreach

    scope = each.value.postgres_id
    role_definition_name = each.value.role
    principal_id = each.value.object_id
}

resource "azurerm_key_vault_secret" "pgfs" {
    name = "infra-pgfs"
    value = jsonencode(local.connection_strings)
    content_type = "application/json"
    key_vault_id = azurerm_key_vault.infra.id

    tags = {
        k8s_secret_name = "azure-pgfs"
        k8s_namespaces = var.secret_namespaces
    }
}

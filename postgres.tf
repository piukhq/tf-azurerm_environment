resource "random_password" "pg" {
    for_each = var.postgres_config

    length = 24
    special = false
}

resource "azurerm_postgresql_server" "pg" {
    for_each = var.postgres_config

    name = each.value["name"]
    location = azurerm_resource_group.rg.location
    resource_group_name = azurerm_resource_group.rg.name
    tags = var.tags

    administrator_login = each.key
    administrator_login_password = random_password.pg[each.key].result

    sku_name = lookup(each.value, "sku_name", "GP_Gen5_2")
    version = lookup(each.value, "version", "11")
    storage_mb = lookup(each.value, "storage_gb", 100) * 1024

    backup_retention_days = lookup(each.value, "backup_retention_days", 7)
    geo_redundant_backup_enabled = lookup(each.value, "geo_redundant_backup_enabled", false)
    auto_grow_enabled = lookup(each.value, "auto_grow_enabled", false)

    # public_network_access_enabled = lookup(each.value, "public_network_access_enabled", false)
    public_network_access_enabled = true
    ssl_enforcement_enabled = lookup(each.value, "ssl_enforcement_enabled", true)
    ssl_minimal_tls_version_enforced = lookup(each.value, "ssl_minimal_tls_version_enforced", "TLS1_2")
}

resource "azurerm_monitor_diagnostic_setting" "pg" {
    for_each = var.postgres_config

    name = "logs"
    target_resource_id = azurerm_postgresql_server.pg[each.key].id
    eventhub_name = "azurepostgres"
    eventhub_authorization_rule_id = var.eventhub_authid

    log {
        category = "PostgreSQLLogs"
        enabled = true
        retention_policy {
            days = 0
            enabled = false
        }
    }
    log {  # Disabled as it might send queries to redscam
        category = "QueryStoreRuntimeStatistics"
        enabled = false
        retention_policy {
            days = 0
            enabled = false
        }
    }
    log {  # Disabled as it might send queries to redscam
        category = "QueryStoreWaitStatistics"
        enabled = false
        retention_policy {
            days = 0
            enabled = false
        }
    }

    metric {
        category = "Errors"
        enabled = false
        retention_policy {
            days = 0
            enabled = false
        }
    }
    metric {
        category = "Latency"
        enabled = false
        retention_policy {
            days = 0
            enabled = false
        }
    }
    metric {
        category = "Saturation"
        enabled = false
        retention_policy {
            days = 0
            enabled = false
        }
    }
    metric {
        category = "Traffic"
        enabled = false
        retention_policy {
            days = 0
            enabled = false
        }
    }
}

# This opens up Postgres to connections from any Azure customer, we should figure out a better way of doing this
resource "azurerm_postgresql_firewall_rule" "azure" {
    for_each = var.postgres_config

    name = "${each.value["name"]}-azure"
    resource_group_name = azurerm_resource_group.rg.name
    server_name = azurerm_postgresql_server.pg[each.key].name
    start_ip_address = "0.0.0.0"
    end_ip_address = "0.0.0.0"
}

resource "azurerm_key_vault_secret" "azure_synapse_pg_individual_pass" {
    for_each = var.postgres_config

    name = "synapse-postgres-${each.key}"

    # value = "Server=${azurerm_postgresql_server.pg[each.key].fqdn};Database=TODO;Port=5432;UID=${azurerm_postgresql_server.pg[each.key].administrator_login}@${azurerm_postgresql_server.pg[each.key].name};Password=${random_password.pg[each.key].result}"
    # So its entirely possible we could store the entire DSN here, but it requires us to specify the Database explicitly which might be "*"
    value = random_password.pg[each.key].result
    key_vault_id = azurerm_key_vault.infra.id

}

resource "azurerm_key_vault_secret" "pg_individual_pass" {
    for_each = var.postgres_config

    name = "infra-pg-${each.key}"
    value = jsonencode({
        "host" : azurerm_postgresql_server.pg[each.key].fqdn,
        "port" : "5432",
        "admin_user" : "${azurerm_postgresql_server.pg[each.key].administrator_login}@${azurerm_postgresql_server.pg[each.key].name}",
        "password" : random_password.pg[each.key].result,
        "dsn" : "host=${azurerm_postgresql_server.pg[each.key].fqdn} user=${azurerm_postgresql_server.pg[each.key].administrator_login}@${azurerm_postgresql_server.pg[each.key].name} sslmode=verify-ca password=${random_password.pg[each.key].result}"
        "uri" : "postgresql://${azurerm_postgresql_server.pg[each.key].administrator_login}@${azurerm_postgresql_server.pg[each.key].name}:${random_password.pg[each.key].result}@${azurerm_postgresql_server.pg[each.key].fqdn}/postgres?sslmode=verify-ca"
        # "databases": each.value["databases"]
    })
    content_type = "application/json"
    key_vault_id = azurerm_key_vault.infra.id

    tags = {
        k8s_secret_name = "azure-pg-${each.key}"
        k8s_namespaces = "default"
        # k8s_convert = "file:/app/templates/pgbouncer.yaml"
    }
}

resource "azurerm_key_vault_secret" "pg_all_pass" {
    name = "infra-pg-all"
    value = jsonencode({
        "servers" : [for key, res in azurerm_postgresql_server.pg : {
            host = res.fqdn
            port = "5432"
            admin_user = "${res.administrator_login}@${res.name}"
            password = random_password.pg[key].result
            "databases" : var.postgres_config[key]["databases"]
        }]
    })
    content_type = "application/json"
    key_vault_id = azurerm_key_vault.infra.id

    tags = {
        k8s_secret_name = "azure-pg-all"
        k8s_namespaces = "default"
        k8s_convert = "file:/app/templates/pgbouncer.yaml"
    }
}

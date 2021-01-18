resource "azurerm_servicebus_namespace" "common" {
    name = "${azurerm_resource_group.rg.name}-common"
    location = azurerm_resource_group.rg.location
    resource_group_name = azurerm_resource_group.rg.name
    sku = var.service_bus.sku
    capacity = var.service_bus.capacity
    zone_redundant = var.service_bus.zone_redundant
    tags = var.tags
}

resource "azurerm_key_vault_secret" "servicebus_common" {
    name = "infra-servicebus-common"
    value = jsonencode({
        "primary_key" : azurerm_servicebus_namespace.common.default_primary_key,
        "azure_connection_string" : azurerm_servicebus_namespace.common.default_primary_connection_string,
        "kombu_connection_string" : "azureservicebus://RootManageSharedAccessKey:${azurerm_servicebus_namespace.common.default_primary_key}@${azurerm_servicebus_namespace.common.name}"
    })
    content_type = "application/json"
    key_vault_id = azurerm_key_vault.infra.id

    tags = {
        k8s_secret_name = "azure-servicebus-common",
        k8s_namespaces = "default"
    }
}

resource "azurerm_monitor_diagnostic_setting" "servicebus" {
    name = "logs"
    target_resource_id = azurerm_servicebus_namespace.common.id
    eventhub_name = "azureservicebus"
    eventhub_authorization_rule_id = var.eventhub_authid

    log {
        category = "OperationalLogs"
        enabled = true
        retention_policy {
            days = 0
            enabled = false
        }
    }
}

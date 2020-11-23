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
    for_each = var.postgres_config

    name = "infra-servicebus-common"
    value = jsonencode({
        "primary_key" : azurerm_servicebus_namespace.common.default_primary_key,
        "azure_connection_string" : azurerm_servicebus_namespace.common.default_primary_connection_string,
        "kombu_connection_string" : "azureservicebus://RootManageSharedAccessKey:${azurerm_servicebus_namespace.common.default_primary_key}@${azurerm_servicebus_namespace.common.name}"
    })
    content_type = "application/json"
    key_vault_id = azurerm_key_vault.infra.id

    tags = {
        k8s_secret_name = "infra-servicebus-common",
        k8s_namespaces = "default"
    }
}

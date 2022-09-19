locals {
    # bink-uksouth-dev-loyalty = { 
    #   name = "loyalty"
    #   ...
    #   eventhubs = {
    #     audit = {...}
    #     history = {...}
    #     poo = {...}
    #   }
    # }
    #
    eventhub_collection = flatten([for eventhub_ns, ns_data in var.eventhubs : [
        for eventhub_name, eh_data in ns_data.eventhubs : {
            key = "${ns_data.name}-${eventhub_name}"
            namespace_name = eventhub_ns
            namespace_friendly_name = ns_data.name
            name = eventhub_name
            partition_count = eh_data.partition_count
            message_retention = eh_data.message_retention
        }
        ]
    ])
    eventhub_foreach = { for evenhub_item in local.eventhub_collection : evenhub_item.key => evenhub_item }

}
output "test" {
    value = local.eventhub_foreach
}

resource "azurerm_eventhub_namespace" "ns" {
    for_each = var.eventhubs

    name = each.key
    location = azurerm_resource_group.rg.location
    resource_group_name = azurerm_resource_group.rg.name
    sku = each.value.sku
    capacity = each.value.capacity

    tags = var.tags
}

resource "azurerm_eventhub" "hub" {
    for_each = local.eventhub_foreach

    name = each.value.name
    namespace_name = azurerm_eventhub_namespace.ns[each.value.namespace_name].name
    resource_group_name = azurerm_resource_group.rg.name
    partition_count = each.value.partition_count
    message_retention = each.value.message_retention
}

# # Make some access keys of varying levels
resource "azurerm_eventhub_authorization_rule" "hub_all" {
    for_each = local.eventhub_foreach

    name = "${each.key}-all"
    namespace_name = azurerm_eventhub_namespace.ns[each.value.namespace_name].name
    eventhub_name = azurerm_eventhub.hub[each.key].name
    resource_group_name = azurerm_resource_group.rg.name
    listen = true
    send = true
    manage = true
}
resource "azurerm_eventhub_authorization_rule" "hub_listen" {
    for_each = local.eventhub_foreach

    name = "${each.key}-listen"
    namespace_name = azurerm_eventhub_namespace.ns[each.value.namespace_name].name
    eventhub_name = azurerm_eventhub.hub[each.key].name
    resource_group_name = azurerm_resource_group.rg.name
    listen = true
    send = false
    manage = false
}
resource "azurerm_eventhub_authorization_rule" "hub_send" {
    for_each = local.eventhub_foreach

    name = "${each.key}-send"
    namespace_name = azurerm_eventhub_namespace.ns[each.value.namespace_name].name
    eventhub_name = azurerm_eventhub.hub[each.key].name
    resource_group_name = azurerm_resource_group.rg.name
    listen = false
    send = true
    manage = false
}

# Put keys in KV secret
resource "azurerm_key_vault_secret" "hub_auth" {
    for_each = local.eventhub_foreach

    name = "infra-eventhub-${each.key}"
    value = jsonencode({
        "all" : azurerm_eventhub_authorization_rule.hub_all[each.key].primary_connection_string,
        "listen" : azurerm_eventhub_authorization_rule.hub_listen[each.key].primary_connection_string,
        "send" : azurerm_eventhub_authorization_rule.hub_send[each.key].primary_connection_string,
    })
    content_type = "application/json"
    key_vault_id = azurerm_key_vault.infra.id

    tags = {
        k8s_secret_name = "azure-eventhub-${each.key}"
    }
}

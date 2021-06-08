locals {
    redis_iam_collection = flatten([for redis_id, redis_data in var.redis_config : [
        for role_id, role_data in var.redis_iam : {
            key = "${redis_id}-${role_id}"
            redis_id = azurerm_redis_cache.redis[redis_id].name
            object_id = role_data.object_id
            role = role_data.role
        }
        ]
    ])
    redis_iam_foreach = { for pg_item in local.pg_iam_collection : pg_item.key => pg_item }
}


resource "azurerm_redis_cache" "redis" {
    for_each = var.redis_config

    name = each.value["name"]
    location = azurerm_resource_group.rg.location
    resource_group_name = azurerm_resource_group.rg.name
    tags = var.tags

    capacity = lookup(each.value, "capacity", 1)
    family = lookup(each.value, "family", "C")
    sku_name = lookup(each.value, "sku_name", "Standard")
    enable_non_ssl_port = lookup(each.value, "enable_non_ssl_port", true)
    minimum_tls_version = lookup(each.value, "minimum_tls_version", "1.2")

    redis_configuration {}

    patch_schedule {
        day_of_week = var.redis_patch_schedule.day_of_week
        start_hour_utc = var.redis_patch_schedule.start_hour_utc
    }
}

resource "azurerm_role_assignment" "redis_iam" {
    for_each = local.redis_iam_foreach

    scope = each.value.redis_id
    role_definition_name = each.value.role
    principal_id = each.value.object_id
}

resource "azurerm_key_vault_secret" "redis_individual_pass" {
    for_each = var.redis_config

    name = "infra-redis-${each.key}"
    value = jsonencode({
        "host" : azurerm_redis_cache.redis[each.key].hostname,
        "port" : tostring(azurerm_redis_cache.redis[each.key].port),
        "ssl_port" : tostring(azurerm_redis_cache.redis[each.key].ssl_port),
        "password" : azurerm_redis_cache.redis[each.key].primary_access_key,
        "azure_connection_string" : azurerm_redis_cache.redis[each.key].primary_connection_string,
        "uri" : "redis://:${azurerm_redis_cache.redis[each.key].primary_access_key}@${azurerm_redis_cache.redis[each.key].hostname}:${azurerm_redis_cache.redis[each.key].port}/0",
        "uri_ssl" : "rediss://:${azurerm_redis_cache.redis[each.key].primary_access_key}@${azurerm_redis_cache.redis[each.key].hostname}:${azurerm_redis_cache.redis[each.key].ssl_port}/0",
    })
    content_type = "application/json"
    key_vault_id = azurerm_key_vault.infra.id

    tags = {
        k8s_secret_name = "azure-redis-${each.key}"
        k8s_namespaces = var.secret_namespaces
    }
}

resource "azurerm_redis_firewall_rule" "uksouth_firewall" {
    for_each = var.redis_config

    name = "uksouth_firewall"
    redis_cache_name = azurerm_redis_cache.redis[each.key].name
    resource_group_name = azurerm_resource_group.rg.name
    start_ip = "51.132.44.240"
    end_ip = "51.132.44.255"
}

resource "azurerm_redis_firewall_rule" "binkhq" {
    for_each = var.redis_config

    name = "binkhq"
    redis_cache_name = azurerm_redis_cache.redis[each.key].name
    resource_group_name = azurerm_resource_group.rg.name
    start_ip = "194.74.152.11"
    end_ip = "194.74.152.11"
}

resource "azurerm_redis_firewall_rule" "wireguard" {
    for_each = var.redis_config

    name = "wireguard"
    redis_cache_name = azurerm_redis_cache.redis[each.key].name
    resource_group_name = azurerm_resource_group.rg.name
    start_ip = "20.49.163.188"
    end_ip = "20.49.163.188"
}

resource "azurerm_redis_enterprise_cluster" "redis_enterprise" {
    for_each = var.redis_enterprise_config

    name = each.value["name"]

    resource_group_name = azurerm_resource_group.rg.name
    location = azurerm_resource_group.rg.location

    sku_name = "Enterprise_E10-2"

    zones = ["1", "2", "3"]
    # tags = var.tags ## Commented out until https://github.com/hashicorp/terraform-provider-azurerm/issues/13076 is fixed
}

resource "azurerm_redis_enterprise_database" "redis_enterprise_db" {
    for_each = var.redis_enterprise_config

    name = "default"

    cluster_id = azurerm_redis_enterprise_cluster.redis_enterprise[each.key].id
}

resource "azurerm_redis_enterprise_cluster" "redis_enterprise" {
    for_each = var.redis_enterprise_config

  name                = each.value["name"]

  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location

  sku_name = "Enterprise_E10-2"

  zones = ["1", "2", "3"]
  tags = var.tags
}

resource "azurerm_redis_enterprise_database" "redis_enterprise_db" {
for_each = var.redis_enterprise_config

  name                = "common"
  resource_group_name = azurerm_resource_group.rg.name

  cluster_id = azurerm_redis_enterprise_cluster.redis_enterprise.id
}

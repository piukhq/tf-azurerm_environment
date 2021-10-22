resource "azurerm_virtual_network" "vnet" {
    name = "${azurerm_resource_group.rg.name}-vnet"
    location = azurerm_resource_group.rg.location
    resource_group_name = azurerm_resource_group.rg.name
    address_space = [var.vnet_cidr]
}

resource "azurerm_subnet" "postgres" {
    name = "postgres"
    resource_group_name = azurerm_resource_group.rg.name
    virtual_network_name = azurerm_virtual_network.vnet.name
    address_prefixes = [cidrsubnet(var.vnet_cidr, 3, 0)]
    service_endpoints = [ "Microsoft.Storage" ]
    delegation {
        name = "fs"
        service_delegation {
            name = "Microsoft.DBforPostgreSQL/flexibleServers"
            actions = [
                "Microsoft.Network/virtualNetworks/subnets/join/action",
            ]
        }
    }
}

resource "azurerm_subnet" "redis" {
    name = "redis"
    resource_group_name = azurerm_resource_group.rg.name
    virtual_network_name = azurerm_virtual_network.vnet.name
    address_prefixes = [cidrsubnet(var.vnet_cidr, 3, 1)]
}
module "aks" {
    source = "./submodules/aks"
    providers = {
        azurerm = azurerm
        azurerm.core = azurerm.core
    }
    for_each = var.aks

    common = {
        resource_group = {
            name = azurerm_resource_group.rg.name
            id = azurerm_resource_group.rg.id
            location = azurerm_resource_group.rg.location
        }
        loganalytics_id = var.loganalytics_id
        peer = {
            vnet_id = azurerm_virtual_network.vnet.id
            vnet_name = azurerm_virtual_network.vnet.name
        }
        dns = {
            postgres = {
                name = azurerm_private_dns_zone.pgfs.name
            }
            private = {
                name = each.value.dns.private.name
                resource_group = each.value.dns.private.resource_group
            }
            public = {
                name = each.value.dns.public.name
                resource_group = each.value.dns.public.resource_group
            }
        }
        registries = {
            binkcore = "/subscriptions/0add5c8e-50a6-4821-be0f-7a47c879b009/resourceGroups/uksouth-core/providers/Microsoft.ContainerRegistry/registries/binkcore"
            binkext = "/subscriptions/0add5c8e-50a6-4821-be0f-7a47c879b009/resourceGroups/uksouth-core/providers/Microsoft.ContainerRegistry/registries/binkext"
        }
    }

    firewall = {
        config = each.value.firewall.config
        rule_priority = each.value.firewall.rule_priority
        ingress = {
            source_ip_groups = each.value.firewall.ingress.source_ip_groups
            source_addr = each.value.firewall.ingress.source_addr
            public_ip = each.value.firewall.ingress.public_ip
            http_port = each.value.firewall.ingress.http_port
            https_port = each.value.firewall.ingress.https_port
        }
    }

    cluster = {
        name = each.value.name
        cidr = each.value.cidr
        api_ip_ranges = each.value.api_ip_ranges
        updates = each.value.updates
        sku = each.value.sku
        node_max_count = each.value.node_max_count
        node_size = each.value.node_size
        maintenance_day = each.value.maintenance_day
        iam = each.value.iam
        zones = each.value.zones
        os_disk_type = each.value.os_disk_type
    }
}

output "aks_flux_config" { value = { for k, v in module.aks: k => v.flux_config }}

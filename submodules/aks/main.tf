terraform {
    required_providers {
        azurerm = {
            source  = "hashicorp/azurerm"
            version = ">= 3.7.0"
            configuration_aliases = [ azurerm.core ]
        }
    }
}

variable "common" {
    type = object({
        resource_group = object({
            name = string
            id = string
            location = string
        })
        peer = object({
            vnet_name = string
            vnet_id = string
        })
        loganalytics_id = string
        dns = object({
            postgres = object({
                name = string
            })
            private = object({
                resource_group = string
                primary_zone = string
                secondary_zones = list(string)
            })
            public = object({
                name = string
                resource_group = string
            })
        })
        aad_admin_group_object_ids = list(string)
        registries = map(string)
    })
}

variable "firewall" {
    type = object({
        rule_priority = number
        ingress = optional(object({
            source_ip_groups = optional(list(string))
            source_addr = optional(list(string))
            public_ip = string
            http_port = number
            https_port = number
        }))
        config = object({
            resource_group = object({
                name = string
            })
            virtual_network = object({
                name = string
                id = string
            })
            firewall = object({
                name = string
                ip = string
            })
        })
    })
}

variable "cluster" {
    type = object({
        name = string
        cidr = string
        api_ip_ranges = optional(list(string), [])
        updates = string
        sku = optional(string, "Free")
        node_count = optional(number, 1)
        zones = optional(list(string), ["1","2","3"])
        os_disk_type = optional(string, "Ephemeral")
        node_size = optional(string, "Standard_E4ads_v5")
        maintenance_day = string
        iam = map(object({
            object_id = string
            role = string
        }))
    })
}

locals {
    full_name = "${var.common.resource_group.location}-${var.cluster.name}"
}

data "azurerm_subscription" "i" {}

resource "azurerm_virtual_network" "i" {
    name = local.full_name
    resource_group_name = var.common.resource_group.name
    location = var.common.resource_group.location
    address_space = [ var.cluster.cidr ]
    subnet {
        address_prefix = var.cluster.cidr
        name = "AzureKubernetesService"
    }
}

resource "azurerm_route_table" "i" {
    name = local.full_name
    resource_group_name = var.common.resource_group.name
    location = var.common.resource_group.location
    disable_bgp_route_propagation = true

    route {
        name = "default"
        address_prefix = "0.0.0.0/0"
        next_hop_type = "VirtualAppliance"
        next_hop_in_ip_address = var.firewall.config.firewall.ip
    }
}

resource "azurerm_subnet_route_table_association" "i" {
    subnet_id = one(azurerm_virtual_network.i.subnet[*].id)
    route_table_id = azurerm_route_table.i.id
}

resource "azurerm_virtual_network_peering" "local-to-env" {
    name = "local-to-env"
    resource_group_name = var.common.resource_group.name
    virtual_network_name = azurerm_virtual_network.i.name
    remote_virtual_network_id = var.common.peer.vnet_id
    allow_virtual_network_access = true
    allow_forwarded_traffic = true
}

resource "azurerm_virtual_network_peering" "env-to-local" {
    name = "local-to-${azurerm_virtual_network.i.name}"
    resource_group_name = var.common.resource_group.name
    virtual_network_name = var.common.peer.vnet_name
    remote_virtual_network_id = azurerm_virtual_network.i.id
    allow_virtual_network_access = true
    allow_forwarded_traffic = true
}

resource "azurerm_virtual_network_peering" "local-to-firewall" {
    name = "local-to-firewall"
    resource_group_name = var.common.resource_group.name
    virtual_network_name = azurerm_virtual_network.i.name
    remote_virtual_network_id = var.firewall.config.virtual_network.id
    allow_virtual_network_access = true
    allow_forwarded_traffic = true
}

resource "azurerm_virtual_network_peering" "firewall-to-local" {
    provider = azurerm.core
    name = "local-to-${azurerm_virtual_network.i.name}"
    resource_group_name = var.firewall.config.resource_group.name
    virtual_network_name = var.firewall.config.virtual_network.name
    remote_virtual_network_id = azurerm_virtual_network.i.id
    allow_virtual_network_access = true
    allow_forwarded_traffic = true
}

resource "azurerm_private_dns_zone_virtual_network_link" "pgfs" {
    name = "private.postgres.database.azure.com-to-${azurerm_virtual_network.i.name}"
    private_dns_zone_name = var.common.dns.postgres.name
    virtual_network_id = azurerm_virtual_network.i.id
    resource_group_name = var.common.resource_group.name
}

resource "azurerm_private_dns_zone_virtual_network_link" "primary" {
    provider = azurerm.core
    name = azurerm_virtual_network.i.name
    resource_group_name = var.common.dns.private.resource_group
    private_dns_zone_name = var.common.dns.private.primary_zone
    virtual_network_id = azurerm_virtual_network.i.id
    registration_enabled = true
}

resource "azurerm_private_dns_zone_virtual_network_link" "secondary" {
    provider = azurerm.core
    for_each = toset(var.common.dns.private.secondary_zones)
    name = azurerm_virtual_network.i.name
    resource_group_name = var.common.dns.private.resource_group
    private_dns_zone_name = each.key
    virtual_network_id = azurerm_virtual_network.i.id
}

resource "azurerm_dns_a_record" "wildcard" {
    provider = azurerm.core
    count = var.firewall.ingress != null ? 1 : 0

    name = "*.${var.cluster.name}.${var.common.resource_group.location}"
    zone_name = var.common.dns.public.name
    resource_group_name = var.common.dns.public.resource_group
    ttl = 3600
    records = [var.firewall.ingress.public_ip]
}

resource "azurerm_user_assigned_identity" "i" {
    name = local.full_name
    resource_group_name = var.common.resource_group.name
    location = var.common.resource_group.location
}

resource "azurerm_role_assignment" "i" {
    scope = var.common.resource_group.id
    role_definition_name = "Contributor"
    principal_id = azurerm_user_assigned_identity.i.principal_id
}

resource "azurerm_user_assigned_identity" "kubelet" {
    name = "${local.full_name}-kubelet"
    resource_group_name = var.common.resource_group.name
    location = var.common.resource_group.location
}

resource "azurerm_role_assignment" "kubelet_acr" {
    for_each = var.common.registries
    scope = each.value
    role_definition_name = "AcrPull"
    principal_id = azurerm_user_assigned_identity.kubelet.principal_id
}

resource "azurerm_kubernetes_cluster" "i" {
    name = local.full_name
    resource_group_name = var.common.resource_group.name
    location = var.common.resource_group.location
    automatic_channel_upgrade = var.cluster.updates
    node_resource_group = "${local.full_name}-nodes"
    dns_prefix = local.full_name
    sku_tier = var.cluster.sku
    azure_policy_enabled = false

    default_node_pool {
        name = "default"
        enable_auto_scaling = false
        node_count = var.cluster.node_count
        vm_size = var.cluster.node_size
        zones = var.cluster.zones
        os_disk_type = var.cluster.os_disk_type
        vnet_subnet_id = one(azurerm_virtual_network.i.subnet[*].id)
        max_pods = 100
    }

    dynamic api_server_access_profile {
        # Workaround described in:
        # https://github.com/hashicorp/terraform-provider-azurerm/issues/20037#issuecomment-1384846081
        # If a proper fix has been applied, we can refactor this
        for_each = toset(length(var.cluster.api_ip_ranges) != 0 ? ["dummy"] : [])
        content {
            authorized_ip_ranges = var.cluster.api_ip_ranges
        }
    }

    network_profile {
        network_plugin = "azure"
        service_cidr = "172.16.0.0/16"
        dns_service_ip = "172.16.0.10"
        outbound_type = "userDefinedRouting"
        load_balancer_sku = "standard"
    }

    identity {
        type = "UserAssigned"
        identity_ids = [ azurerm_user_assigned_identity.i.id ]
    }

    kubelet_identity {
        client_id = azurerm_user_assigned_identity.kubelet.client_id
        object_id = azurerm_user_assigned_identity.kubelet.principal_id
        user_assigned_identity_id = azurerm_user_assigned_identity.kubelet.id
    }

    linux_profile {
        admin_username = "terraform"
        ssh_key {
            key_data = file("~/.ssh/id_bink_azure_terraform.pub")
        }
    }

    azure_active_directory_role_based_access_control {
        managed = true
        azure_rbac_enabled = true
        admin_group_object_ids = var.common.aad_admin_group_object_ids
    }

    maintenance_window {
        allowed {
            day = var.cluster.maintenance_day
            hours = [0, 1, 2, 3, 4, 5, 6]
        }
    }
}

resource "azurerm_monitor_diagnostic_setting" "i" {
    name = "loganalytics"
    target_resource_id = azurerm_kubernetes_cluster.i.id
    log_analytics_workspace_id = var.common.loganalytics_id

    enabled_log { category = "kube-apiserver" }
    enabled_log { category = "kube-controller-manager" }
    enabled_log { category = "kube-scheduler" }
    metric {
        category = "AllMetrics"
        enabled = false
    }
}

data azurerm_resource_group "node" {
    name = azurerm_kubernetes_cluster.i.node_resource_group
}

# Required for AAD Pod Identity
resource "azurerm_role_assignment" "kubelet_node_vmss_contributor" {
    scope = data.azurerm_resource_group.node.id
    role_definition_name = "Virtual Machine Contributor"
    principal_id = azurerm_user_assigned_identity.kubelet.principal_id
    lifecycle {
        ignore_changes = [ scope ] # terraform incorrectly thinks this changes between runs
    }
}

# Required for AAD Pod Identity
resource "azurerm_role_assignment" "kubelet_node_identity_operator_env_rg" {
    scope = var.common.resource_group.id
    role_definition_name = "Managed Identity Operator"
    principal_id = azurerm_user_assigned_identity.kubelet.principal_id
}

# Required for AAD Pod Identity
resource "azurerm_role_assignment" "kubelet_node_identity_operator_node_rg" {
    scope = data.azurerm_resource_group.node.id
    role_definition_name = "Managed Identity Operator"
    principal_id = azurerm_user_assigned_identity.kubelet.principal_id
    lifecycle {
        ignore_changes = [ scope ] # terraform incorrectly thinks this changes between runs
    } 
}

resource "azurerm_role_assignment" "rbac_users" {
    for_each = var.cluster.iam

    scope = azurerm_kubernetes_cluster.i.id
    role_definition_name = "Azure Kubernetes Service Cluster User Role"
    principal_id = each.value["object_id"]
}

resource "azurerm_role_assignment" "iam" {
    for_each = var.cluster.iam

    scope = azurerm_kubernetes_cluster.i.id
    role_definition_name = each.value["role"]
    principal_id = each.value["object_id"]
}

resource "azurerm_firewall_network_rule_collection" "i" {
    provider = azurerm.core

    name = "aks_api_server-${local.full_name}"
    azure_firewall_name = var.firewall.config.firewall.name
    resource_group_name = var.firewall.config.resource_group.name
    priority = var.firewall.rule_priority
    action = "Allow"
    rule {
        name = "443/tcp"
        source_addresses = [var.cluster.cidr]
        destination_ports = ["443"]
        protocols = ["TCP"]
        destination_fqdns = [
            trimprefix(trimsuffix(azurerm_kubernetes_cluster.i.kube_config.0.host, ":443"), "https://")
        ]
    }
    rule {
        name = "1194/udp"
        source_addresses = [var.cluster.cidr]
        destination_ports = ["1194"]
        protocols = ["UDP"]
        destination_fqdns = [
            trimprefix(trimsuffix(azurerm_kubernetes_cluster.i.kube_config.0.host, ":443"), "https://")
        ]
    }
    rule {
        name = "9000/tcp"
        source_addresses = [var.cluster.cidr]
        destination_ports = ["9000"]
        protocols = ["TCP"]
        destination_fqdns = [
            trimprefix(trimsuffix(azurerm_kubernetes_cluster.i.kube_config.0.host, ":443"), "https://")
        ]
    }
}

resource "azurerm_firewall_nat_rule_collection" "i" {
    provider = azurerm.core
    count = var.firewall.ingress != null ? 1 : 0

    name = "ingress-${local.full_name}"
    azure_firewall_name = var.firewall.config.firewall.name
    resource_group_name = var.firewall.config.resource_group.name
    priority = var.firewall.rule_priority
    action = "Dnat"

    rule {
        name = "http"
        source_ip_groups = var.firewall.ingress.source_ip_groups
        source_addresses = var.firewall.ingress.source_addr
        destination_ports = [var.firewall.ingress.http_port]
        destination_addresses = [var.firewall.ingress.public_ip]
        translated_address = cidrhost(var.cluster.cidr, 65534)
        translated_port = "80"
        protocols = ["TCP"]
    }
    rule {
        name = "https"
        source_ip_groups = var.firewall.ingress.source_ip_groups
        source_addresses = var.firewall.ingress.source_addr
        destination_ports = [var.firewall.ingress.https_port]
        destination_addresses = [var.firewall.ingress.public_ip]
        translated_address = cidrhost(var.cluster.cidr, 65534)
        translated_port = "443"
        protocols = ["TCP"]
    }
}

resource "null_resource" "flux_install" {
    provisioner "local-exec" {
        command = <<-EOF
        export FLUX_DIR="${var.common.resource_group.location}-${trim(var.cluster.name, "0123456789")}"
        export LOCATION="${var.common.resource_group.location}"
        export CLUSTER_NAME="${var.cluster.name}"
        export KUBE_API_HOST="${azurerm_kubernetes_cluster.i.kube_admin_config.0.host}"
        export LOADBALANCER_IP="${cidrhost(var.cluster.cidr, 65534)}"
        export PRIVATELINK_IP="${cidrhost(var.cluster.cidr, 65533)}"

        envsubst < ${path.module}/flux/gotk-sync.yaml > /tmp/${local.full_name}.yaml

        until az aks command invoke \
            --subscription "${data.azurerm_subscription.i.subscription_id}" \
            --resource-group ${var.common.resource_group.name} \
            --name ${local.full_name} \
            --command "kubectl get namespaces -o name" | grep flux-system
        do
            echo "Attempting to install Flux"
            az aks command invoke \
                --subscription "${data.azurerm_subscription.i.subscription_id}" \
                --resource-group ${var.common.resource_group.name} \
                --name ${local.full_name} \
                --command "kubectl apply -f gotk-components.yaml" \
                --file ${path.module}/flux/gotk-components.yaml
            sleep 10
        done

        until az aks command invoke \
            --subscription "${data.azurerm_subscription.i.subscription_id}" \
            --resource-group ${var.common.resource_group.name} \
            --name ${local.full_name} \
            --command "kubectl get gitrepository -n flux-system -o name" | grep flux-system
        do
            echo "Attempting to install Flux Sync"
            az aks command invoke \
                --subscription "${data.azurerm_subscription.i.subscription_id}" \
                --resource-group ${var.common.resource_group.name} \
                --name ${local.full_name} \
                --command "kubectl apply -f ${local.full_name}.yaml" \
                --file /tmp/${local.full_name}.yaml
            sleep 10
        done

        EOF
        interpreter = ["/bin/zsh", "-c"]
    }
    depends_on = [
      azurerm_kubernetes_cluster.i,
      azurerm_firewall_network_rule_collection.i,
    ]
}

output "flux_config" {
    value = {
        kube_admin_config = azurerm_kubernetes_cluster.i.kube_admin_config.0
        variables = {
            cluster_name = var.cluster.name
            location = var.common.resource_group.location
            loadbalancer_ip = cidrhost(var.cluster.cidr, 65534)
        }
    }
}

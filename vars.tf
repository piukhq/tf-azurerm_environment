variable resource_group_name { type = string }
variable location { type = string }
variable tags { type = map }

variable loganalytics_id { type = string }

variable "vnet_cidr" { type = string }

variable resource_group_iam {
    type = map(object({ object_id = string, role = string }))
    default = {}
}

variable keyvault_iam {
    type = map(object({ object_id = string, role = string }))
    default = {}
}
variable postgres_iam {
    type = map(object({ object_id = string, role = string }))
    default = {}
}
variable redis_iam {
    type = map(object({ object_id = string, role = string }))
    default = {}
}
variable storage_iam {
    type = map(object({ object_id = string, role = string, storage_id = string }))
    default = {}
}

variable keyvault_users {
    type = map(string)
    default = {}
}

variable infra_keyvault_users {
    type = map(object({ object_id = string, permissions = list(string) }))
    default = {}
}

variable additional_keyvaults {
    type = list(string)
    default = []
}

variable managed_identities {
    type = map(object({ kv_access = string }))
    default = {}
}

variable managed_identities_loganalytics {
    type = map(object({
        role = string
    }))
    default = {}
}

variable eventhubs {
    type = map(object({
        name = string
        sku = string
        capacity = number
        eventhubs = map(object({
            partition_count = number
            message_retention = number
        }))
    }))
    default = {}
}


variable postgres_config {
    type = map(object({
        name = string
        databases = list(string)
        sku_name = string
        storage_gb = number
        public_access = bool
    }))
    default = {}
}

variable postgres_flexible_config {
    type = map(object({
        name = string
        version = string
        sku_name = string
        storage_mb = number
        databases = list(string)
        high_availability = bool
    }))
    default = {}
}

variable redis_config {
    type = map
    default = {}
}

variable redis_enterprise_config {
    type = map(object({
        name = string
    }))
    default = {}
}

# start_hour is 0 - 23 based
variable redis_patch_schedule {
    type = object({
        day_of_week = string
        start_hour_utc = number
    })
    default = {
        day_of_week = "Monday"
        start_hour_utc = 3
    }
}

variable storage_config {
    type = map(object({
        name = string
        account_replication_type = string
        account_tier = string
    }))
    default = {}
}

variable storage_management_policy_config {
    type = map(list(object({
        name = string
        enabled = bool
        prefix_match = list(string)
        delete_after_days = number
    })))
    default = {}
}

variable "bink_sh_zone_id" {
    type = string
}

variable "bink_host_zone_id" {
    type = string
}

variable aks {
    type = map(object({
        name = string
        cidr = string
        api_ip_ranges = optional(list(string))
        updates = string
        sku = optional(string)
        node_count = optional(number)
        node_size = optional(string)
        maintenance_day = string
        zones = optional(list(string))
        os_disk_type = optional(string)
        aad_admin_group_object_ids = optional(list(string), [ "0140ccf4-f68c-4daa-b531-97e5292ec364" ])
        iam = map(object({
            object_id = string
            role = string
        }))
        dns = object({
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
        firewall = object({
            rule_priority = number
            ingress = optional(object({
                source_ip_groups = optional(list(string))
                source_addr = optional(list(string))
                public_ip = string
                http_port = number
                https_port = number
            }), null)
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
    }))
    default = {}
}

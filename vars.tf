variable resource_group_name { type = string }
variable location { type = string }
variable tags { type = map }
variable eventhub_authid { type = string }

variable resource_group_iam {
    type = map
    default = {}
}

variable keyvault_users {
    type = map(object({ object_id = string }))
    default = {}
}
variable postgres_config {
    type = map(object({
        name = string
        databases = list(string)
        sku_name = string
        storage_gb = number
    }))
    default = {}
}
variable redis_config {
    type = map
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
    type = map
    default = {}
}

variable service_bus {
    type = object({
        sku = string
        capacity = number
        zone_redundant = bool
    })
    default = {  # https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/servicebus_namespace
        sku = "Standard"
        capacity = 0
        zone_redundant = false
    }
}

variable additional_managed_identities {
    type = map(object({
        keyvault_permissions = list(string)
    }))
    default = {}
}

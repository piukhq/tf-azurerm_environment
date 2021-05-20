variable resource_group_name { type = string }
variable location { type = string }
variable tags { type = map }
variable eventhub_authid { type = string }

variable resource_group_iam {
    type = map
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

variable secret_namespaces {
    type = string
    default = "default,monitoring"
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
    type = map
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

variable additional_managed_identities {
    type = map(object({
        keyvault_permissions = list(string)
    }))
    default = {}
}

variable "cert_manager_zone_id" {
    type = string
}

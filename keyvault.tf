data "azurerm_client_config" "current" {}

resource "azurerm_key_vault" "infra" {
    name = "bink-${azurerm_resource_group.rg.name}-inf"
    location = azurerm_resource_group.rg.location
    resource_group_name = azurerm_resource_group.rg.name
    tags = var.tags

    sku_name = "standard"
    # All don't need much accidental delete protection as TF populates this KV
    enabled_for_disk_encryption = false
    tenant_id = data.azurerm_client_config.current.tenant_id
    purge_protection_enabled = false
}

resource "azurerm_monitor_diagnostic_setting" "infra_keyvault" {
    name = "logs"
    target_resource_id = azurerm_key_vault.infra.id
    eventhub_name = "azurekeyvault"
    eventhub_authorization_rule_id = var.eventhub_authid

    log {
        category = "AuditEvent"
        enabled = true
        retention_policy {
            days = 0
            enabled = false
        }
    }

    metric {
        category = "AllMetrics"
        enabled = false
        retention_policy {
            days = 0
            enabled = false
        }
    }
}

resource "azurerm_key_vault_access_policy" "infra_terraform" {
    key_vault_id = azurerm_key_vault.infra.id

    tenant_id = data.azurerm_client_config.current.tenant_id
    object_id = "4869640a-3727-4496-a8eb-f7fae0872410"

    secret_permissions = [
        "backup",
        "delete",
        "get",
        "list",
        "purge",
        "recover",
        "restore",
        "set",
    ]
}

# Need to do access policies separately if your going to add additional after
resource "azurerm_key_vault_access_policy" "infra_devops" {
    key_vault_id = azurerm_key_vault.infra.id

    tenant_id = data.azurerm_client_config.current.tenant_id
    object_id = "aac28b59-8ac3-4443-bccc-3fb820165a08"

    secret_permissions = [
        "backup",
        "delete",
        "get",
        "list",
        "purge",
        "recover",
        "restore",
        "set",
    ]
}

resource "azurerm_key_vault_access_policy" "infra_additional" {
    for_each = var.infra_keyvault_users

    key_vault_id = azurerm_key_vault.infra.id

    tenant_id = data.azurerm_client_config.current.tenant_id
    object_id = each.value["object_id"]

    secret_permissions = each.value["permissions"]
}

# Used to sync KeyVault postgres/redis/... to the cluster secrets
resource "azurerm_user_assigned_identity" "infra_sync" {
    resource_group_name = azurerm_resource_group.rg.name
    location = azurerm_resource_group.rg.location

    name = "bink-${azurerm_resource_group.rg.name}-infra-sync"
}

# TODO export resource and client id
resource "azurerm_key_vault_access_policy" "infra_sync" {
    key_vault_id = azurerm_key_vault.infra.id

    tenant_id = data.azurerm_client_config.current.tenant_id
    object_id = azurerm_user_assigned_identity.infra_sync.principal_id

    secret_permissions = [
        "get",
        "list"
    ]
}

resource "azurerm_key_vault" "common" {
    name = "bink-${azurerm_resource_group.rg.name}-com"
    location = azurerm_resource_group.rg.location
    resource_group_name = azurerm_resource_group.rg.name
    tags = var.tags

    sku_name = "standard"
    enabled_for_disk_encryption = false
    tenant_id = data.azurerm_client_config.current.tenant_id
    purge_protection_enabled = false
}

resource "azurerm_monitor_diagnostic_setting" "common_keyvault" {
    name = "logs"
    target_resource_id = azurerm_key_vault.common.id
    eventhub_name = "azurekeyvault"
    eventhub_authorization_rule_id = var.eventhub_authid

    log {
        category = "AuditEvent"
        enabled = true
        retention_policy {
            days = 0
            enabled = false
        }
    }

    metric {
        category = "AllMetrics"
        enabled = false
        retention_policy {
            days = 0
            enabled = false
        }
    }
}

resource "azurerm_user_assigned_identity" "fakicorp" {
    resource_group_name = azurerm_resource_group.rg.name
    location = azurerm_resource_group.rg.location

    name = "bink-${azurerm_resource_group.rg.name}-fakicorp"
}

# TODO export resource and client id
resource "azurerm_key_vault_access_policy" "fakicorp" {
    key_vault_id = azurerm_key_vault.common.id

    tenant_id = data.azurerm_client_config.current.tenant_id
    object_id = azurerm_user_assigned_identity.fakicorp.principal_id

    secret_permissions = [
        "get",
        "list",
        "set",
        "delete"
    ]
}

resource "azurerm_user_assigned_identity" "europa" {
    resource_group_name = azurerm_resource_group.rg.name
    location = azurerm_resource_group.rg.location

    name = "bink-${azurerm_resource_group.rg.name}-europa"
}

resource "azurerm_key_vault_access_policy" "europa" {
    key_vault_id = azurerm_key_vault.common.id

    tenant_id = data.azurerm_client_config.current.tenant_id
    object_id = azurerm_user_assigned_identity.europa.principal_id

    secret_permissions = [
        "get",
        "list",
        "set",
        "delete"
    ]
}

resource "azurerm_user_assigned_identity" "harmonia" {
    resource_group_name = azurerm_resource_group.rg.name
    location = azurerm_resource_group.rg.location

    name = "bink-${azurerm_resource_group.rg.name}-harmonia"
}

resource "azurerm_key_vault_access_policy" "harmonia" {
    key_vault_id = azurerm_key_vault.common.id

    tenant_id = data.azurerm_client_config.current.tenant_id
    object_id = azurerm_user_assigned_identity.harmonia.principal_id

    secret_permissions = [
        "get",
        "list",
    ]
}

resource "azurerm_user_assigned_identity" "hermes" {
    resource_group_name = azurerm_resource_group.rg.name
    location = azurerm_resource_group.rg.location

    name = "bink-${azurerm_resource_group.rg.name}-hermes"
}

resource "azurerm_key_vault_access_policy" "hermes" {
    key_vault_id = azurerm_key_vault.common.id

    tenant_id = data.azurerm_client_config.current.tenant_id
    object_id = azurerm_user_assigned_identity.hermes.principal_id

    secret_permissions = [
        "get",
        "list",
    ]
}

resource "azurerm_user_assigned_identity" "polaris" {
    resource_group_name = azurerm_resource_group.rg.name
    location = azurerm_resource_group.rg.location

    name = "bink-${azurerm_resource_group.rg.name}-polaris"
}

resource "azurerm_key_vault_access_policy" "polaris" {
    key_vault_id = azurerm_key_vault.common.id

    tenant_id = data.azurerm_client_config.current.tenant_id
    object_id = azurerm_user_assigned_identity.polaris.principal_id

    secret_permissions = [
        "get",
        "list",
    ]
}

resource "azurerm_user_assigned_identity" "event-horizon" {
    resource_group_name = azurerm_resource_group.rg.name
    location = azurerm_resource_group.rg.location

    name = "bink-${azurerm_resource_group.rg.name}-event-horizon"
}

resource "azurerm_key_vault_access_policy" "event-horizon" {
    key_vault_id = azurerm_key_vault.common.id

    tenant_id = data.azurerm_client_config.current.tenant_id
    object_id = azurerm_user_assigned_identity.event-horizon.principal_id

    secret_permissions = [
        "get",
        "list",
    ]
}

resource "azurerm_user_assigned_identity" "metis" {
    resource_group_name = azurerm_resource_group.rg.name
    location = azurerm_resource_group.rg.location

    name = "bink-${azurerm_resource_group.rg.name}-metis"
}

resource "azurerm_key_vault_access_policy" "metis" {
    key_vault_id = azurerm_key_vault.common.id

    tenant_id = data.azurerm_client_config.current.tenant_id
    object_id = azurerm_user_assigned_identity.metis.principal_id

    secret_permissions = [
        "get",
        "list",
    ]
}

resource "azurerm_user_assigned_identity" "pyqa" {
    resource_group_name = azurerm_resource_group.rg.name
    location = azurerm_resource_group.rg.location

    name = "bink-${azurerm_resource_group.rg.name}-pyqa"
}

resource "azurerm_key_vault_access_policy" "pyqa" {
    key_vault_id = azurerm_key_vault.common.id

    tenant_id = data.azurerm_client_config.current.tenant_id
    object_id = azurerm_user_assigned_identity.pyqa.principal_id

    secret_permissions = [
        "get",
        "list",
    ]
}

resource "azurerm_user_assigned_identity" "zephyrus" {
    resource_group_name = azurerm_resource_group.rg.name
    location = azurerm_resource_group.rg.location

    name = "bink-${azurerm_resource_group.rg.name}-zephyrus"
}

resource "azurerm_key_vault_access_policy" "zephyrus" {
    key_vault_id = azurerm_key_vault.common.id

    tenant_id = data.azurerm_client_config.current.tenant_id
    object_id = azurerm_user_assigned_identity.zephyrus.principal_id

    secret_permissions = [
        "get",
        "list",
    ]
}

resource "azurerm_key_vault_access_policy" "common_devops" {
    key_vault_id = azurerm_key_vault.common.id

    tenant_id = data.azurerm_client_config.current.tenant_id
    object_id = "aac28b59-8ac3-4443-bccc-3fb820165a08"

    secret_permissions = [
        "backup",
        "delete",
        "get",
        "list",
        "purge",
        "recover",
        "restore",
        "set",
    ]
}

resource "azurerm_key_vault_access_policy" "common_terraform" {
    key_vault_id = azurerm_key_vault.common.id

    tenant_id = data.azurerm_client_config.current.tenant_id
    object_id = "4869640a-3727-4496-a8eb-f7fae0872410"

    secret_permissions = [
        "backup",
        "delete",
        "get",
        "list",
        "purge",
        "recover",
        "restore",
        "set",
    ]
}

resource "azurerm_key_vault_access_policy" "common_users" {
    for_each = var.keyvault_users

    key_vault_id = azurerm_key_vault.common.id

    tenant_id = data.azurerm_client_config.current.tenant_id
    object_id = each.value["object_id"]

    secret_permissions = [
        "backup",
        "delete",
        "get",
        "list",
        "set"
    ]
}

resource "azurerm_user_assigned_identity" "additional" {
    for_each = var.additional_managed_identities

    resource_group_name = azurerm_resource_group.rg.name
    location = azurerm_resource_group.rg.location

    # Additional is a horrible name to add but it prevents clashes
    # which cause bad things
    name = "bink-${azurerm_resource_group.rg.name}-additional-${each.key}"
}

resource "azurerm_key_vault_access_policy" "additional" {
    for_each = var.additional_managed_identities

    key_vault_id = azurerm_key_vault.common.id

    tenant_id = data.azurerm_client_config.current.tenant_id
    object_id = azurerm_user_assigned_identity.additional[each.key].principal_id

    secret_permissions = each.value["keyvault_permissions"]
}

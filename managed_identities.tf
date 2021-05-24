# Have to write the below in an ugly way to avoid recreating
# identities in existing environments.
# Terry tells me he'll make this pretty in future.
# [2021/05/20 15:38] Chris Pressland
#    I just wana avoid statefile hackery where possible
# ​[2021/05/20 15:38] Terry Cain
#    am happy to do the statefile fuckery

locals {
    kv_admin_ids = {
        devops = "aac28b59-8ac3-4443-bccc-3fb820165a08",
        terraform = "4869640a-3727-4496-a8eb-f7fae0872410"
    }
    kv_rw_ids = merge(var.keyvault_users, {
        fakicorp = azurerm_user_assigned_identity.fakicorp.principal_id,
        europa = azurerm_user_assigned_identity.europa.principal_id
    })
    kv_ro_ids = {
        harmonia = azurerm_user_assigned_identity.harmonia.principal_id,
        hermes = azurerm_user_assigned_identity.hermes.principal_id,
        polaris = azurerm_user_assigned_identity.polaris.principal_id,
        event-horizon = azurerm_user_assigned_identity.event-horizon.principal_id,
        metis = azurerm_user_assigned_identity.metis.principal_id,
        midas = azurerm_user_assigned_identity.midas.principal_id,
        azuregcpvaultsync = azurerm_user_assigned_identity.azuregcpvaultsync.principal_id,
        pyqa = azurerm_user_assigned_identity.pyqa.principal_id,
        vela = azurerm_user_assigned_identity.vela.principal_id,
        zephyrus = azurerm_user_assigned_identity.zephyrus.principal_id
    }
}

resource "azurerm_user_assigned_identity" "fakicorp" {
    resource_group_name = azurerm_resource_group.rg.name
    location = azurerm_resource_group.rg.location

    name = "bink-${azurerm_resource_group.rg.name}-fakicorp"
}

resource "azurerm_user_assigned_identity" "europa" {
    resource_group_name = azurerm_resource_group.rg.name
    location = azurerm_resource_group.rg.location

    name = "bink-${azurerm_resource_group.rg.name}-europa"
}

resource "azurerm_user_assigned_identity" "azuregcpvaultsync" {
    resource_group_name = azurerm_resource_group.rg.name
    location = azurerm_resource_group.rg.location

    name = "bink-${azurerm_resource_group.rg.name}-azuregcpvaultsync"
}

resource "azurerm_user_assigned_identity" "harmonia" {
    resource_group_name = azurerm_resource_group.rg.name
    location = azurerm_resource_group.rg.location

    name = "bink-${azurerm_resource_group.rg.name}-harmonia"
}

resource "azurerm_user_assigned_identity" "hermes" {
    resource_group_name = azurerm_resource_group.rg.name
    location = azurerm_resource_group.rg.location

    name = "bink-${azurerm_resource_group.rg.name}-hermes"
}

resource "azurerm_user_assigned_identity" "polaris" {
    resource_group_name = azurerm_resource_group.rg.name
    location = azurerm_resource_group.rg.location

    name = "bink-${azurerm_resource_group.rg.name}-polaris"
}

resource "azurerm_user_assigned_identity" "event-horizon" {
    resource_group_name = azurerm_resource_group.rg.name
    location = azurerm_resource_group.rg.location

    name = "bink-${azurerm_resource_group.rg.name}-event-horizon"
}

resource "azurerm_user_assigned_identity" "metis" {
    resource_group_name = azurerm_resource_group.rg.name
    location = azurerm_resource_group.rg.location

    name = "bink-${azurerm_resource_group.rg.name}-metis"
}

resource "azurerm_user_assigned_identity" "midas" {
    resource_group_name = azurerm_resource_group.rg.name
    location = azurerm_resource_group.rg.location

    name = "bink-${azurerm_resource_group.rg.name}-midas"
}

resource "azurerm_user_assigned_identity" "pyqa" {
    resource_group_name = azurerm_resource_group.rg.name
    location = azurerm_resource_group.rg.location

    name = "bink-${azurerm_resource_group.rg.name}-pyqa"
}

resource "azurerm_user_assigned_identity" "vela" {
    resource_group_name = azurerm_resource_group.rg.name
    location = azurerm_resource_group.rg.location

    name = "bink-${azurerm_resource_group.rg.name}-vela"
}


resource "azurerm_user_assigned_identity" "zephyrus" {
    resource_group_name = azurerm_resource_group.rg.name
    location = azurerm_resource_group.rg.location

    name = "bink-${azurerm_resource_group.rg.name}-zephyrus"
}

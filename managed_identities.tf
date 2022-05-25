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
}

resource "azurerm_user_assigned_identity" "app" {
    for_each = var.managed_identities

    resource_group_name = azurerm_resource_group.rg.name
    location = azurerm_resource_group.rg.location

    name = "bink-${azurerm_resource_group.rg.name}-${each.key}"
}

resource "azurerm_user_assigned_identity" "loganalytics" {
    for_each = var.managed_identities_loganalytics

    resource_group_name = azurerm_resource_group.rg.name
    location = azurerm_resource_group.rg.location

    name = "bink-${azurerm_resource_group.rg.name}-${each.key}"
}

resource "azurerm_role_assignment" "loganalytics" {
    for_each = var.managed_identities_loganalytics
    scope = var.loganalytics_id
    role_definition_name = each.value.role
    principal_id = azurerm_user_assigned_identity.loganalytics[each.key].principal_id
}

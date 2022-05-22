terraform {
    required_providers {
        azurerm = {
            source  = "hashicorp/azurerm"
            version = ">= 3.7.0"
            configuration_aliases = [ azurerm.core ]
        }
    }
}

resource "azurerm_resource_group" "rg" {
    name = var.resource_group_name
    location = var.location
    tags = var.tags
}

resource "azurerm_role_assignment" "iam" {
    for_each = var.resource_group_iam

    scope = azurerm_resource_group.rg.id
    role_definition_name = each.value["role"]
    principal_id = each.value["object_id"]
}

resource "azurerm_role_assignment" "kube_resource_group_access" {
    scope = azurerm_resource_group.rg.id
    role_definition_name = "Managed Identity Operator"
    principal_id = "ed09bbbc-7b4d-4f2e-a657-3f0c7b3335c7"
}

output "managedidentites" {
    value = {
        infra_sync = {
            client_id = azurerm_user_assigned_identity.infra_sync.client_id
            resource_id = azurerm_user_assigned_identity.infra_sync.id
            keyvault_url = azurerm_key_vault.infra.vault_uri
        }
        fakicorp = {
            client_id = azurerm_user_assigned_identity.fakicorp.client_id
            resource_id = azurerm_user_assigned_identity.fakicorp.id
            keyvault_url = azurerm_key_vault.common.vault_uri
        }
    }
}

output "postgres_servers" {
    value = { for server in azurerm_postgresql_server.pg : server.name => azurerm_resource_group.rg.name }
}

output "storage_accounts" {
    value = { for account in azurerm_storage_account.storage : account.name => account.primary_blob_connection_string }
}

output "controller_availability_set_id" {
    value = azurerm_availability_set.controller.id
}

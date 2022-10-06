# TODO: can probably remove this, dont think this output is used
output "managedidentites" {
    value = {
        infra_sync = {
            client_id = azurerm_user_assigned_identity.infra_sync.client_id
            resource_id = azurerm_user_assigned_identity.infra_sync.id
            keyvault_url = azurerm_key_vault.infra.vault_uri
        }
    }
}

output "storage_accounts" {
    value = { for account in azurerm_storage_account.storage : account.name => account.primary_blob_connection_string }
}

output "peering" {
    value = {
        vnet_id = azurerm_virtual_network.vnet.id
        vnet_name = azurerm_virtual_network.vnet.name
        resource_group_name = azurerm_resource_group.rg.name
    }
}

output "postgres_flexible_server_dns_link" {
    value = {
        name = azurerm_private_dns_zone.pgfs.name
        resource_group_name = azurerm_resource_group.rg.name
    }
}

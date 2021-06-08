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

output "postgres_servers" {
    value = { for server in azurerm_postgresql_server.pg : server.name => azurerm_resource_group.rg.name }
}

output "storage_accounts" {
    value = { for account in azurerm_storage_account.storage : account.name => account.primary_blob_connection_string }
}

output "private_links" {
    value = flatten([
        [for server in keys(var.postgres_config) : {
            private_zone = "privatelink.postgres.database.azure.com"
            name = "pg-${server}"
            resource_id = azurerm_postgresql_server.pg[server].id
            subresource_names = ["postgresqlServer"]
        }],
        [for server in keys(var.redis_enterprise_config) : {
            private_zone = "privatelink.redisenterprise.cache.azure.net"
            name = "redis-${server}"
            resource_id = azurerm_redis_enterprise_cluster.redis_enterprise[server].id
            subresource_names = ["redisEnterprise"]
        }],
        # [  # Dont need KeyVault endpoints atm, example of non-dynamic endpoint entry
        #     {
        #         private_zone = "privatelink.vaultcore.azure.net"
        #         name = "kv-infra"
        #         resource_id = azurerm_key_vault.infra.id,
        #         subresource_names = ["vault"]
        #     },
        #     {
        #         private_zone = "privatelink.vaultcore.azure.net"
        #         name = "kv-common"
        #         resource_id = azurerm_key_vault.common.id,
        #         subresource_names = ["vault"]
        #     }
        # ]
    ])
}

# private endpoints
# type            | name                    | subresource                   | zone
# ================|=========================|===============================|======================================================================
# PG              | bink-uksouth-dev-common | postgresqlServer              | privatelink.postgres.database.azure.com
# Redis           | bink-uksouth-dev-common | redisCache                    | privatelink.redis.cache.windows.net
# RedisEnterprise | bink-uksouth-dev-common | redisEnterprise               | privatelink.redisenterprise.cache.azure.net
# ACR             | binkcore                | registry                      | privatelink.azurecr.io
# KeyVault        | bink-uksouth-dev-com    | vault                         | privatelink.vaultcore.azure.net
# StorageAccount  | binkuksouthdev          | blob/table/queue/file/web/dfs | privatelink.blob.core.windows.net/privatelink.dfs.core.windows.net...

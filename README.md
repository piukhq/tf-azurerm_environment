# Terraform azurerm_environment module

Creates pre-requisite supporting services for a Kubernetes environment. This module is responsible for creating the persistant datastores & paas services i.e Azure Postgres/KeyVault/Redis/ServiceBus. Where the azure managed services require authentication, credentials are stored in Azure KeyVault and the Kubernetes cluster will have access to the KeyVault via a managed service account.

## Module Inputs

`resource_group_name` - string - Name of the resource group that will contain the Azure resources relating to the environment

`location` - string - Azure location name

`tags` - map[string] -> string - Tags to assign to various Azure resources (if they support tags)

`resource_group_iam` - map[string] -> {"object_id": string, "role": string} - Map of arbitary group name against an Azure AD group/user ID and Azure IAM role.

`keyvault_users` - map[string] -> {"object_id": string} - List of user or group IDs that have write access to the environment's common keyvault.

`postgres_config` - map[string] -> {"name": string, "databases": [string, ...], "sku_name": string, "storage_gb": int} - Map of postgres server name -> postgres server info

`redis_config` - map[string] -> string - Redis name -> configuration TODO

`redis_patch_schedule` -> {"day_of_week": string, "start_hour_utc": int} - When the redis maintenance should be scheduled, `start_hour_utc` is between 0 - 23 inclusive.

`storage_config` -> map[string] -> string - Storage config TODO

`service_bus` -> {"sku": string, "capacity": int, "zone_redundant": bool} - Specifies the SKU and related info for the common service bus namespace.

## Module Outputs

`managedidentites` - map[string] -> {"client_id": string, "resource_id": string, "keyvault_url": string} - Exports managed identity information for use in Kubernetes manifests. Identities are exported for `infra_sync` and `fakicorp`

`postgres_servers` - map[string] -> string - Exports a map of Postgres server name and resource group

`storage_accounts` - map[string] -> string - Exports a map of storage account name and connection string

`output "controller_availability_set_id` - string - Exports the environment level availability set for Kubernetes controllers

# Example

Dev Environment Example

```hcl
module "uksouth_dev_environment" {
    source = "git::ssh://git@git.bink.com/Terraform/azurerm_environment.git?ref=1.2.1"
    providers = {
        azurerm = azurerm.uk_dev
    }
    resource_group_name = "uksouth-dev"
    location = "uksouth"
    tags = {
        "Environment" = "Dev",
    }

    resource_group_iam = {
        Backend = {
            object_id = "219194f6-b186-4146-9be7-34b731e19001",
            role = "Contributor",
        },
        QA = {
            object_id = "2e3dc1d0-e6b8-4ceb-b1ae-d7ce15e2150d",
            role = "Contributor",
        },
    }

    keyvault_users = {
        Backend = { object_id = "219194f6-b186-4146-9be7-34b731e19001" },
        QA = { object_id = "2e3dc1d0-e6b8-4ceb-b1ae-d7ce15e2150d" },
    }

    postgres_config = {
        common = {
            name = "bink-uksouth-dev-common",
            sku_name = "GP_Gen5_4",
            storage_gb = 500,
            databases = ["*"]
        },
    }
    redis_config = {
        common = {
            name = "bink-uksouth-dev-common",
        },
    }
    redis_patch_schedule = {
        day_of_week = "Monday"
        start_hour_utc = 1
    }
    storage_config = {
        common = {
            name = "binkuksouthdev",
            account_replication_type = "ZRS",
            account_tier = "Standard"
        },
    }
}
```

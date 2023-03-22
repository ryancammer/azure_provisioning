include {
  path = find_in_parent_folders("root.hcl")
}

dependency "azure_setup" {
  config_path = "../100_azure_setup"

  mock_outputs = {
    environment         = "prod"
    namespace           = "ns"
    resource_group_name = "rg"
  }
}

dependency "network" {
  config_path = "../200_network"

  mock_outputs = {
    subnet_private_id = "/subscriptions/00000000-00f0-0000-0000-000000000000/resourceGroups/rg-vdi-prod-westus2/providers/Microsoft.Network/virtualNetworks/vnet01/subnets/snet01"
  }
}

dependency "storage" {
  config_path = "../300_storage"

  mock_outputs = {
    deploy_agent_archive_url                        = "https://orgstorageprod.blob.core.windows.net/st-vdi-vdi-prod-westus2-01/deployagent.zip"
    duo_api_hostname_key_name                       = "vdi-prod-westus2-duo-api-hostname"
    duo_installer_bits_url                          = "https://orgstorageprod.blob.core.windows.net/st-vdi-vdi-prod-westus2-01/DuoWinLogon_MSIs_Policies_and_Documentation-4.2.0.zip"
    duo_integration_key_name                        = "vdi-prod-westus2-duo-integration-key"
    duo_secret_key_name                             = "vdi-prod-westus2-duo-secret"
    key_vault_id                                    = "/subscriptions/00000000-00f0-0000-0000-000000000000/resourceGroups/rg--vdi-prod-westus2/providers/Microsoft.KeyVault/vaults/kv-orgvdi-prod-wes"
    key_vault_name                                  = "kv-orgvdi-prod-wesalp"
    scripts_storage_container_id                    = "https://orgstorageprod.blob.core.windows.net/st-vdi-vdi-prod-westus2-scripts-01"
    scripts_storage_container_name                  = "st-vdi-vdi-prod-westus2-scripts-01"
    scripts_storage_container_resource_manager_id   = "/subscriptions/00000000-00f0-0000-0000-000000000000/resourceGroups/rg-vdi-prod-westus2/providers/Microsoft.Storage/storageAccounts/orgstorageprod/blobServices/default/containers/st-vdi-vdi-prod-westus2-01"
    storage_account_name                            = "orgstorageprod"
    storage_account_primary_access_key              = "i/aE43BUhLLvF/0000000000000000000000i000000c000000000000000000O0000000000002000000000=="
    vdi_config_storage_container_name                = "st-vdi-vdi-prod-westus2-wutang-01"
    vdi_config_storage_container_resource_manager_id = "/subscriptions/00000000-00f0-0000-0000-000000000000/resourceGroups/rg-vdi-prod-westus2/providers/Microsoft.Storage/storageAccounts/orgstorageprod/blobServices/default/containers/st-vdi-vdi-prod-westus2-wutang-01"
  }
}

dependency "host_pool" {
  config_path = "../400_host_pool"

  mock_outputs = {
    host_pool_name = "vdpool-vdi-prod-westus2-01"
    vdag_id        = "/subscriptions/00000000-00f0-0000-0000-000000000000/resourceGroups/rg-vdi-prod-westus2/providers/Microsoft.DesktopVirtualization/applicationGroups/vdag-vdi-pro-westus2-01"
  }
}

inputs = {
  deploy_agent_archive_url                      = dependency.storage.outputs.deploy_agent_archive_url
  duo_api_hostname_key_name                     = dependency.storage.outputs.duo_api_hostname_key_name
  duo_installer_bits_url                        = dependency.storage.outputs.duo_installer_bits_url
  duo_integration_key_name                      = dependency.storage.outputs.duo_integration_key_name
  duo_secret_key_name                           = dependency.storage.outputs.duo_secret_key_name
  environment                                   = dependency.azure_setup.outputs.environment
  host_pool_name                                = dependency.host_pool.outputs.host_pool_name
  key_vault_id                                  = dependency.storage.outputs.key_vault_id
  key_vault_name                                = dependency.storage.outputs.key_vault_name
  namespace                                     = dependency.azure_setup.outputs.namespace
  resource_group_name                           = dependency.azure_setup.outputs.resource_group_name
  scripts_storage_container_id                  = dependency.storage.outputs.scripts_storage_container_id
  scripts_storage_container_name                = dependency.storage.outputs.scripts_storage_container_name
  scripts_storage_container_resource_manager_id = dependency.storage.outputs.scripts_storage_container_resource_manager_id
  storage_account_name                          = dependency.storage.outputs.storage_account_name
  storage_account_primary_access_key            = dependency.storage.outputs.storage_account_primary_access_key
  subnet_private_id                             = dependency.network.outputs.subnet_private_id
  vdag_id                                       = dependency.host_pool.outputs.vdag_id
  vdi_config_storage_container_name              = dependency.storage.outputs.vdi_config_storage_container_name
}

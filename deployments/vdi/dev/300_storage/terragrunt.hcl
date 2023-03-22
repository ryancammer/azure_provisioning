include {
  path = find_in_parent_folders("root.hcl")
}

dependency "azure_setup" {
  config_path = "../100_azure_setup"

  mock_outputs = {
    namespace           = "vdi-dev-westus2-alpha"
    resource_group_name = "rg-vdi-dev-westus2-alpha"
  }
}

inputs = {
  namespace           = dependency.azure_setup.outputs.namespace
  resource_group_name = dependency.azure_setup.outputs.resource_group_name
}

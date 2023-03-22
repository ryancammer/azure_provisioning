# deployments/root.hcl
locals {
  root_deployments_dir       = get_parent_terragrunt_dir()
  relative_deployment_path   = path_relative_to_include()
  deployment_path_components = compact(split("/", local.relative_deployment_path))

  tier  = local.deployment_path_components[0]
  stack = reverse(local.deployment_path_components)[0]

  # Get a list of every path between root_deployments_directory and the path of
  # the deployment
  possible_config_dirs = [
    for i in range(0, length(local.deployment_path_components) + 1) :
      join(
        "/",
        concat(
          [local.root_deployments_dir],
          slice(local.deployment_path_components, 0, i)
        )
      )
  ]
  # Generate a list of possible config files at every possible_config_dir
  # (support both .yml and .yaml)
  possible_config_paths = flatten(
    [
      for dir in local.possible_config_dirs : [
        "${dir}/config.yml",
        "${dir}/config.yaml"
      ]
    ]
  )
  # Load every YAML config file that exists into an HCL object
  file_configs = [
  for path in local.possible_config_paths :
  yamldecode(file(path)) if fileexists(path)
  ]
  # Merge the objects together, with deeper configs overriding higher configs
  merged_config = merge(local.file_configs...)

  env = try(yamldecode(file(find_in_parent_folders("env.yml"))), {})
}

# Pass the merged config to terraform as variable values using TF_VAR_
# environment variables
inputs = local.merged_config

# Default the stack each deployment deploys based on its directory structure
# Can be overridden by redefining this block in a child terragrunt.hcl
terraform {
  source = "${local.root_deployments_dir}/..//modules/stacks/${local.tier}/${local.stack}"

  extra_arguments "retry_lock" {
    commands = [
      "apply",
      "refresh",
      "import",
      "plan",
      "taint",
      "untaint"
    ]

    arguments = [
      "-lock-timeout=10m"
    ]

    env_vars = local.env
  }
}

remote_state {
  backend = "s3"
  generate = {
    path      = "backend.tf"
    if_exists = "overwrite"
  }
  config = {
    bucket         = "prod-us-west-1-vdi-state"
    dynamodb_table = "prod-us-west-1-vdi-state-lock"
    key            = "${path_relative_to_include()}/terraform.tfstate"
    region         = "us-west-1"
    encrypt        = true
    profile        = "tf-backend"
  }
}

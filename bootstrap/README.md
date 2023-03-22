# VDI - bootstrap

Bootstraps terraform state for this project.

This will to be run exactly once when the project initializes. This code 
creates an encrypted S3 bucket to store terraform state, and an encrypted 
DynamoDB table to manage the distributed lock to serialize terraform runs.

## Getting Started

- Run `terraform init && terraform apply`.
- Once the run has finished successfully, commit terraform state file into 
  source control.

## Wrapping Up

When the time comes to end this project, ensure that the project resources have 
been destroyed. Then run `terraform destroy` in this directory to clean up the 
last the state relating to this project.

This MUST only be done once the project is longer needed, and after ensuring 
that all other allocated resources have been destroyed.

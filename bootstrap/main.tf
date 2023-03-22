terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.0"
    }
  }
}

provider "aws" {
  region = "us-west-1"
}

module "tfstate_backend" {
  source = "../modules/aws_tfstate_backend"

  name   = "vdi"
  region = "us-west-1"
  stage  = "prod"
}

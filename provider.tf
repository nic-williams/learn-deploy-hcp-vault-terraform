terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = "6.31.0"
    }
    hcp = {
      source = "hashicorp/hcp"
      version = "0.111.0"
    }
    vault = {
      source  = "hashicorp/vault"
      version = "~> 4.0"
    }
    tfe = {
      source  = "hashicorp/tfe"
      version = "~> 0.60"
    }
  }
}


provider "aws" {
  # Configuration options
  region = var.region
}

provider "hcp" {
  # Configuration options
  # project_id = var.hcp_project
}

provider "vault" {
  address   = var.vault_addr
  namespace = "admin"
}

provider "tfe" {
  token = var.tfe_token
}
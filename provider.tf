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
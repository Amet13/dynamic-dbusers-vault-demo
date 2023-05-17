terraform {
  backend "local" {
    path = "terraform.tfstate"
  }
  required_providers {
    docker = {
      source  = "kreuzwerker/docker"
      version = "~> 3.0"
    }
    vault = {
      source  = "hashicorp/vault"
      version = "~> 3.15"
    }
  }
}

provider "docker" {
  host = "unix:///var/run/docker.sock"
}

provider "vault" {
  address = "http://127.0.0.1:8200"
  token   = var.vault_root_token
}

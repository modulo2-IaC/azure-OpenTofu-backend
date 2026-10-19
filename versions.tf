terraform {
  required_version = ">= 1.6.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.100"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.6"
    }
  }

  # Azure Blob Storage para estado remoto centralizado
  backend "azurerm" {
    resource_group_name  = "rg-asistencia-tfstate"
    storage_account_name = "sttofuasistenciadev"
    container_name       = "tfstate"
    key                  = "backend.terraform.tfstate"
  }
}

provider "azurerm" {
  features {}
}

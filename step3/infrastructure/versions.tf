terraform {
  required_version = ">= 1.5.0"

  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.22.0"
    }

    # http = {
    #   source  = "hashicorp/http"
    #   version = "~> 2.1.0"
    # }

    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.10.1"
    }

    null = {
      source  = "hashicorp/null"
      version = "~> 3.1.0"
    }

    # random = {
    #   source  = "hashicorp/random"
    #   version = "~> 3.1.0"
    # }
  }
}
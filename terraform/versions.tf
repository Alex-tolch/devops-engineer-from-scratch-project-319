terraform {
  required_version = ">= 1.11.0, < 2.0.0"

  required_providers {
    digitalocean = {
      source  = "digitalocean/digitalocean"
      version = "~> 2.106"
    }
    restful = {
      source  = "magodo/restful"
      version = "~> 0.25.2"
    }
  }

  backend "s3" {}
}

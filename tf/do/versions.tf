terraform {
  required_providers {
    cloudflare = {
      source = "terraform-providers/cloudflare"
    }
    consul = {
      source = "hashicorp/consul"
    }
    digitalocean = {
      source = "terraform-providers/digitalocean"
    }
  }
  required_version = ">= 0.13"
}

provider "digitalocean" {
  token = var.digitalocean_token
  # Spaces management credentials come from SPACES_ACCESS_KEY_ID and
  # SPACES_SECRET_ACCESS_KEY, separately from the scoped application key.
}

# DigitalOcean's Terraform provider does not yet implement Secrets Manager.
# Use the official API through a declarative REST resource with CRUD support.
provider "restful" {
  base_url = "https://api.digitalocean.com"
  security = {
    http = {
      token = {
        token = var.digitalocean_token
      }
    }
  }
}

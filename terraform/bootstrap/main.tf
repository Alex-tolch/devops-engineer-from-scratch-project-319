provider "digitalocean" {
  token = var.digitalocean_token
}

# This separate, locally stored bootstrap state breaks the backend dependency
# cycle. Protect and back it up; the main stack must not own its own backend.
resource "digitalocean_spaces_bucket" "state" {
  name          = var.state_bucket_name
  region        = "fra1"
  acl           = "private"
  force_destroy = false

  versioning {
    enabled = true
  }

  lifecycle {
    prevent_destroy = true
  }
}

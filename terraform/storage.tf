resource "digitalocean_spaces_bucket" "app" {
  name          = var.app_bucket_name
  region        = var.region
  acl           = "private"
  force_destroy = false
}

# This key can read and write application objects, but cannot administer other
# buckets or access the Terraform state bucket.
resource "digitalocean_spaces_key" "app" {
  name = "${local.name}-app"

  grant {
    bucket     = digitalocean_spaces_bucket.app.name
    permission = "readwrite"
  }
}

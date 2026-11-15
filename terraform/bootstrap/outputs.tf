output "state_bucket_name" {
  description = "Protected Spaces bucket storing the main Terraform state."
  value       = digitalocean_spaces_bucket.state.name
}

output "backend_config" {
  description = "Credential-free HCL for terraform/backend.hcl."
  value       = <<-HCL
    bucket = "${digitalocean_spaces_bucket.state.name}"
    key    = "bulletin-board/dev/terraform.tfstate"
    region = "us-east-1"
    endpoints = {
      s3 = "https://${digitalocean_spaces_bucket.state.region}.digitaloceanspaces.com"
    }
    skip_credentials_validation = true
    skip_requesting_account_id  = true
    skip_metadata_api_check     = true
    skip_region_validation      = true
    skip_s3_checksum            = true
    use_lockfile                = true
  HCL
}

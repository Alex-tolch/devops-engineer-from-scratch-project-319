variable "digitalocean_token" {
  description = "DigitalOcean token supplied using TF_VAR_digitalocean_token."
  type        = string
  sensitive   = true
  ephemeral   = true
}

variable "state_bucket_name" {
  description = "Globally unique Spaces bucket name used exclusively for state."
  type        = string

  validation {
    condition     = can(regex("^[a-z0-9][a-z0-9-]{1,61}[a-z0-9]$", var.state_bucket_name))
    error_message = "Use 3-63 lowercase letters, numbers or hyphens, with no leading or trailing hyphen."
  }
}


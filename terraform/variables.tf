variable "digitalocean_token" {
  description = "DigitalOcean API token supplied through TF_VAR_digitalocean_token."
  type        = string
  sensitive   = true
  ephemeral   = true
}

variable "project_name" {
  type    = string
  default = "bulletin-board"
}

variable "environment" {
  type    = string
  default = "dev"
}

variable "region" {
  type    = string
  default = "fra1"
}

variable "vpc_cidr" {
  type    = string
  default = "10.20.0.0/16"
}

variable "api_server_allowed_cidrs" {
  description = "Public administrator IP addresses allowed to reach the Kubernetes API, in CIDR notation."
  type        = list(string)

  validation {
    condition = length(var.api_server_allowed_cidrs) > 0 && alltrue([
      for address in var.api_server_allowed_cidrs : can(cidrnetmask(address)) && !endswith(address, "/0")
    ])
    error_message = "Provide at least one administrator IPv4 CIDR, such as your public IP/32."
  }
}

variable "kubernetes_version" {
  description = "Version prefix; isolated workers require Kubernetes 1.36 or later."
  type        = string
  default     = "1.36."
}

variable "node_size" {
  type    = string
  default = "s-2vcpu-4gb"
}

variable "node_count" {
  type    = number
  default = 1
}

variable "postgres_size" {
  type    = string
  default = "db-s-1vcpu-1gb"
}

variable "postgres_version" {
  type    = string
  default = "17"
}

variable "postgres_database" {
  type    = string
  default = "bulletins"
}

variable "app_bucket_name" {
  description = "Globally unique name of the application Spaces bucket."
  type        = string
}

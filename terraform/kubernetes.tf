data "digitalocean_kubernetes_versions" "available" {
  version_prefix = var.kubernetes_version == "latest" ? null : var.kubernetes_version
}

resource "digitalocean_kubernetes_cluster" "main" {
  name             = "${local.name}-k8s"
  region           = var.region
  version          = data.digitalocean_kubernetes_versions.available.latest_version
  vpc_uuid         = digitalocean_vpc.main.id
  isolated_workers = true
  ha               = false

  # DigitalOcean manages worker firewalls. Restrict the public API separately.
  control_plane_firewall {
    enabled           = true
    allowed_addresses = var.api_server_allowed_cidrs
  }

  node_pool {
    name       = "workers"
    size       = var.node_size
    node_count = var.node_count
    auto_scale = false
  }

  lifecycle {
    precondition {
      condition     = tonumber(split(".", data.digitalocean_kubernetes_versions.available.latest_version)[1]) >= 36
      error_message = "Isolated worker nodes require Kubernetes 1.36 or later."
    }
  }

  depends_on = [digitalocean_vpc_nat_gateway.main]
}

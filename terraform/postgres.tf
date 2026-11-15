resource "digitalocean_database_cluster" "postgres" {
  name                 = "${local.name}-postgres"
  engine               = "pg"
  version              = var.postgres_version
  size                 = var.postgres_size
  region               = var.region
  node_count           = 1
  private_network_uuid = digitalocean_vpc.main.id
}

# Trusted sources protect both public and private endpoints. Application
# connections use private_host; no workstation IP or 0.0.0.0/0 is admitted.
resource "digitalocean_database_firewall" "postgres" {
  cluster_id = digitalocean_database_cluster.postgres.id

  rule {
    type  = "k8s"
    value = digitalocean_kubernetes_cluster.main.id
  }
}

resource "digitalocean_database_db" "app" {
  cluster_id = digitalocean_database_cluster.postgres.id
  name       = var.postgres_database
}

# Use the generated doadmin credentials on this dedicated training cluster.
# Spring Boot creates its schema (ddl-auto=update), so an unprivileged user
# would require an additional SQL grant phase through the private endpoint.

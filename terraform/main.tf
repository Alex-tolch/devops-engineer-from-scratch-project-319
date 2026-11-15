locals {
  name = "${var.project_name}-${var.environment}"

  postgres_ca_path  = "/etc/postgresql/ca.crt"
  postgres_jdbc_url = "jdbc:postgresql://${digitalocean_database_cluster.postgres.private_host}:${digitalocean_database_cluster.postgres.port}/${digitalocean_database_db.app.name}?sslmode=verify-full&sslrootcert=${local.postgres_ca_path}"
}

data "digitalocean_database_ca" "postgres" {
  cluster_id = digitalocean_database_cluster.postgres.id
}

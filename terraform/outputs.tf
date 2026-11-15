output "cluster_id" {
  value = digitalocean_kubernetes_cluster.main.id
}

output "node_pool_id" {
  value = digitalocean_kubernetes_cluster.main.node_pool[0].id
}

output "kubeconfig" {
  value     = digitalocean_kubernetes_cluster.main.kube_config[0].raw_config
  sensitive = true
}

output "kubernetes_token" {
  value     = digitalocean_kubernetes_cluster.main.kube_config[0].token
  sensitive = true
}

output "postgres_connection" {
  value = {
    host           = digitalocean_database_cluster.postgres.private_host
    port           = digitalocean_database_cluster.postgres.port
    database       = digitalocean_database_db.app.name
    username       = digitalocean_database_cluster.postgres.user
    password       = digitalocean_database_cluster.postgres.password
    jdbc_url       = local.postgres_jdbc_url
    ca_path        = local.postgres_ca_path
    ca_certificate = data.digitalocean_database_ca.postgres.certificate
  }
  sensitive = true
}

output "s3_access" {
  value = {
    bucket     = digitalocean_spaces_bucket.app.name
    region     = digitalocean_spaces_bucket.app.region
    endpoint   = "https://${digitalocean_spaces_bucket.app.endpoint}"
    access_key = digitalocean_spaces_key.app.access_key
    secret_key = digitalocean_spaces_key.app.secret_key
  }
  sensitive = true
}

output "app_secret_id" {
  description = "Secrets Manager identifier in region/name format."
  value       = "${var.region}/${local.app_secret_name}"
  depends_on  = [restful_resource.app_secret]
}

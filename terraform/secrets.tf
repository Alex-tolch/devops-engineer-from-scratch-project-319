locals {
  app_secret_name = "${local.name}-app"

  app_environment = {
    SPRING_PROFILES_ACTIVE     = "prod"
    SPRING_DATASOURCE_URL      = local.postgres_jdbc_url
    SPRING_DATASOURCE_USERNAME = digitalocean_database_cluster.postgres.user
    SPRING_DATASOURCE_PASSWORD = digitalocean_database_cluster.postgres.password
    POSTGRES_CA_CERT           = data.digitalocean_database_ca.postgres.certificate
    STORAGE_S3_BUCKET          = digitalocean_spaces_bucket.app.name
    STORAGE_S3_REGION          = digitalocean_spaces_bucket.app.region
    STORAGE_S3_ENDPOINT        = "https://${digitalocean_spaces_bucket.app.endpoint}"
    STORAGE_S3_ACCESSKEY       = digitalocean_spaces_key.app.access_key
    STORAGE_S3_SECRETKEY       = digitalocean_spaces_key.app.secret_key
  }
}

# Secrets Manager is a native DigitalOcean service. The official DigitalOcean
# Terraform provider does not expose it yet, so manage its documented REST API
# with a declarative provider that supports full create/read/update/delete.
resource "terraform_data" "app_secret_identity" {
  triggers_replace = "${var.region}/${local.app_secret_name}"
}

resource "restful_resource" "app_secret" {
  path      = "/v2/security/secrets"
  read_path = "/v2/security/secrets/${local.app_secret_name}"

  body = sensitive({
    name   = local.app_secret_name
    region = var.region
    values = local.app_environment
  })

  read_query = {
    region = [var.region]
  }
  delete_query = {
    region = [var.region]
  }

  # GET uses "secret" where POST uses "name". Keep the current server version
  # in the response so updates use the API's optimistic-concurrency check.
  read_selector = "{\"name\":secret,\"region\":region,\"values\":values,\"version\":version}"
  update_method = "PUT"
  update_body_patches = [
    { path = "name", removed = true },
    { path = "version", raw_json = "$(body.version)" },
  ]

  use_sensitive_output = true

  lifecycle {
    replace_triggered_by = [terraform_data.app_secret_identity]
  }
}

# Resources without an explicit subnet join the VPC's default subnet.
# Additional VPC subnets are API-only in the current DigitalOcean provider.
resource "digitalocean_vpc" "main" {
  name        = "${local.name}-vpc"
  region      = var.region
  ip_range    = var.vpc_cidr
  description = "Private network for the bulletin board Kubernetes cluster and PostgreSQL."
}

# Isolated DOKS workers require the managed NAT gateway before provisioning.
# The gateway provides outbound access for bootstrap and container image pulls.
resource "digitalocean_vpc_nat_gateway" "main" {
  name   = "${local.name}-nat"
  type   = "PUBLIC"
  region = var.region
  size   = 1

  vpcs {
    vpc_uuid        = digitalocean_vpc.main.id
    default_gateway = true
  }
}

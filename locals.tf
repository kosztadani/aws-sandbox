locals {
    instances = var.run ? var.instances : 0
    public_ips = var.internet == "public" ? local.instances : 0
    nat_gateways = var.internet == "nat" ? 1 : 0
}

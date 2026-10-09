output "gke_endpoint" {
  value     = module.dependencies.gke_endpoint
  sensitive = true
}

output "gke_ca_certificate" {
  value     = module.dependencies.gke_ca_certificate
  sensitive = true
}

output "gcs_name" {
  value = module.dependencies.gcs_name
}
output "gcs_region" {
  value = module.dependencies.gcs_region
}

output "s3_access_key" {
  value     = module.dependencies.s3_access_key
  sensitive = true
}
output "s3_access_secret" {
  value     = module.dependencies.s3_access_secret
  sensitive = true
}

output "db_hostname" {
  value = module.dependencies.db_hostname
}
output "db_name" {
  value = module.dependencies.db_name
}
output "db_pass" {
  value     = module.dependencies.db_pass
  sensitive = true
}
output "db_user" {
  value = module.dependencies.db_user
}

output "redis_hostname" {
  value = module.dependencies.redis_hostname
}
output "redis_port" {
  value = module.dependencies.redis_port
}
output "redis_auth_string" {
  value     = module.dependencies.redis_auth_string
  sensitive = true
}

output "ingress_ipv4_name" {
  value = module.dependencies.ingress_ipv4_name
}

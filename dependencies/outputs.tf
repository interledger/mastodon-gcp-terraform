output "gke_endpoint" {
  value     = module.gke.endpoint
  sensitive = true
}

output "gke_ca_certificate" {
  value     = module.gke.ca_certificate
  sensitive = true
}

output "gcs_name" {
  value = google_storage_bucket.storage.name
}
output "gcs_region" {
  value = google_storage_bucket.storage.location
}

output "s3_access_key" {
  value     = google_storage_hmac_key.s3.access_id
  sensitive = true
}
output "s3_access_secret" {
  value     = google_storage_hmac_key.s3.secret
  sensitive = true
}

output "db_hostname" {
  value = google_sql_database_instance.postgres.private_ip_address
}
output "db_name" {
  value = google_sql_database.database.name
}
output "db_pass" {
  value     = google_sql_user.user.password
  sensitive = true
}
output "db_user" {
  value = google_sql_user.user.name
}

output "redis_hostname" {
  value = google_redis_instance.redis.host
}
output "redis_port" {
  value = google_redis_instance.redis.port
}
output "redis_auth_string" {
  value     = google_redis_instance.redis.auth_string
  sensitive = true
}

output "ingress_ipv4_name" {
  value = google_compute_global_address.reserved_ipv4_address.name
}

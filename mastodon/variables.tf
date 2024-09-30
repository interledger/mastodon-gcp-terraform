variable "credentials_file_path" {
  description = "Path to the JSON file of the service account credentials"
  sensitive   = true
}

variable "project" {}

variable "region" {
  # Consider the planet: https://cloud.google.com/sustainability/region-carbon
  default = "europe-north1"
}

variable "kubernetes_namespace" {
  default = "mastodon"
}

variable "tls_certificate_name" {
  default = "mastodon-cert"
}

# Mastodon Helm chart variables
# See https://docs.joinmastodon.org/admin/config/
variable "create_admin" {
  default = false
}
variable "create_admin_email" {
  default = ""
}
variable "create_admin_username" {
  default = ""
}
variable "local_domain" {}
variable "otp_secret" {}
variable "secret_key_base" {}
variable "smtp_auth_method" {
  default = "plain"
}
variable "smtp_enable_starttls" {
  default = "auto"
}
variable "smtp_from_address" {}
variable "smtp_login" {}
variable "smtp_openssl_verify_mode" {}
variable "smtp_password" {}
variable "smtp_port" {
  default = 587
}
variable "smtp_server" {}
variable "trusted_proxy_ip" {
  # The IP address range (trusted_proxy_ip) for Google Clould Global external Application Load Balancer can change without warning. To find the current range: `nslookup -q=TXT _cloud-eoips.googleusercontent.com 8.8.8.8`
  # Source: https://cloud.google.com/load-balancing/docs/https/setup-global-ext-https-external-backend#allow-ip
  # Must escape comma with \\ to prevent error: failed parsing key "mastodon.trusted_proxy_ip" with value 34.96.0.0/20,34.127.192.0/18, key "0/18" has no value
  default = "34.96.0.0/20\\,34.127.192.0/18\\,35.191.0.0/18\\,192.168.0.0/16"
}
variable "vapid_private_key" {}
variable "vapid_public_key" {}

variable "active_record_encryption_primary_key" {}
variable "active_record_encryption_deterministic_key" {}
variable "active_record_encryption_key_derivation_salt" {}

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
variable "vapid_private_key" {}
variable "vapid_public_key" {}

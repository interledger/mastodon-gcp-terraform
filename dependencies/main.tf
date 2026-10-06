terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = ">=4.66.0"
    }

    google-beta = {
      source  = "hashicorp/google-beta"
      version = ">= 4.51.0, < 5.0, !=4.65.0, !=4.65.1"
    }
  }

  backend "gcs" {
    bucket      = "interledger-social-terraform"
    prefix      = "terraform/state"
    credentials = "../terraform-sa.json"
  }
}

provider "google" {
  region      = var.region
  zone        = var.zone
  project     = var.project
  credentials = var.credentials_file_path
}
provider "google-beta" {
  region      = var.region
  zone        = var.zone
  project     = var.project
  credentials = var.credentials_file_path
}

module "dependencies" {
  source = "../modules/mastodon-gcp/dependencies"

  credentials_file_path             = var.credentials_file_path
  project                           = var.project
  service_account_name              = var.service_account_name
  region                            = var.region
  zone                              = var.zone
  mastodon_domain_name              = var.mastodon_domain_name
  dns_managed_zone_name             = var.dns_managed_zone_name
  additional_dns_records            = var.additional_dns_records
  vpc_name                          = var.vpc_name
  subnet_name                       = var.subnet_name
  kubernetes_services_ip_range_name = var.kubernetes_services_ip_range_name
  kubernetes_pods_ip_range_name     = var.kubernetes_pods_ip_range_name
  private_ip_alloc_name             = var.private_ip_alloc_name
  firewall_name_ipv4                = var.firewall_name_ipv4
  firewall_name_ipv6                = var.firewall_name_ipv6
  reserved_ipv4_address_name        = var.reserved_ipv4_address_name
  reserved_ipv6_address_name        = var.reserved_ipv6_address_name
  postgres_instance_name            = var.postgres_instance_name
  database_name                     = var.database_name
  database_user                     = var.database_user
  postgres_tier                     = var.postgres_tier
  postgres_disk_size                = var.postgres_disk_size
  postgres_availability_type        = var.postgres_availability_type
  redis_instance_name               = var.redis_instance_name
  redis_size_gb                     = var.redis_size_gb
  redis_tier                        = var.redis_tier
  storage_domain_name               = var.storage_domain_name
  mastodon_kubernetes_cluster_name  = var.mastodon_kubernetes_cluster_name
}

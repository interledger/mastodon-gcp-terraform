# IPv6-related features are commented out. It is not possible to use
# IPv6 with GCP until it fixes bugs in its official provider.
# The code is kept here in hope that one day, the Mastodon instance
# will be fully IPv6-enabled.

terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 8.6"
    }

    random = {
      source  = "hashicorp/random"
      version = "~> 3.5"
    }

    # ec = {
    #   source  = "elastic/ec"
    #   version = ">= 0.7.0, < 0.8.0"
    # }
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

# Create VPC, subnet, private services access, firewalls
resource "google_compute_network" "mastodon_vpc" {
  name                    = var.vpc_name
  auto_create_subnetworks = "false"
  mtu                     = 1460
  routing_mode            = "GLOBAL"
}

resource "google_compute_subnetwork" "mastodon_external_subnet" {
  name          = var.subnet_name
  region        = var.region
  network       = google_compute_network.mastodon_vpc.self_link
  ip_cidr_range = "10.2.0.0/19"
  # stack_type                 = "IPV4_IPV6"
  stack_type               = "IPV4_ONLY"
  ipv6_access_type         = "EXTERNAL"
  private_ip_google_access = true
  # private_ipv6_google_access = "ENABLE_OUTBOUND_VM_ACCESS_TO_GOOGLE"

  secondary_ip_range {
    range_name    = var.kubernetes_services_ip_range_name
    ip_cidr_range = "192.168.0.0/24"
  }
  secondary_ip_range {
    range_name    = var.kubernetes_pods_ip_range_name
    ip_cidr_range = "192.168.64.0/22"
  }
}

resource "google_compute_global_address" "private_ip_alloc" {
  name          = var.private_ip_alloc_name
  purpose       = "VPC_PEERING"
  address_type  = "INTERNAL"
  prefix_length = 20
  network       = google_compute_network.mastodon_vpc.id
}

resource "google_service_networking_connection" "private_service_access" {
  network                 = google_compute_network.mastodon_vpc.id
  service                 = "servicenetworking.googleapis.com"
  reserved_peering_ranges = [google_compute_global_address.private_ip_alloc.name]
}

resource "google_compute_firewall" "mastodon_firewall_ipv4" {
  name    = var.firewall_name_ipv4
  network = google_compute_network.mastodon_vpc.name

  direction     = "INGRESS"
  source_ranges = ["0.0.0.0/0"]

  allow {
    protocol = "tcp"
    ports    = ["80", "443"]
  }
}

# resource "google_compute_firewall" "mastodon_firewall_ipv6" {
#   name    = var.firewall_name_ipv6
#   network = google_compute_network.mastodon_vpc.name

#   direction     = "INGRESS"
#   source_ranges = ["::/0"]

#   allow {
#     protocol = "tcp"
#     ports = ["80", "443"]
#   }
# }

# Reserve IPv4 and IPv6 addresses for DNS
resource "google_compute_global_address" "reserved_ipv4_address" {
  name         = var.reserved_ipv4_address_name
  address_type = "EXTERNAL"
  ip_version   = "IPV4"
}

# data "google_compute_address" "reserved_ipv6_address" {
#   name = var.reserved_ipv6_address_name
# }

# Set the DNS records
resource "google_dns_managed_zone" "dns_zone" {
  name       = var.dns_managed_zone_name
  dns_name   = "${var.mastodon_domain_name}."
  visibility = "public"
  dnssec_config {
    state = "on"
  }
}

resource "google_dns_record_set" "mastodon_dns_a_record" {
  name    = "${var.mastodon_domain_name}."
  type    = "A"
  ttl     = 3600
  rrdatas = [google_compute_global_address.reserved_ipv4_address.address]

  managed_zone = google_dns_managed_zone.dns_zone.name
}

# resource "google_dns_record_set" "mastodon_dns_aaaa_record" {
#   name    = "${var.mastodon_domain_name}."
#   type    = "AAAA"
#   ttl     = 3600
#   rrdatas = [data.google_compute_address.reserved_ipv6_address.address]

#   managed_zone = google_dns_managed_zone.dns_zone.name
# }

resource "google_dns_record_set" "additional_dns_records" {
  # Convert list of objects to a map so Terraform can for_loop
  for_each = { for record in var.additional_dns_records : "${record.type}_${record.name}" => record }

  name    = each.value["name"]
  type    = each.value["type"]
  ttl     = each.value["ttl"]
  rrdatas = each.value["rrdatas"]

  managed_zone = google_dns_managed_zone.dns_zone.name
}

# File storage bucket for uploads
# User running the Terraform must be a domain owner in Search Console
resource "google_storage_bucket" "storage" {
  name                        = var.storage_domain_name
  location                    = var.region
  uniform_bucket_level_access = false
  storage_class               = "STANDARD"

  cors {
    origin          = ["*"]
    method          = ["GET", "HEAD"]
    response_header = ["*"]
    max_age_seconds = 3600
  }
}
# This service account will be used to generate S3 API-compatible credentials
resource "google_service_account" "s3" {
  account_id   = "mastodon-gcs-sa"
  display_name = "Mastodon GCS Service Account"
}
resource "google_project_iam_member" "s3" {
  project = var.project
  role    = "roles/storage.objectAdmin"
  member  = "serviceAccount:${google_service_account.s3.email}"
}
resource "google_storage_hmac_key" "s3" {
  service_account_email = google_service_account.s3.email
}


# Redis cache
resource "google_redis_instance" "redis" {
  name           = var.redis_instance_name
  redis_version  = "REDIS_7_2"
  memory_size_gb = var.redis_size_gb
  region         = var.region
  location_id    = var.zone
  tier           = var.redis_tier
  auth_enabled   = true

  authorized_network = google_compute_network.mastodon_vpc.id
  connect_mode       = "PRIVATE_SERVICE_ACCESS"

  depends_on = [google_service_networking_connection.private_service_access]
}

# PostgreSQL database server instance
resource "google_sql_database_instance" "postgres" {
  name             = var.postgres_instance_name
  region           = var.region
  database_version = "POSTGRES_15"

  depends_on = [google_service_networking_connection.private_service_access]

  settings {
    tier                        = var.postgres_tier
    disk_size                   = var.postgres_disk_size
    disk_autoresize             = true
    availability_type           = var.postgres_availability_type
    deletion_protection_enabled = true

    database_flags {
      name  = "cloudsql.iam_authentication"
      value = "on"
    }

    backup_configuration {
      enabled                        = true
      point_in_time_recovery_enabled = true
    }

    insights_config {
      query_insights_enabled = true
    }

    ip_configuration {
      ipv4_enabled                                  = false
      private_network                               = google_compute_network.mastodon_vpc.id
      enable_private_path_for_google_cloud_services = true
    }
  }
}

# The database inside the PostgreSQL server
resource "google_sql_database" "database" {
  name            = var.database_name
  instance        = google_sql_database_instance.postgres.name
  deletion_policy = "ABANDON"
}

# Database user
resource "random_password" "sql_user_password" {
  length  = 48
  special = false
}
resource "google_sql_user" "user" {
  name            = var.database_user
  instance        = google_sql_database_instance.postgres.name
  password        = random_password.sql_user_password.result
  deletion_policy = "ABANDON"
}

# Kubernetes Cluster
data "google_service_account" "terraform_sa" {
  account_id = var.service_account_name
}

# Service account used by the Autopilot nodes
resource "random_string" "gke_sa_suffix" {
  upper   = false
  lower   = true
  special = false
  length  = 4
}
resource "google_service_account" "gke_nodes" {
  account_id   = "tf-gke-${substr(var.mastodon_kubernetes_cluster_name, 0, 15)}-${random_string.gke_sa_suffix.result}"
  display_name = "Terraform-managed service account for cluster ${var.mastodon_kubernetes_cluster_name}"
}
resource "google_project_iam_member" "gke_nodes" {
  for_each = toset([
    "roles/logging.logWriter",
    "roles/monitoring.metricWriter",
    "roles/monitoring.viewer",
    "roles/stackdriver.resourceMetadata.writer",
  ])

  project = var.project
  role    = each.value
  member  = google_service_account.gke_nodes.member
}

resource "google_container_cluster" "gke" {
  name                = var.mastodon_kubernetes_cluster_name
  location            = var.region
  enable_autopilot    = true
  deletion_protection = true

  network         = google_compute_network.mastodon_vpc.id
  subnetwork      = google_compute_subnetwork.mastodon_external_subnet.id
  networking_mode = "VPC_NATIVE"

  ip_allocation_policy {
    cluster_secondary_range_name  = var.kubernetes_pods_ip_range_name
    services_secondary_range_name = var.kubernetes_services_ip_range_name
  }

  release_channel {
    channel = "REGULAR"
  }

  cluster_autoscaling {
    auto_provisioning_defaults {
      service_account = google_service_account.gke_nodes.email
    }
  }

  vertical_pod_autoscaling {
    enabled = true
  }

  security_posture_config {
    mode               = "BASIC"
    vulnerability_mode = "VULNERABILITY_BASIC"
  }

  maintenance_policy {
    daily_maintenance_window {
      start_time = "05:00"
    }
  }
}

# Migrate state from the terraform-google-modules/kubernetes-engine module,
# which required the google-beta provider. Safe to remove once applied.
# The cluster cannot be moved across providers. Before the first apply, run:
#   terraform state rm module.gke.google_container_cluster.primary
# so that it is re-imported with the google provider.
import {
  to = google_container_cluster.gke
  id = "projects/${var.project}/locations/${var.region}/clusters/${var.mastodon_kubernetes_cluster_name}"
}
moved {
  from = module.gke.random_string.cluster_service_account_suffix
  to   = random_string.gke_sa_suffix
}
moved {
  from = module.gke.google_service_account.cluster_service_account[0]
  to   = google_service_account.gke_nodes
}
moved {
  from = module.gke.google_project_iam_member.cluster_service_account-log_writer[0]
  to   = google_project_iam_member.gke_nodes["roles/logging.logWriter"]
}
moved {
  from = module.gke.google_project_iam_member.cluster_service_account-metric_writer[0]
  to   = google_project_iam_member.gke_nodes["roles/monitoring.metricWriter"]
}
moved {
  from = module.gke.google_project_iam_member.cluster_service_account-monitoring_viewer[0]
  to   = google_project_iam_member.gke_nodes["roles/monitoring.viewer"]
}
moved {
  from = module.gke.google_project_iam_member.cluster_service_account-resourceMetadata-writer[0]
  to   = google_project_iam_member.gke_nodes["roles/stackdriver.resourceMetadata.writer"]
}
removed {
  from = module.gke.random_shuffle.available_zones
  lifecycle {
    destroy = false
  }
}

# Elastic Cloud instance
# External Elasticsearch not yet supported by Mastodon chart
# Disabled until https://github.com/mastodon/chart/issues/30
# provider "ec" {
#   apikey = var.ec_credentials
# }
# data "ec_stack" "latest" {
#   count = var.use_elastic_cloud ? 1 : 0

#   version_regex = "latest"
#   region        = var.ec_region
# }
# resource "ec_deployment" "elasticsearch" {
#   count = var.use_elastic_cloud ? 1 : 0

#   name                   = var.ec_deployment_name
#   region                 = var.ec_region
#   version                = data.ec_stack.latest[0].version
#   deployment_template_id = var.ec_deployment_template

#   elasticsearch = {
#     autoscale = false

#     hot = {
#       autoscaling   = {} # required, empty to disable
#       size          = var.ec_hot_size
#       size_resource = var.ec_hot_size_resource
#       zone_count    = var.ec_hot_zone_count
#     }
#   }

#   # Kibana not needed, but free and documentation notes issues when not included
#   # https://registry.terraform.io/providers/elastic/ec/latest/docs/resources/deployment#kibana
#   kibana = {}

#   enterprise_search = {
#     size          = var.ec_search_size
#     size_resource = var.ec_search_size_resource
#     zone_count    = var.ec_search_zone_count
#   }
# }

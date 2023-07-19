variable "credentials_file_path" {
  description = "Path to the JSON file of the service account credentials"
  sensitive   = true
}

variable "project" {
  description = "GCP project name"
}

variable "service_account_name" {}

variable "region" {
  # Consider the planet: https://cloud.google.com/sustainability/region-carbon
  default = "europe-north1"
}

variable "zone" {
  default = "europe-north1-a"
}

# Domain name
variable "mastodon_domain_name" {
  description = "Root domain (eg example.com)"
}
variable "dns_managed_zone_name" {
  default     = "mastodon-domain"
  description = "GCP name for the Managed DNS Zone"
}
variable "additional_dns_records" {
  type = list(
    object({
      name    = string
      type    = string
      ttl     = number
      rrdatas = list(string)
    })
  )

  default = []
}


# VPC network
variable "vpc_name" {
  default = "mastodon-vpc-1"
}
variable "subnet_name" {
  default = "mastodon-external-subnet-1"
}
variable "kubernetes_services_ip_range_name" {
  default = "mastodon-kubernetes-services-range"
}
variable "kubernetes_pods_ip_range_name" {
  default = "mastodon-kubernetes-pods-range"
}
variable "private_ip_alloc_name" {
  default = "mastodon-vpc-1-ip-range"
}

variable "firewall_name_ipv4" {
  default = "mastodon-firewall-ipv4-1"
}
variable "firewall_name_ipv6" {
  default = "mastodon-firewall-ipv6-1"
}

variable "reserved_ipv4_address_name" {
  default = "mastodon-static-address-ipv4-1"
}
variable "reserved_ipv6_address_name" {
  default = "mastodon-static-address-ipv6-1"
}

# PostgreSQL
variable "postgres_instance_name" {
  default = "mastodon-pg-instance-1"
}
variable "database_name" {
  default = "mastodon-db-1"
}
variable "database_user" {
  default = "mastodon-postgres"
}

variable "postgres_tier" {
  # List at https://cloud.google.com/sdk/gcloud/reference/sql/tiers/list
  default = "db-custom-1-3840" # 1 CPU, 3.75*1024 MB RAM
}

variable "postgres_disk_size" {
  default = 10
}

variable "postgres_availability_type" {
  default = "ZONAL"
}

# Redis
variable "redis_instance_name" {
  default = "mastodon-redis-1"
}
variable "redis_size_gb" {
  default = 1
}
variable "redis_tier" {
  default = "BASIC"
}

# S3-compatible storage
variable "storage_domain_name" {}

# Kubernetes
variable "mastodon_kubernetes_cluster_name" {
  default = "mastodon-gke-1"
}

# Elasticsearch
# variable "use_elastic_cloud" {
#   default = false
# }
# variable "ec_credentials" {
#   sensitive = true
# }
# variable "ec_region" {
#   default = "gcp-europe-north1"
# }
# variable "ec_deployment_name" {
#   default = "mastodon-search-1"
# }
# variable "ec_deployment_template" {
#   # List at https://www.elastic.co/guide/en/cloud/current/ec-regions-templates-instances.html
#   default = "gcp-storage-optimized-v5"
# }
# # Hot data tier
# variable "ec_hot_size" {
#   default = "1g"
# }
# variable "ec_hot_size_resource" {
#   default = "memory"
# }
# variable "ec_hot_zone_count" {
#   default = 1
# }
# # Enterprise Search instance
# variable "ec_search_size" {
#   default = "2g"
# }
# variable "ec_search_size_resource" {
#   default = "memory"
# }
# variable "ec_search_zone_count" {
#   default = 1
# }

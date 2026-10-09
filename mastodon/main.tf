terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 8.6"
    }

    helm = {
      source  = "hashicorp/helm"
      version = "~> 3.3"
    }
  }

  backend "gcs" {
    bucket      = "interledger-social-terraform"
    prefix      = "terraform/state/mastodon-app"
    credentials = "../terraform-sa.json"
  }
}

provider "google" {
  project     = var.project
  credentials = var.credentials_file_path
}

data "google_client_config" "default" {}

data "terraform_remote_state" "dependencies" {
  backend = "gcs"

  config = {
    bucket      = "interledger-social-terraform"
    prefix      = "terraform/state"
    credentials = "../terraform-sa.json"
  }
}

provider "kubernetes" {
  host                   = "https://${data.terraform_remote_state.dependencies.outputs.gke_endpoint}"
  token                  = data.google_client_config.default.access_token
  cluster_ca_certificate = base64decode(data.terraform_remote_state.dependencies.outputs.gke_ca_certificate)
}

# Prepare GKE ingress TLS certificate
resource "kubernetes_manifest" "managedcertificate_managed_cert" {
  manifest = {
    apiVersion = "networking.gke.io/v1"
    kind       = "ManagedCertificate"

    metadata = {
      name      = var.tls_certificate_name
      namespace = var.kubernetes_namespace
    }

    spec = {
      domains = [
        var.local_domain
      ]
    }
  }
}

# Mastodon release on Kubernetes
provider "helm" {
  kubernetes = {
    host                   = "https://${data.terraform_remote_state.dependencies.outputs.gke_endpoint}"
    token                  = data.google_client_config.default.access_token
    cluster_ca_certificate = base64decode(data.terraform_remote_state.dependencies.outputs.gke_ca_certificate)
  }
}

# Mastodon does not yet publish its Helm chart in a chart repository
# See: https://github.com/mastodon/chart/issues/27
# See: https://github.com/mastodon/chart/pull/54
# Downloading as source as an interim solution

resource "helm_release" "mastodon" {
  name      = "mastodon"
  namespace = var.kubernetes_namespace
  chart     = "../charts/chart"

  create_namespace = true

  wait = false

  set = [
    {
      name  = "mastodon.createAdmin.enabled"
      value = var.create_admin
    },
    {
      name  = "mastodon.createAdmin.username"
      value = var.create_admin_username
    },
    {
      name  = "mastodon.createAdmin.email"
      value = var.create_admin_email
    },

    {
      name  = "mastodon.local_domain"
      value = var.local_domain
    },

    {
      name  = "mastodon.logLevel.rails"
      value = var.logLevel_rails
    },
    {
      name  = "mastodon.logLevel.streaming"
      value = var.logLevel_streaming
    },

    {
      name  = "mastodon.persistence.assets.accessMode"
      value = "ReadWriteMany"
    },
    {
      name  = "mastodon.persistence.system.accessMode"
      value = "ReadWriteMany"
    },

    {
      name  = "mastodon.s3.enabled"
      value = true
    },
    {
      name  = "mastodon.s3.access_key"
      value = data.terraform_remote_state.dependencies.outputs.s3_access_key
    },
    {
      name  = "mastodon.s3.bucket"
      value = data.terraform_remote_state.dependencies.outputs.gcs_name
    },
    {
      name  = "mastodon.s3.endpoint"
      value = "https://storage.googleapis.com"
    },
    {
      name  = "mastodon.s3.hostname"
      value = "storage.googleapis.com"
    },
    {
      name  = "mastodon.s3.region"
      value = data.terraform_remote_state.dependencies.outputs.gcs_region
    },
    {
      name  = "mastodon.secrets.vapid.public_key"
      value = var.vapid_public_key
    },

    {
      name  = "mastodon.smtp.auth_method"
      value = var.smtp_auth_method
    },
    {
      name  = "mastodon.smtp.domain"
      value = var.local_domain
    },
    {
      name  = "mastodon.smtp.enable_starttls"
      value = var.smtp_enable_starttls
    },
    {
      name  = "mastodon.smtp.from_address"
      value = var.smtp_from_address
    },
    {
      name  = "mastodon.smtp.openssl_verify_mode"
      value = var.smtp_openssl_verify_mode
    },
    {
      name  = "mastodon.smtp.port"
      value = var.smtp_port
    },
    {
      name  = "mastodon.smtp.server"
      value = var.smtp_server
    },

    {
      name  = "mastodon.trusted_proxy_ip"
      value = var.trusted_proxy_ip
    },

    {
      name  = "ingress.annotations.networking\\.gke\\.io/managed-certificates"
      value = var.tls_certificate_name
    },
    {
      name  = "ingress.annotations.kubernetes\\.io/ingress\\.global-static-ip-name"
      value = data.terraform_remote_state.dependencies.outputs.ingress_ipv4_name
    },
    {
      name  = "ingress.hosts[0].host"
      value = var.local_domain
    },
    {
      name  = "ingress.hosts[0].paths[0].path"
      value = "/"
    },
    {
      name  = "ingress.tls"
      value = false
    },

    {
      name  = "postgresql.enabled"
      value = false
    },
    {
      name  = "postgresql.postgresqlHostname"
      value = data.terraform_remote_state.dependencies.outputs.db_hostname
    },
    {
      name  = "postgresql.postgresqlPort"
      value = 5432
    },
    {
      name  = "postgresql.auth.database"
      value = data.terraform_remote_state.dependencies.outputs.db_name
    },
    {
      name  = "postgresql.auth.username"
      value = data.terraform_remote_state.dependencies.outputs.db_user
    },

    {
      name  = "redis.enabled"
      value = false
    },
    {
      name  = "redis.hostname"
      value = data.terraform_remote_state.dependencies.outputs.redis_hostname
    },
    {
      name  = "redis.port"
      value = data.terraform_remote_state.dependencies.outputs.redis_port
    },

    {
      name  = "elasticsearch.enabled"
      value = false
    },
  ]

  set_sensitive = [
    {
      name  = "mastodon.s3.access_secret"
      value = data.terraform_remote_state.dependencies.outputs.s3_access_secret
    },

    {
      name  = "mastodon.secrets.secret_key_base"
      value = var.secret_key_base
    },
    {
      name  = "mastodon.secrets.otp_secret"
      value = var.otp_secret
    },
    {
      name  = "mastodon.secrets.vapid.private_key"
      value = var.vapid_private_key
    },
    {
      name  = "mastodon.secrets.activeRecordEncryption.primaryKey"
      value = var.active_record_encryption_primary_key
    },
    {
      name  = "mastodon.secrets.activeRecordEncryption.deterministicKey"
      value = var.active_record_encryption_deterministic_key
    },
    {
      name  = "mastodon.secrets.activeRecordEncryption.keyDerivationSalt"
      value = var.active_record_encryption_key_derivation_salt
    },
    {
      name  = "mastodon.smtp.login"
      value = var.smtp_login
    },
    {
      name  = "mastodon.smtp.password"
      value = var.smtp_password
    },
    {
      name  = "postgresql.auth.password"
      value = data.terraform_remote_state.dependencies.outputs.db_pass
    },
    {
      name  = "redis.auth.password"
      value = data.terraform_remote_state.dependencies.outputs.redis_auth_string
    },
  ]

  values = [
    yamlencode(var.node_selector != null ? { nodeSelector : var.node_selector } : {})
  ]
}

# Add ingress rule for redirecting http-to-https
resource "kubernetes_manifest" "frontendconfig_https_redirect" {
  manifest = {
    "apiVersion" = "networking.gke.io/v1beta1"
    "kind"       = "FrontendConfig"

    "metadata" = {
      "name"      = "https-redirect"
      "namespace" = var.kubernetes_namespace
    }

    "spec" = {
      "redirectToHttps" = {
        "enabled" = true
      }
    }
  }
}

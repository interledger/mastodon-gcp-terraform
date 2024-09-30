# Mastodon on GCP via Terraform

This Terraform project manages the Google Cloud Platform infrastructure necessary for operating the Interledger Foundation's [Mastodon](https://joinmastodon.org/) instance. This repository is intended to be reusable by other people who want to operate a Mastodon instance using GCP.

Mastodon requires:

- a domain name (Cloud DNS)
- a PostgreSQL database (Cloud SQL)
- a Redis database (Memorystore)
- an S3-compatible object storage (Cloud Storage)
- a Kubernetes cluster (Kubernetes Engine in Autopilot mode)

Additional GCP-specific functionality:

- [Global external Application Load Balancer](https://cloud.google.com/load-balancing/docs/https) for ingress
- [Google-managed TLS certificates](https://cloud.google.com/kubernetes-engine/docs/how-to/managed-certs)
- Ingress rule to redirect `http` traffic to `https`

This project was tested on 2024-09-30 with:

- GKE 1.30.3-gke.1969001
- helm 3.16.1
- Mastodon chart 5.4.0 (* see below)
- Mastodon app 4.2.12

## How to use

### Prerequisites

This project assumes you have [`gcloud`](https://cloud.google.com/sdk/gcloud/) and [`helm`](https://helm.sh/docs/intro/install/) installed locally.

This project assumes the use of automated deployments, so a [service account](https://console.cloud.google.com/iam-admin/iam) is used to apply the Terraform. Grant the service account (`terraform-sa`) the roles of Compute Network Admin, Editor, and Security Admin. Download the JSON credentials and set the `credentials_file_path` in `terraform.tfvars`. Alternatively, you can run this Terraform code locally with your Google account and authenticate using the [`gcloud` CLI](https://cloud.google.com/sdk/gcloud/).

This project sets the DNS records for the Mastodon instance. The domain name must be pointed to [Google Cloud DNS](https://console.cloud.google.com/net-services/dns/zones) name servers and the service account (or Google account running the Terraform) must be an owner for the domain name in the [Google Search Console](https://search.google.com/search-console/users).

[Create a Cloud Storage bucket](https://console.cloud.google.com/storage/browser) dedicated to storing the Terraform state. This must be provisioned manually or independently of these modules, as it is a dependency for running this Terraform.

~~Elastic Cloud’s Elasticsearch Service (ESS) is used because GCP does not offer managed Elasticsearch. [Generate an API key](https://registry.terraform.io/providers/elastic/ec/latest/docs#api-key-authentication-recommended) to use.~~ [Blocked by Mastodon chart issue](https://github.com/mastodon/chart/issues/30)

### Project structure

Terraform best practices dictate Kubernetes clusters and Kubernetes resources not [co-exist](https://itnext.io/terraform-dont-use-kubernetes-provider-with-your-cluster-resource-d8ec5319d14a). The `dependencies` module must be applied before and separately from the `mastodon` module.

The `dependencies` Terraform module provisions GCP-managed resources and Google Kubernetes Engine in autopilot mode.

The `mastodon` Terraform module deploys the official [Mastodon Helm chart](https://github.com/mastodon/chart) with GCP-specific amendments.

Run `terraform init` in both module directories.

### Create the infrastructure

1. Create a `terraform.tfvars` file in `./dependencies/` with the necessary variables. See the [`dependencies/terraform.tfvars.example`](./dependencies/terraform.tfvars.example) file for guidance.

2. `cd ./dependencies && terraform apply`

### Deploy Mastodon and GKE resources

1. Clone the Mastodon Helm chart into `./charts` because it is not published anywhere [yet](https://github.com/mastodon/chart/issues/27). `cd ./charts && git clone https://github.com/mastodon/chart.git --single-branch --branch=main --depth=1 && cd chart && helm dep update`

2. Create a `terraform.tfvars` file in `./mastodon/` with the necessary variables. See the [`mastodon/terraform.tfvars.example`](./mastodon/terraform.tfvars.example) file for guidance.

3. `cd ./mastodon && terraform apply`

## Known limitations

- As of 2023-06, Google Cloud's IPv6 support is a work in progress. IPv6 support will be added once GCP resolves several outstanding issues with its Terraform provider.

- [`WEB_DOMAIN`](https://docs.joinmastodon.org/admin/config/#web_domain) is not supported, but could be. Contribution welcomed.

## Troubleshooting

### HTTPS

If you get HTTPS-related errors, but everything else seems ok, check the status of the certificate with `kubectl get ManagedCertificate mastodon-cert -n mastodon`. Provisioning a Google-managed certificate can take [up to an hour](https://cloud.google.com/load-balancing/docs/ssl-certificates/troubleshooting#certificate-managed-status).

### Upgrading to Mastodon 4.3

You must generate encryption secrets environment variables before upgrading.

1. `kubectl -n mastodon get pods` to list the pods. Look for something with "mastodon-web".
2. `kubectl -n mastodon exec --stdin --tty mastodon-web-99z999z9z9-99zz9 -- /bin/bash` to connect to the container.
3. `bin/rails db:encryption:init` to generate the new encryption secrets environment variables.
4. Add the credentials to your `terraform.tfvars` file as `active_record_encryption_primary_key`, `active_record_encryption_deterministic_key`, and `active_record_encryption_key_derivation_salt`.

## License

This is configuration code. This work is marked with CC0 1.0 Universal. It is dedicated to the public domain. See LICENSE file.

[Contributions](./CONTRIBUTING.md) welcomed.

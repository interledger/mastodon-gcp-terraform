# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/) and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [3.0.0] - 2026-10-10

### Removed

- Removed the one-time `import`, `moved`, and `removed` blocks that migrated the GKE cluster out of the `terraform-google-modules/kubernetes-engine` module. Deployments on 1.x must upgrade to 2.0.0 (tag `v2.0.0`) and run `terraform apply` before upgrading to this version.

## [2.0.0] - 2026-10-09

### Changed

- Upgraded the `hashicorp/google` provider to v8.6 and removed the `hashicorp/google-beta` provider
- Upgraded the `hashicorp/helm` provider to v3.3, which changes `set` and `set_sensitive` from blocks to lists of objects
- Replaced the `terraform-google-modules/kubernetes-engine` module with a native `google_container_cluster` resource. Workload vulnerability scanning now uses `security_posture_config` instead of the beta-only `protect_config`. Existing deployments must run `terraform state rm module.gke.google_container_cluster.primary` in `./dependencies` before the next `terraform apply` so the cluster is re-imported with the `google` provider.

## [1.0.2] - 2026-02-24

### Added

- Added support for `mastodon.logLevel.rails` and `mastodon.logLevel.streaming` env vars

## [1.0.1] - 2023-07-21

### Fixed

- Fixed uploads being blocked due to GCS bucket not using object ACLs

## [1.0.0] - 2023-07-19

### Added

- Initial release to support deploying Mastodon to Google Cloud Platform using Terraform

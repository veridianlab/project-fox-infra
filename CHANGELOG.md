# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.2.0] - 2026-05-29

### Breaking Changes

- **Removed `allowed_ip_ranges` variable from `lb-cloud-armor` module.** IP allowlisting is no longer managed via Terraform. The Cloud Armor policy deployed by this module contains only the default-deny rule. IP allow rules are now populated at runtime by the application's IP whitelist sync. Until the application has synced at least one allow rule after `terraform apply`, all inbound traffic will be denied with a 403. If upgrading from a previous version, remove `allowed_ip_ranges` from your module block and migrate any static IPs to the application's IP whitelist configuration.

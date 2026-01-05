# Cloud NAT Module

This module creates a Cloud NAT gateway with a static external IP address. This is essential for Cloud Run services that need to call external APIs which require IP allowlisting.

## Features

- **Static External IP**: Reserves a static external IP address for consistent outbound traffic
- **Cloud Router**: Automatically creates the required Cloud Router
- **Cloud NAT Gateway**: Configures NAT for all subnetworks in the VPC
- **Logging**: Optional NAT logging for troubleshooting
- **Port Allocation**: Configurable port allocation settings

## How It Works

1. Cloud Run services are configured to route egress traffic through VPC (via VPC Connector)
2. VPC traffic is routed through Cloud NAT
3. Cloud NAT uses the static external IP for all outbound connections
4. Third-party APIs see a consistent IP address

## Usage

```hcl
module "cloud_nat" {
  source = "./modules/cloud-nat"

  project_id       = var.project_id
  region           = var.region
  nat_name         = "my-cloud-nat"
  vpc_network_name = module.vpc_network.network_name

  # Optional: Enable detailed logging
  enable_logging = true
  log_filter     = "ALL"
}

# Output the static IP to provide to third-party APIs
output "nat_external_ip" {
  description = "Static IP address for API allowlisting"
  value       = module.cloud_nat.nat_ip_address
}
```

## Important Notes

1. **Cloud Run VPC Egress**: Your Cloud Run service must be configured with `vpc_egress = "all-traffic"` to route ALL traffic through the VPC (not just private traffic)
2. **VPC Connector Required**: Cloud Run needs a VPC Connector to access the VPC network
3. **Cost**: Static IP addresses and Cloud NAT have associated costs
4. **IP Allowlisting**: Provide the output `nat_ip_address` to your third-party API provider

## Inputs

| Name             | Description                                          | Type   | Default     | Required |
| ---------------- | ---------------------------------------------------- | ------ | ----------- | -------- |
| project_id       | The GCP project ID                                   | string | -           | yes      |
| region           | The GCP region                                       | string | -           | yes      |
| nat_name         | Name of the Cloud NAT gateway                        | string | -           | yes      |
| vpc_network_name | Name of the VPC network                              | string | -           | yes      |
| enable_logging   | Enable NAT logging                                   | bool   | true        | no       |
| log_filter       | Logging filter (ERRORS_ONLY, TRANSLATIONS_ONLY, ALL) | string | ERRORS_ONLY | no       |
| min_ports_per_vm | Minimum ports per VM                                 | number | 64          | no       |
| max_ports_per_vm | Maximum ports per VM                                 | number | 65536       | no       |

## Outputs

| Name             | Description                                                       |
| ---------------- | ----------------------------------------------------------------- |
| nat_ip_address   | The static external IP address (provide this to third-party APIs) |
| nat_name         | The name of the Cloud NAT gateway                                 |
| router_name      | The name of the Cloud Router                                      |
| nat_ip_self_link | The self_link of the NAT IP                                       |

## Example: Complete Setup

```hcl
# 1. VPC Network
module "vpc_network" {
  source       = "./modules/vpc-network"
  project_id   = var.project_id
  network_name = "my-vpc"
  environment  = "production"
}

# 2. VPC Connector
module "vpc_connector" {
  source           = "./modules/vpc-connector"
  project_id       = var.project_id
  region           = var.region
  connector_name   = "my-connector"
  vpc_network_name = module.vpc_network.network_name
  ip_cidr_range    = "10.8.0.0/28"
}

# 3. Cloud NAT with Static IP
module "cloud_nat" {
  source           = "./modules/cloud-nat"
  project_id       = var.project_id
  region           = var.region
  nat_name         = "my-nat"
  vpc_network_name = module.vpc_network.network_name
}

# 4. Cloud Run with VPC and NAT
module "cloudrun" {
  source               = "./modules/cloudrun"
  project_id           = var.project_id
  region               = var.region
  service_name         = "my-api"
  image                = "gcr.io/my-project/my-api:latest"
  vpc_connector_name   = module.vpc_connector.connector_id
  vpc_egress           = "all-traffic"  # CRITICAL: Route ALL traffic through VPC
  # ... other variables
}

# Output the static IP for allowlisting
output "static_nat_ip" {
  description = "Provide this IP to third-party API providers for allowlisting"
  value       = module.cloud_nat.nat_ip_address
}
```

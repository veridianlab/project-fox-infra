# VPC Connector Module

Creates a Serverless VPC Access connector to allow Cloud Run services to access resources in a VPC network.

## Features

- ✅ Serverless VPC Access connector
- ✅ Dedicated subnet for connector
- ✅ Configurable instance scaling
- ✅ Cost-effective e2-micro instances

## Usage

```hcl
module "vpc_connector" {
  source = "git::https://github.com/veridianlab/project-fox-infra.git//modules/vpc-connector?ref=v1.1.0"

  project_id       = "project-fox-staging"
  region           = "asia-southeast1"
  connector_name   = "cloudrun-connector-staging"
  vpc_network_name = module.vpc_network.network_name

  ip_cidr_range = "10.8.0.0/28"
  machine_type  = "e2-micro"
  min_instances = 2
  max_instances = 3
}
```

## Inputs

| Name             | Description                                  | Type     | Default         | Required |
| ---------------- | -------------------------------------------- | -------- | --------------- | -------- |
| project_id       | GCP Project ID                               | `string` | n/a             | yes      |
| region           | GCP Region                                   | `string` | n/a             | yes      |
| connector_name   | Name of the VPC Access Connector             | `string` | n/a             | yes      |
| vpc_network_name | Name of the VPC network                      | `string` | n/a             | yes      |
| ip_cidr_range    | IP CIDR range for the connector subnet (/28) | `string` | `"10.8.0.0/28"` | no       |
| machine_type     | Machine type for connector instances         | `string` | `"e2-micro"`    | no       |
| min_instances    | Minimum number of connector instances        | `number` | `2`             | no       |
| max_instances    | Maximum number of connector instances        | `number` | `3`             | no       |

## Outputs

| Name                | Description                           |
| ------------------- | ------------------------------------- |
| connector_id        | ID of the VPC Access Connector        |
| connector_name      | Name of the VPC Access Connector      |
| connector_self_link | Self-link of the VPC Access Connector |

## IP Range Requirements

- Must use a /28 CIDR block (16 IP addresses)
- Must not overlap with existing subnets
- Common ranges:
  - `10.8.0.0/28` (10.8.0.0 - 10.8.0.15)
  - `10.8.1.0/28` (10.8.1.0 - 10.8.1.15)
  - `10.8.2.0/28` (10.8.2.0 - 10.8.2.15)

## Cost

- VPC Connector: ~$10-15/month (fixed cost for min_instances)
- Additional per-GB data transfer charges apply

## Notes

- Creates a dedicated subnet for the connector
- Uses e2-micro instances for cost efficiency
- Minimum 2 instances for redundancy
- Maximum 3 instances to control costs
- Requires `vpcaccess.googleapis.com` API to be enabled
- Connector takes 3-5 minutes to provision

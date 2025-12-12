# VPC Network Module

Creates a VPC network with private IP peering for Cloud SQL.

## Features

- ✅ Custom VPC network (no auto-created subnets)
- ✅ Private IP range allocation for Cloud SQL
- ✅ Service networking connection for private access

## Usage

```hcl
module "vpc_network" {
  source = "git::https://github.com/veridianlab/project-fox-infra.git//modules/vpc-network?ref=v1.1.0"

  project_id   = "project-fox-staging"
  network_name = "project-fox-vpc-staging"
  environment  = "staging"
}
```

## Inputs

| Name         | Description                           | Type     | Required |
| ------------ | ------------------------------------- | -------- | -------- |
| project_id   | GCP Project ID                        | `string` | yes      |
| network_name | Name of the VPC network               | `string` | yes      |
| environment  | Environment name (staging/production) | `string` | yes      |

## Outputs

| Name                   | Description                                    |
| ---------------------- | ---------------------------------------------- |
| network_id             | The ID of the VPC network                      |
| network_name           | The name of the VPC network                    |
| network_self_link      | The self-link of the VPC network               |
| private_ip_range_name  | Name of the private IP range for Cloud SQL     |
| private_vpc_connection | The private VPC connection for dependency mgmt |

## Notes

- Private IP range uses /16 (65,536 addresses)
- Service networking connection enables Cloud SQL private IP access
- Required APIs: `compute.googleapis.com`, `servicenetworking.googleapis.com`

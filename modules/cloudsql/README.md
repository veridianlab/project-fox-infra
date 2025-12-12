# Cloud SQL Module

Creates a PostgreSQL Cloud SQL instance with private IP access and automated backups.

## Features

- ✅ PostgreSQL 15
- ✅ Private IP only (no public IP)
- ✅ Automated backups with point-in-time recovery
- ✅ Configurable machine tier and disk size
- ✅ High availability option for production
- ✅ Query insights support
- ✅ Maintenance window configuration
- ✅ SSL enforcement option

## Usage

### Staging Example (Small Instance)

```hcl
module "cloudsql_staging" {
  source = "git::https://github.com/veridianlab/project-fox-infra.git//modules/cloudsql?ref=v1.1.0"

  project_id    = "project-fox-staging"
  region        = "asia-southeast1"
  instance_name = "lynx-haven-staging"
  database_name = "lynx_haven"

  tier              = "db-f1-micro"
  availability_type = "ZONAL"
  disk_size         = 10

  vpc_network_self_link     = module.vpc_network.network_self_link
  vpc_connection_dependency = module.vpc_network.private_vpc_connection

  db_user     = "root"
  db_password = var.db_password

  deletion_protection = false
}
```

### Production Example (HA Instance)

```hcl
module "cloudsql_production" {
  source = "git::https://github.com/veridianlab/project-fox-infra.git//modules/cloudsql?ref=v1.1.0"

  project_id    = "project-fox-production"
  region        = "asia-southeast1"
  instance_name = "lynx-haven-production"
  database_name = "lynx_haven"

  tier              = "db-custom-2-7680"  # 2 vCPU, 7.5GB RAM
  availability_type = "REGIONAL"          # High Availability
  disk_size         = 50

  vpc_network_self_link     = module.vpc_network.network_self_link
  vpc_connection_dependency = module.vpc_network.private_vpc_connection

  db_user     = "root"
  db_password = var.db_password

  require_ssl            = true
  deletion_protection    = true
  query_insights_enabled = true
}
```

## Inputs

| Name                           | Description                           | Type     | Default         | Required |
| ------------------------------ | ------------------------------------- | -------- | --------------- | -------- |
| project_id                     | GCP Project ID                        | `string` | n/a             | yes      |
| region                         | GCP Region                            | `string` | n/a             | yes      |
| instance_name                  | Cloud SQL instance name               | `string` | n/a             | yes      |
| database_name                  | Name of the database to create        | `string` | n/a             | yes      |
| database_version               | PostgreSQL version                    | `string` | `"POSTGRES_15"` | no       |
| tier                           | Machine tier                          | `string` | `"db-f1-micro"` | no       |
| availability_type              | Availability type (ZONAL or REGIONAL) | `string` | `"ZONAL"`       | no       |
| disk_size                      | Disk size in GB                       | `number` | `10`            | no       |
| disk_type                      | Disk type (PD_SSD or PD_HDD)          | `string` | `"PD_SSD"`      | no       |
| vpc_network_self_link          | Self-link of the VPC network          | `string` | n/a             | yes      |
| vpc_connection_dependency      | VPC connection dependency             | `any`    | `null`          | no       |
| db_user                        | Database user name                    | `string` | `"root"`        | no       |
| db_password                    | Database user password                | `string` | n/a             | yes      |
| deletion_protection            | Enable deletion protection            | `bool`   | `true`          | no       |
| backup_enabled                 | Enable automated backups              | `bool`   | `true`          | no       |
| backup_start_time              | Backup start time (HH:MM)             | `string` | `"03:00"`       | no       |
| point_in_time_recovery_enabled | Enable point-in-time recovery         | `bool`   | `true`          | no       |
| transaction_log_retention_days | Transaction log retention days        | `number` | `7`             | no       |
| retained_backups               | Number of backups to retain           | `number` | `7`             | no       |
| require_ssl                    | Require SSL for connections           | `bool`   | `false`         | no       |
| max_connections                | Maximum number of connections         | `string` | `"100"`         | no       |
| query_insights_enabled         | Enable query insights                 | `bool`   | `false`         | no       |

## Outputs

| Name                     | Description                         |
| ------------------------ | ----------------------------------- |
| instance_name            | Name of the Cloud SQL instance      |
| instance_connection_name | Connection name for Cloud SQL Proxy |
| private_ip_address       | Private IP address of the instance  |
| database_name            | Name of the created database        |
| db_user                  | Database user name                  |

## Machine Tiers

### Staging (Cost-Effective)

- `db-f1-micro`: 0.6 GB RAM, shared CPU (~$10/month)
- `db-g1-small`: 1.7 GB RAM, shared CPU (~$25/month)

### Production (Performance)

- `db-custom-1-3840`: 1 vCPU, 3.75 GB RAM (~$50/month)
- `db-custom-2-7680`: 2 vCPU, 7.5 GB RAM (~$100/month)
- `db-custom-4-15360`: 4 vCPU, 15 GB RAM (~$200/month)

Add `REGIONAL` availability for HA: ~2x cost

## Connection String Format

```text
postgresql://root:PASSWORD@PRIVATE_IP:5432/lynx_haven?sslmode=disable
```

For Go applications:

```go
connectionString := fmt.Sprintf(
    "host=%s port=5432 user=root password=%s dbname=lynx_haven sslmode=disable",
    os.Getenv("DB_HOST"),
    os.Getenv("DB_PASSWORD"),
)
```

## Notes

- Instance name gets a random suffix to allow recreation
- Private IP only - no public internet access
- Automatic disk resize enabled
- Backups run at 3 AM by default
- 7-day transaction log retention for point-in-time recovery
- Requires `sqladmin.googleapis.com` API to be enabled

# Cloud Run Module

This Terraform module provisions a Google Cloud Run service with configurable resources, scaling, environment variables, VPC access, and secret management.

## Features

- ✅ Google Cloud Run v2 service deployment
- ✅ Configurable CPU and memory limits
- ✅ Auto-scaling with min/max instance settings
- ✅ Environment variable support
- ✅ Secret Manager integration
- ✅ VPC connector support for private networking
- ✅ Custom service account support
- ✅ Public access IAM configuration
- ✅ Environment-based labeling

## Usage

### Basic Example

```hcl
module "cloud_run_service" {
  source = "git::https://github.com/veridianlab/project-fox-infra.git//modules/cloudrun?ref=v1.1.0"

  project_id   = "my-gcp-project"
  region       = "asia-southeast1"
  service_name = "my-service"
  environment  = "production"
  image        = "gcr.io/my-project/my-image:latest"
}
```

### Frontend Application Example

```hcl
module "frontend" {
  source = "git::https://github.com/veridianlab/project-fox-infra.git//modules/cloudrun?ref=v1.1.0"

  project_id   = "project-fox-production"
  region       = "asia-southeast1"
  service_name = "frontend-production"
  environment  = "production"
  
  image        = "gcr.io/project-fox-production/frontend:v1.2.3"
  port         = 3000"
  
  cpu_limit    = "2"
  memory_limit = "1Gi"
  
  min_instances = 1
  max_instances = 100
  
  env_vars = {
    NODE_ENV = "production"
    API_URL  = "https://api.example.com"
  }
}

output "frontend_url" {
  value = module.frontend.service_url
}
```

### Backend API Example with VPC and Secrets

```hcl
module "backend_api" {
  source = "git::https://github.com/veridianlab/project-fox-infra.git//modules/cloudrun?ref=v1.1.0"

  project_id   = "project-fox-production"
  region       = "asia-southeast1"
  service_name = "lynx-haven-api"
  environment  = "production"
  
  image        = "gcr.io/project-fox-production/lynx-haven:v2.1.0"
  port         = 8080
  
  cpu_limit    = "2"
  memory_limit = "2Gi"
  
  min_instances = 2
  max_instances = 50
  
  # VPC Access for Cloud SQL
  vpc_connector_name = module.vpc_connector.connector_id
  vpc_egress         = "private-ranges-only"
  
  # Service account for Secret Manager access
  service_account_email = module.service_account.email
  
  # Environment variables
  env_vars = {
    GIN_MODE = "release"
    DB_HOST  = module.cloudsql.private_ip_address
    DB_PORT  = "5432"
    DB_NAME  = "lynx_haven"
    DB_USER  = "root"
  }
  
  # Secrets from Secret Manager
  secrets = {
    DB_PASSWORD = {
      secret_name = module.db_password_secret.secret_name
      version     = "latest"
    }
    API_KEY = {
      secret_name = "api-key-production"
      version     = "1"
    }
  }
}

output "api_url" {
  value = module.backend_api.service_url
}
```

## Requirements

| Name      | Version |
| --------- | ------- |
| terraform | >= 1.0  |
| google    | >= 5.0  |

## Providers

| Name   | Version |
| ------ | ------- |
| google | >= 5.0  |

## Inputs

| Name                  | Description                                       | Type                                      | Default                | Required |
| --------------------- | ------------------------------------------------- | ----------------------------------------- | ---------------------- | :------: |
| project_id            | GCP Project ID                                    | `string`                                  | n/a                    |   yes    |
| region                | GCP Region                                        | `string`                                  | n/a                    |   yes    |
| service_name          | Cloud Run service name                            | `string`                                  | n/a                    |   yes    |
| environment           | Environment name (staging/production)             | `string`                                  | n/a                    |   yes    |
| image                 | Container image URL                               | `string`                                  | n/a                    |   yes    |
| port                  | Container port                                    | `number`                                  | `3000`                 |    no    |
| cpu_limit             | CPU limit for the container                       | `string`                                  | `"1"`                  |    no    |
| memory_limit          | Memory limit for the container                    | `string`                                  | `"512Mi"`              |    no    |
| min_instances         | Minimum number of instances                       | `number`                                  | `1`                    |    no    |
| max_instances         | Maximum number of instances                       | `number`                                  | `10`                   |    no    |
| env_vars              | Environment variables                             | `map(string)`                             | `{}`                   |    no    |
| secrets               | Secret environment variables from Secret Manager  | `map(object({secret_name, version}))`     | `{}`                   |    no    |
| vpc_connector_name    | VPC Access Connector name for private network     | `string`                                  | `null`                 |    no    |
| vpc_egress            | VPC egress setting (all-traffic or private-ranges)| `string`                                  | `"private-ranges-only"`|    no    |
| service_account_email | Service account email for the Cloud Run service   | `string`                                  | `null`                 |    no    |

## Outputs

| Name             | Description                       |
| ---------------- | --------------------------------- |
| service_url      | URL of the Cloud Run service      |
| service_name     | Name of the Cloud Run service     |
| service_id       | ID of the Cloud Run service       |
| service_location | Location of the Cloud Run service |

## Resource Limits

### CPU Limits

- Format: String representing number of CPUs
- Examples: `"1"`, `"2"`, `"4"`
- Range: 0.08 to 8 CPUs

### Memory Limits

- Format: String with unit (Mi or Gi)
- Examples: `"512Mi"`, `"1Gi"`, `"2Gi"`
- Range: 128Mi to 32Gi

### Scaling

- **min_instances**: Minimum number of container instances to keep running
  - Set to `0` to scale to zero when no traffic
  - Set to `1+` for always-on instances (reduces cold start)
- **max_instances**: Maximum number of instances to scale up to
  - Prevents runaway costs
  - Should account for expected traffic patterns

## Notes

- This module configures public access (`allUsers` has `roles/run.invoker`)
- Services are labeled with `environment` and `managed-by=terraform`
- Traffic is always routed 100% to the latest revision
- Requires the Cloud Run API to be enabled in your GCP project

## Versioning

This module follows semantic versioning. Always use a specific version reference in production:

```hcl
source = "git::https://github.com/veridianlab/project-fox-infra.git//modules/cloudrun?ref=v1.0.0"
```

See the [VERSIONING.md](../../VERSIONING.md) file for details on version management and git tagging.

## License

MIT

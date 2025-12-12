# Migration Guide: Using Shared Infrastructure Modules

This guide explains how to update your existing Terraform configurations to use the shared modules from `project-fox-infra`.

## Frontend (d-dollar-allocation-fe)

### Before: Local Module Reference

```hcl
module "cloud_run" {
  source = "../../modules/cloud-run"  # Local path

  # ... variables
}
```

### After: Shared Module Reference

```hcl
module "cloud_run" {
  source = "git::https://github.com/veridianlab/project-fox-infra.git//modules/cloudrun?ref=v1.0.0"

  # ... same variables
}
```

### Step-by-Step Migration

#### 1. Update Staging Environment

File: `d-dollar-allocation-fe/terraform/environments/staging/main.tf`

**Change this:**

```hcl
module "cloud_run" {
  source = "../../modules/cloud-run"
```

**To this:**

```hcl
module "cloud_run" {
  source = "git::https://github.com/veridianlab/project-fox-infra.git//modules/cloudrun?ref=v1.0.0"
```

#### 2. Update Production Environment

File: `d-dollar-allocation-fe/terraform/environments/production/main.tf`

Make the same change as in staging.

#### 3. Re-initialize Terraform

```bash
cd d-dollar-allocation-fe/terraform/environments/staging
terraform init -upgrade

cd ../production
terraform init -upgrade
```

#### 4. Verify No Changes

Since the module code is identical, there should be no infrastructure changes:

```bash
cd d-dollar-allocation-fe/terraform/environments/staging
terraform plan
# Should show: No changes. Your infrastructure matches the configuration.
```

#### 5. (Optional) Remove Local Module

After confirming everything works, you can optionally remove the local module:

```bash
cd d-dollar-allocation-fe/terraform
rm -rf modules/cloud-run/
```

Update `.gitignore` or commit the deletion:

```bash
git rm -r modules/cloud-run/
git commit -m "refactor: migrate to shared cloud-run module from project-fox-infra"
```

## Backend (lynx-haven)

When you're ready to add Cloud Run deployment to lynx-haven:

### Create Terraform Configuration

```bash
cd lynx-haven
mkdir -p terraform/environments/staging
cd terraform/environments/staging
```

### Create main.tf

```hcl
terraform {
  required_version = ">= 1.0"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
  }

  backend "gcs" {
    bucket = "project-fox-staging-tfstate"
    prefix = "terraform/state/backend"
  }
}

provider "google" {
  project = var.project_id
  region  = var.region
}

module "backend_api" {
  source = "git::https://github.com/veridianlab/project-fox-infra.git//modules/cloudrun?ref=v1.0.0"

  project_id   = var.project_id
  region       = var.region
  service_name = var.service_name
  environment  = var.environment

  # Container configuration
  image        = var.image
  port         = 8080  # lynx-haven uses port 8080

  # Resource limits (backend needs more resources)
  cpu_limit    = "2"
  memory_limit = "2Gi"

  # Scaling configuration
  min_instances = var.min_instances
  max_instances = var.max_instances

  # Environment variables
  env_vars = var.env_vars
}
```

### Create variables.tf

```hcl
variable "project_id" {
  description = "GCP Project ID"
  type        = string
}

variable "region" {
  description = "GCP Region"
  type        = string
  default     = "asia-southeast1"
}

variable "service_name" {
  description = "Cloud Run service name"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "image" {
  description = "Container image URL"
  type        = string
}

variable "min_instances" {
  description = "Minimum number of instances"
  type        = number
  default     = 1
}

variable "max_instances" {
  description = "Maximum number of instances"
  type        = number
  default     = 20
}

variable "env_vars" {
  description = "Environment variables"
  type        = map(string)
  default     = {}
}
```

### Create terraform.tfvars

```hcl
project_id   = "project-fox-staging"
service_name = "lynx-haven-staging"
environment  = "staging"
image        = "gcr.io/project-fox-staging/lynx-haven:latest"

min_instances = 1
max_instances = 20

env_vars = {
  GIN_MODE        = "release"
  DATABASE_URL    = "postgresql://user:pass@host:5432/dbname"
  REDIS_URL       = "redis://host:6379"
  JWT_SECRET      = "your-secret-here"
  CASBIN_MODEL    = "/app/configs/casbin_model.conf"
  CASBIN_POLICY   = "/app/configs/casbin_policy.csv"
}
```

### Create outputs.tf

```hcl
output "service_url" {
  description = "URL of the Cloud Run service"
  value       = module.backend_api.service_url
}

output "service_name" {
  description = "Name of the Cloud Run service"
  value       = module.backend_api.service_name
}
```

## Benefits of Shared Modules

### Consistency

✅ Both frontend and backend use the exact same Cloud Run configuration
✅ Same best practices applied across all services
✅ Easier to maintain and update

### Centralized Updates

When you improve the module (e.g., add VPC connector support):

1. Update the module in `project-fox-infra`
2. Create a new version tag (e.g., v1.1.0)
3. Both projects can upgrade by changing `ref=v1.0.0` to `ref=v1.1.0`

### Version Control

Different environments can use different module versions:

```hcl
# Staging uses latest
source = "...?ref=v1.1.0"

# Production uses stable
source = "...?ref=v1.0.0"
```

## Troubleshooting

### Module not found error

```text
Error: Failed to download module
```

**Solution**: Check your Git authentication and network connection:

```bash
git ls-remote https://github.com/veridianlab/project-fox-infra.git
```

### "No changes" not showing after migration

If Terraform shows changes after migrating to the shared module, it likely means the module code differs slightly.

**Solution**: Use `terraform state mv` to preserve state:

```bash
# This should not be necessary if module code is identical
terraform state mv module.cloud_run module.cloud_run
```

### Private repository authentication

For private repositories, use SSH:

```hcl
source = "git::ssh://git@github.com/veridianlab/project-fox-infra.git//modules/cloudrun?ref=v1.0.0"
```

Or configure HTTPS with credentials:

```bash
git config --global credential.helper store
```

## Recommended Workflow

1. ✅ Push `project-fox-infra` to GitHub
2. ✅ Create v1.0.0 release
3. ✅ Update frontend staging to use shared module
4. ✅ Test frontend staging deployment
5. ✅ Update frontend production
6. ✅ Test frontend production deployment
7. ✅ Create backend (lynx-haven) Terraform config
8. ✅ Deploy backend staging
9. ✅ Deploy backend production

## Questions?

See:

- [QUICKSTART.md](QUICKSTART.md) - Initial setup guide
- [VERSIONING.md](VERSIONING.md) - Version management
- [modules/cloudrun/README.md](modules/cloudrun/README.md) - Module documentation

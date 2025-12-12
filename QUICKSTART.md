# Quick Start Guide

This guide will help you set up the `project-fox-infra` repository on GitHub and start using it in your projects.

## Initial Setup

### 1. Initialize Git Repository (if not already done)

```bash
cd /Users/ganshenghong/Documents/repo/project-fox/project-fox-infra
git init
git add .
git commit -m "Initial commit: Add Cloud Run module and documentation"
```

### 2. Create GitHub Repository

Create a new repository on GitHub:

- Go to <https://github.com/veridianlab> (or your organization)
- Click "New repository"
- Repository name: `project-fox-infra`
- Description: "Shared Terraform infrastructure modules for Project Fox"
- Make it **Private** (recommended) or Public based on your needs
- Don't initialize with README, .gitignore, or license (we already have these)

### 3. Push to GitHub

```bash
# Add GitHub remote (replace with your actual GitHub URL)
git remote add origin https://github.com/veridianlab/project-fox-infra.git

# Push to main branch
git branch -M main
git push -u origin main
```

### 4. Create Initial Release

```bash
# Create and push the first version tag
git tag -a v1.0.0 -m "Initial release: Cloud Run module"
git push origin v1.0.0
```

### 5. Create GitHub Release (Optional)

Go to `https://github.com/veridianlab/project-fox-infra/releases/new` and create a release for `v1.0.0`.

## Using in Your Frontend Project

### Update d-dollar-allocation-fe

Navigate to your frontend project's Terraform configuration:

```bash
cd /Users/ganshenghong/Documents/repo/project-fox/d-dollar-allocation-fe/terraform/environments/staging
```

Edit `main.tf` to use the shared module:

```hcl
terraform {
  required_version = ">= 1.0"

  backend "gcs" {
    bucket = "project-fox-staging-tfstate"
    prefix = "terraform/state"
  }

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
  }
}

provider "google" {
  project = var.project_id
  region  = var.region
}

module "frontend" {
  source = "git::https://github.com/veridianlab/project-fox-infra.git//modules/cloudrun?ref=v1.0.0"

  project_id    = var.project_id
  region        = var.region
  service_name  = var.service_name
  environment   = var.environment
  image         = var.image
  port          = var.port
  cpu_limit     = var.cpu_limit
  memory_limit  = var.memory_limit
  min_instances = var.min_instances
  max_instances = var.max_instances
  env_vars      = var.env_vars
}

output "service_url" {
  value = module.frontend.service_url
}
```

Then re-initialize:

```bash
terraform init -upgrade
terraform plan
```

## Using in Your Backend Project (lynx-haven)

When you're ready to deploy lynx-haven with Cloud Run, create a similar Terraform configuration:

```bash
cd /Users/ganshenghong/Documents/repo/project-fox/lynx-haven
mkdir -p terraform/environments/staging
cd terraform/environments/staging
```

Create `main.tf`:

```hcl
module "backend_api" {
  source = "git::https://github.com/veridianlab/project-fox-infra.git//modules/cloudrun?ref=v1.0.0"

  project_id   = "project-fox-staging"
  region       = "asia-southeast1"
  service_name = "lynx-haven-staging"
  environment  = "staging"

  image        = "gcr.io/project-fox-staging/lynx-haven:latest"
  port         = 8080

  cpu_limit    = "2"
  memory_limit = "1Gi"

  min_instances = 1
  max_instances = 10

  env_vars = {
    GIN_MODE     = "release"
    DATABASE_URL = "your-database-url"
  }
}

output "api_url" {
  value = module.backend_api.service_url
}
```

## Authentication for Private Repositories

If your repository is private, configure Git authentication:

### Option 1: SSH (Recommended)

```hcl
module "cloud_run" {
  source = "git::ssh://git@github.com/veridianlab/project-fox-infra.git//modules/cloudrun?ref=v1.0.0"
  # ...
}
```

Make sure your SSH key is added to GitHub.

### Option 2: HTTPS with Personal Access Token

Create a Personal Access Token on GitHub and configure Git credentials:

```bash
git config --global credential.helper store
```

### Option 3: In CI/CD (GitHub Actions)

```yaml
- name: Configure Git for private modules
  run: |
    git config --global url."https://x-access-token:${{ secrets.GITHUB_TOKEN }}@github.com/".insteadOf "https://github.com/"
```

## Updating the Module

When you make changes to the module:

```bash
cd /Users/ganshenghong/Documents/repo/project-fox/project-fox-infra

# Make your changes
git add .
git commit -m "feat: add VPC connector support"
git push origin main

# Create new version tag
git tag -a v1.1.0 -m "Add VPC connector support"
git push origin v1.1.0
```

Then update your projects to use the new version:

```hcl
# Change from v1.0.0 to v1.1.0
source = "git::https://github.com/veridianlab/project-fox-infra.git//modules/cloudrun?ref=v1.1.0"
```

## Troubleshooting

### "Error installing provider" or module not found

```bash
# Clear Terraform cache and re-initialize
rm -rf .terraform .terraform.lock.hcl
terraform init
```

### Authentication errors

```bash
# Test Git access
git ls-remote https://github.com/veridianlab/project-fox-infra.git
```

### Module version not updating

```bash
# Force upgrade
terraform init -upgrade
```

## Next Steps

1. ✅ Push this repository to GitHub
2. ✅ Create the v1.0.0 release
3. ✅ Update d-dollar-allocation-fe to use the shared module
4. ✅ Test the deployment
5. ⏭️ When ready, set up lynx-haven to use the same module

For more details, see:

- [README.md](README.md) - Repository overview
- [VERSIONING.md](VERSIONING.md) - Version management guide
- [modules/cloudrun/README.md](modules/cloudrun/README.md) - Cloud Run module documentation

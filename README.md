# Project Fox Infrastructure Modules

Shared Terraform infrastructure modules for Project Fox services.

## Overview

This repository contains reusable Terraform modules that are shared across multiple Project Fox services:

- **d-dollar-allocation-fe** - Frontend application
- **lynx-haven** - Backend API service

By centralizing infrastructure modules, we ensure consistency, reduce duplication, and simplify maintenance across all services.

## Available Modules

### Cloud Run Module

A production-ready module for deploying containerized applications to Google Cloud Run.

📁 **Path**: `modules/cloudrun`  
📖 **Documentation**: [modules/cloudrun/README.md](modules/cloudrun/README.md)

**Features**:

- Google Cloud Run v2 service deployment
- Configurable CPU and memory limits
- Auto-scaling configuration
- Environment variable support
- Public access IAM setup
- Environment-based labeling

**Quick Example**:

```hcl
module "my_service" {
  source = "git::https://github.com/veridianlab/project-fox-infra.git//modules/cloudrun?ref=v1.0.0"

  project_id   = "my-gcp-project"
  region       = "asia-southeast1"
  service_name = "my-service"
  environment  = "production"
  image        = "gcr.io/my-project/my-image:latest"
}
```

## Usage

### 1. Reference Modules in Your Terraform Configuration

Use the Git source with a specific version tag:

```hcl
module "cloud_run_service" {
  source = "git::https://github.com/veridianlab/project-fox-infra.git//modules/cloudrun?ref=v1.0.0"

  # Module variables...
}
```

### 2. Version Pinning

**Always** use a specific version reference in production environments:

✅ **Good** - Uses specific version:

```hcl
source = "git::https://github.com/veridianlab/project-fox-infra.git//modules/cloudrun?ref=v1.0.0"
```

❌ **Bad** - Uses branch (unpredictable):

```hcl
source = "git::https://github.com/veridianlab/project-fox-infra.git//modules/cloudrun?ref=main"
```

### 3. Update Module Versions

When a new module version is released:

```bash
# Update the ref parameter in your module source
source = "git::https://github.com/veridianlab/project-fox-infra.git//modules/cloudrun?ref=v1.1.0"

# Re-initialize Terraform
terraform init -upgrade
```

## Repository Structure

```text
project-fox-infra/
├── README.md              # This file
├── VERSIONING.md          # Version management guide
└── modules/
    └── cloudrun/          # Cloud Run module
        ├── main.tf
        ├── variables.tf
        ├── outputs.tf
        └── README.md
```

## Contributing

### Adding a New Module

1. Create a new directory under `modules/`
2. Add Terraform files (`main.tf`, `variables.tf`, `outputs.tf`)
3. Create a comprehensive `README.md` with usage examples
4. Test the module thoroughly
5. Submit a pull request

### Module Best Practices

- ✅ Use clear, descriptive variable names
- ✅ Provide sensible defaults where appropriate
- ✅ Document all inputs and outputs
- ✅ Include usage examples in README
- ✅ Follow Terraform best practices
- ✅ Add validation rules for critical variables
- ✅ Use consistent naming conventions

## Versioning

This repository follows [Semantic Versioning](https://semver.org/):

- **MAJOR** version (v2.0.0) - Breaking changes
- **MINOR** version (v1.1.0) - New features, backward compatible
- **PATCH** version (v1.0.1) - Bug fixes, backward compatible

See [VERSIONING.md](VERSIONING.md) for detailed versioning guidelines and git tag management.

## Support

For issues or questions:

1. Check the module-specific README documentation
2. Review existing [GitHub Issues](https://github.com/veridianlab/project-fox-infra/issues)
3. Create a new issue with detailed information

## License

MIT

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
- Secret Manager integration
- VPC connector support
- Custom service account
- Public access IAM setup

**Quick Example**:

```hcl
module "my_service" {
  source = "git::https://github.com/veridianlab/project-fox-infra.git//modules/cloudrun?ref=v1.1.0"

  project_id   = "my-gcp-project"
  region       = "asia-southeast1"
  service_name = "my-service"
  environment  = "production"
  image        = "gcr.io/my-project/my-image:latest"
}
```

### Cloud SQL Module

PostgreSQL database with private IP access and automated backups.

📁 **Path**: `modules/cloudsql`  
📖 **Documentation**: [modules/cloudsql/README.md](modules/cloudsql/README.md)

**Features**:

- PostgreSQL 15
- Private IP only (no public access)
- Automated backups with point-in-time recovery
- High availability option
- Query insights

**Quick Example**:

```hcl
module "database" {
  source = "git::https://github.com/veridianlab/project-fox-infra.git//modules/cloudsql?ref=v1.1.0"

  project_id    = "my-gcp-project"
  region        = "asia-southeast1"
  instance_name = "my-database"
  database_name = "myapp"

  vpc_network_self_link = module.vpc_network.network_self_link
  db_password           = var.db_password
}
```

### VPC Network Module

VPC network with private IP peering for Cloud SQL.

📁 **Path**: `modules/vpc-network`  
📖 **Documentation**: [modules/vpc-network/README.md](modules/vpc-network/README.md)

**Features**:

- Custom VPC network
- Private IP range allocation
- Service networking connection

**Quick Example**:

```hcl
module "vpc_network" {
  source = "git::https://github.com/veridianlab/project-fox-infra.git//modules/vpc-network?ref=v1.1.0"

  project_id   = "my-gcp-project"
  network_name = "my-vpc"
  environment  = "production"
}
```

### Cloud NAT Module

Cloud NAT with static external IP for consistent egress traffic from Cloud Run.

📁 **Path**: `modules/cloud-nat`  
📖 **Documentation**: [modules/cloud-nat/README.md](modules/cloud-nat/README.md)

**Features**:

- Static external IP address reservation
- Cloud Router configuration
- Cloud NAT gateway setup
- Configurable logging and port allocation
- Perfect for third-party API IP allowlisting

**Quick Example**:

```hcl
module "cloud_nat" {
  source = "git::https://github.com/veridianlab/project-fox-infra.git//modules/cloud-nat?ref=v1.1.0"

  project_id       = "my-gcp-project"
  region           = "asia-southeast1"
  nat_name         = "my-nat"
  vpc_network_name = module.vpc_network.network_name
}

# Output the static IP for allowlisting
output "nat_ip" {
  value = module.cloud_nat.nat_ip_address
}
```

**Use Case**: When your Cloud Run service calls third-party APIs that require IP allowlisting, this module provides a consistent static IP for all egress traffic.

### Load Balancer + Cloud Armor Module

Global external HTTPS Load Balancer with Cloud Armor for IP allowlisting in front of a Cloud Run service.

📁 **Path**: `modules/lb-cloud-armor`  
📖 **Documentation**: [modules/lb-cloud-armor/README.md](modules/lb-cloud-armor/README.md)

**Features**:

- Global external HTTPS LB with reserved static IPv4
- Serverless NEG to Cloud Run
- Cloud Armor policy: default deny 403, allowlist for hotel / VPN / office IPs
- Google-managed SSL cert (multi-domain)
- Backend service request logging

**Quick Example**:

```hcl
module "api_lb" {
  source = "git::https://github.com/veridianlab/project-fox-infra.git//modules/lb-cloud-armor?ref=v1.1.4"

  project_id  = "my-gcp-project"
  region      = "asia-southeast1"
  lb_name     = "api-lb"
  environment = "production"

  cloudrun_service_name     = module.backend_service.service_name
  cloudrun_service_location = module.backend_service.service_location

  domains           = ["api.example.com"]
  allowed_ip_ranges = ["203.0.113.10/32", "198.51.100.0/24"]
}
```

**Use Case**: Restrict access to an internal/staging Cloud Run service to known office, hotel, or VPN IP ranges. Pair with `ingress = "INGRESS_TRAFFIC_INTERNAL_LOAD_BALANCER"` on the cloudrun module so the `*.run.app` URL can't bypass the allowlist.

### VPC Connector Module

Serverless VPC Access connector for Cloud Run.

📁 **Path**: `modules/vpc-connector`  
📖 **Documentation**: [modules/vpc-connector/README.md](modules/vpc-connector/README.md)

**Features**:

- Serverless VPC Access connector
- Dedicated subnet
- Configurable scaling

**Quick Example**:

```hcl
module "vpc_connector" {
  source = "git::https://github.com/veridianlab/project-fox-infra.git//modules/vpc-connector?ref=v1.1.0"

  project_id       = "my-gcp-project"
  region           = "asia-southeast1"
  connector_name   = "my-connector"
  vpc_network_name = module.vpc_network.network_name
}
```

### Secret Manager Module

Secure secret storage with IAM bindings.

📁 **Path**: `modules/secret-manager`  
📖 **Documentation**: [modules/secret-manager/README.md](modules/secret-manager/README.md)

**Features**:

- Secret creation and versioning
- Automatic replication
- IAM access control

**Quick Example**:

```hcl
module "db_password" {
  source = "git::https://github.com/veridianlab/project-fox-infra.git//modules/secret-manager?ref=v1.1.0"

  project_id   = "my-gcp-project"
  secret_id    = "database-password"
  secret_value = var.db_password
  environment  = "production"

  accessor_service_accounts = [
    "my-service@my-gcp-project.iam.gserviceaccount.com"
  ]
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
source = "git::https://github.com/veridianlab/project-fox-infra.git//modules/cloudrun?ref=v1.1.0"
```

❌ **Bad** - Uses branch (unpredictable):

```hcl
source = "git::https://github.com/veridianlab/project-fox-infra.git//modules/cloudrun?ref=main"
```

### 3. Update Module Versions

When a new module version is released:

```bash
# Update the ref parameter in your module source
source = "git::https://github.com/veridianlab/project-fox-infra.git//modules/cloudrun?ref=v1.2.0"

# Re-initialize Terraform
terraform init -upgrade
```

## Complete Backend Example

For a complete backend infrastructure setup with database, networking, and secrets, see:

📁 **[examples/backend-complete](examples/backend-complete/)**

This example includes:

- VPC Network
- Cloud SQL PostgreSQL
- VPC Connector
- Cloud NAT with Static IP (for third-party API calls)
- Secret Manager
- Cloud Run service

Perfect starting point for deploying the lynx-haven backend!

**Note**: For static IP egress (required when calling third-party APIs that need IP allowlisting), see the [STATIC_IP_SETUP.md](STATIC_IP_SETUP.md) guide.

## Repository Structure

```text
project-fox-infra/
├── README.md              # This file
├── CLOUD_NAT_CHANGES.md   # Cloud NAT implementation summary
├── STATIC_IP_SETUP.md     # Static IP setup guide
├── modules/
│   ├── cloudrun/          # Cloud Run service module
│   ├── cloudsql/          # Cloud SQL PostgreSQL module
│   ├── cloud-nat/         # Cloud NAT with static IP module
│   ├── lb-cloud-armor/    # Global HTTPS LB + Cloud Armor IP allowlisting
│   ├── vpc-network/       # VPC network with private IP peering
│   ├── vpc-connector/     # Serverless VPC Access connector
│   └── secret-manager/    # Secret Manager module
└── examples/
    └── backend-complete/  # Complete backend infrastructure example
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

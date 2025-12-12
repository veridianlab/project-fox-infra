# Complete Backend Infrastructure Example

This example demonstrates how to set up a complete backend infrastructure with:

- VPC Network
- Cloud SQL PostgreSQL
- VPC Connector  
- Secret Manager
- Cloud Run service

## Prerequisites

1. GCP Project created
2. Required APIs enabled:
   - Cloud Run API (`run.googleapis.com`)
   - Cloud SQL Admin API (`sqladmin.googleapis.com`)
   - Serverless VPC Access API (`vpcaccess.googleapis.com`)
   - Secret Manager API (`secretmanager.googleapis.com`)
   - Compute Engine API (`compute.googleapis.com`)
   - Service Networking API (`servicenetworking.googleapis.com`)

3. GCS bucket for Terraform state

## Usage

### 1. Copy Files to Your Project

```bash
cd /path/to/your/lynx-haven/terraform/environments/staging
cp -r /path/to/project-fox-infra/examples/backend-complete/* .
```

### 2. Customize `terraform.tfvars`

```hcl
project_id    = "project-fox-staging"
region        = "asia-southeast1"
backend_image = "gcr.io/project-fox-staging/lynx-haven:latest"
```

### 3. Initialize and Deploy

```bash
terraform init
terraform plan
terraform apply
```

### 4. Get Outputs

```bash
terraform output backend_url
terraform output database_connection_name
```

## Architecture

```text
┌─────────────────────────────────────┐
│         Cloud Run Service           │
│         (lynx-haven API)            │
│                                     │
│  - Reads DB_PASSWORD from Secret   │
│  - Connects via VPC Connector      │
└──────────────┬──────────────────────┘
               │
               ├──────────────────┐
               │                  │
               ▼                  ▼
┌──────────────────────┐  ┌─────────────────┐
│   Secret Manager     │  │  VPC Connector  │
│                      │  │                 │
│  - DB Password       │  │  - Private IP   │
│  - API Keys          │  │    10.8.0.0/28  │
└──────────────────────┘  └────────┬────────┘
                                   │
                          ┌────────▼────────┐
                          │   VPC Network   │
                          │                 │
                          │  Private Peering│
                          └────────┬────────┘
                                   │
                          ┌────────▼────────┐
                          │   Cloud SQL     │
                          │  (PostgreSQL)   │
                          │                 │
                          │  - Private IP   │
                          │  - Auto Backup  │
                          │  - 10GB Disk    │
                          └─────────────────┘
```

## Cost Estimate

### Staging

- Cloud SQL (db-f1-micro): ~$10/month
- VPC Connector: ~$10/month
- Cloud Run: Pay per use (~$5-20/month)
- **Total**: ~$25-40/month

### Production

- Cloud SQL (db-custom-2-7680, HA): ~$300/month
- VPC Connector: ~$10/month
- Cloud Run: Pay per use (~$50-200/month)
- **Total**: ~$360-510/month

## Files

- `main.tf` - Main infrastructure configuration
- `variables.tf` - Input variables
- `outputs.tf` - Output values
- `terraform.tfvars` - Variable values (customize this)
- `README.md` - This file

terraform {
  required_version = ">= 1.0"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.0"
    }
  }

  backend "gcs" {
    bucket = "project-fox-terraform-state-staging"
    prefix = "lynx-haven/staging"
  }
}

provider "google" {
  project = var.project_id
  region  = var.region
}

# Generate secure database password
resource "random_password" "db_password" {
  length  = 32
  special = true
}

# 1. VPC Network
module "vpc_network" {
  source = "git::https://github.com/veridianlab/project-fox-infra.git//modules/vpc-network?ref=v1.1.0"

  project_id   = var.project_id
  network_name = "project-fox-vpc-${var.environment}"
  environment  = var.environment
}

# 2. Database Password in Secret Manager
module "db_password_secret" {
  source = "git::https://github.com/veridianlab/project-fox-infra.git//modules/secret-manager?ref=v1.1.0"

  project_id   = var.project_id
  secret_id    = "lynx-haven-db-password-${var.environment}"
  secret_value = random_password.db_password.result
  environment  = var.environment

  accessor_service_accounts = [
    "${var.project_id}@appspot.gserviceaccount.com"  # Default App Engine service account
  ]
}

# 3. Cloud SQL PostgreSQL
module "cloudsql" {
  source = "git::https://github.com/veridianlab/project-fox-infra.git//modules/cloudsql?ref=v1.1.0"

  project_id    = var.project_id
  region        = var.region
  instance_name = "lynx-haven-${var.environment}"
  database_name = var.database_name

  # Staging: Small instance
  tier              = var.db_tier
  availability_type = var.db_availability_type
  disk_size         = var.db_disk_size

  # Network
  vpc_network_self_link     = module.vpc_network.network_self_link
  vpc_connection_dependency = module.vpc_network.private_vpc_connection

  # Database credentials
  db_user     = "root"
  db_password = random_password.db_password.result

  # Configurable via variables
  deletion_protection = var.db_deletion_protection
  require_ssl         = var.db_require_ssl

  depends_on = [module.vpc_network]
}

# 4. VPC Connector
module "vpc_connector" {
  source = "git::https://github.com/veridianlab/project-fox-infra.git//modules/vpc-connector?ref=v1.1.0"

  project_id       = var.project_id
  region           = var.region
  connector_name   = "cloudrun-connector-${var.environment}"
  vpc_network_name = module.vpc_network.network_name

  ip_cidr_range = var.vpc_connector_ip_range
  machine_type  = var.vpc_connector_machine_type
  min_instances = var.vpc_connector_min_instances
  max_instances = var.vpc_connector_max_instances

  depends_on = [module.vpc_network]
}

# 5. Cloud Run Backend Service
module "backend_service" {
  source = "git::https://github.com/veridianlab/project-fox-infra.git//modules/cloudrun?ref=v1.1.0"

  project_id   = var.project_id
  region       = var.region
  service_name = "lynx-haven-${var.environment}"
  environment  = var.environment

  image = var.backend_image
  port  = var.backend_port

  cpu_limit    = var.backend_cpu_limit
  memory_limit = var.backend_memory_limit

  min_instances = var.backend_min_instances
  max_instances = var.backend_max_instances

  # VPC Access for Cloud SQL
  vpc_connector_name = module.vpc_connector.connector_id
  vpc_egress         = "private-ranges-only"

  # Environment variables
  env_vars = merge(
    {
      GIN_MODE    = "release"
      DB_HOST     = module.cloudsql.private_ip_address
      DB_PORT     = "5432"
      DB_NAME     = module.cloudsql.database_name
      DB_USER     = "root"
      ENVIRONMENT = var.environment
    },
    var.additional_env_vars
  )

  # Secrets
  secrets = {
    DB_PASSWORD = {
      secret_name = module.db_password_secret.secret_name
      version     = "latest"
    }
  }

  depends_on = [
    module.vpc_connector,
    module.cloudsql,
    module.db_password_secret
  ]
}

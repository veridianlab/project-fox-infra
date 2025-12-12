# Secret Manager Module

Creates and manages secrets in Google Cloud Secret Manager with IAM bindings.

## Features

- ✅ Creates secret with automatic replication
- ✅ Stores secret value securely
- ✅ Grants access to specified service accounts
- ✅ Environment-based labeling

## Usage

```hcl
module "db_password" {
  source = "git::https://github.com/veridianlab/project-fox-infra.git//modules/secret-manager?ref=v1.1.0"

  project_id   = "project-fox-staging"
  secret_id    = "db-password-staging"
  secret_value = var.db_password
  environment  = "staging"

  accessor_service_accounts = [
    "cloud-run-backend@project-fox-staging.iam.gserviceaccount.com"
  ]
}
```

## Inputs

| Name                      | Description                                        | Type           | Default | Required |
| ------------------------- | -------------------------------------------------- | -------------- | ------- | -------- |
| project_id                | GCP Project ID                                     | `string`       | n/a     | yes      |
| secret_id                 | ID of the secret (name)                            | `string`       | n/a     | yes      |
| secret_value              | Value of the secret                                | `string`       | n/a     | yes      |
| environment               | Environment name (staging/production)              | `string`       | n/a     | yes      |
| accessor_service_accounts | Service account emails that can access this secret | `list(string)` | `[]`    | no       |

## Outputs

| Name                | Description                    |
| ------------------- | ------------------------------ |
| secret_id           | The ID of the secret           |
| secret_name         | The name of the secret         |
| secret_version_name | The version name of the secret |

## Security Notes

- Secret values are marked as sensitive in Terraform state
- Uses automatic replication across regions
- Only specified service accounts can access the secret
- Requires `secretmanager.googleapis.com` API to be enabled

## Example with Random Password

```hcl
resource "random_password" "db_password" {
  length  = 32
  special = true
}

module "db_password_secret" {
  source = "git::https://github.com/veridianlab/project-fox-infra.git//modules/secret-manager?ref=v1.1.0"

  project_id   = "project-fox-staging"
  secret_id    = "database-password"
  secret_value = random_password.db_password.result
  environment  = "staging"

  accessor_service_accounts = [
    "my-service@project-fox-staging.iam.gserviceaccount.com"
  ]
}
```

# Cloud Scheduler Module

Simple module to ping a Cloud Run service on a schedule.

## Usage

```hcl
module "ping_cloudrun" {
  source = "./modules/cloud-scheduler"

  project_id  = "my-project"
  region      = "us-central1"
  job_name    = "ping-my-service"
  description = "Keep Cloud Run warm"
  schedule    = "*/5 * * * *"  # Every 5 minutes
  uri         = "https://my-service-abc123-uc.a.run.app/health"

  # Optional: for authenticated Cloud Run services
  service_account_email = "scheduler-sa@my-project.iam.gserviceaccount.com"
}
```

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| project_id | The GCP project ID | `string` | n/a | yes |
| region | The region for the scheduler job | `string` | n/a | yes |
| job_name | The name of the job | `string` | n/a | yes |
| description | Job description | `string` | `""` | no |
| schedule | Cron schedule | `string` | n/a | yes |
| uri | Cloud Run URL to ping | `string` | n/a | yes |
| http_method | HTTP method | `string` | `"GET"` | no |
| service_account_email | SA for OIDC auth | `string` | `null` | no |
| paused | Whether job is paused | `bool` | `false` | no |

## Outputs

| Name | Description |
|------|-------------|
| job_id | The ID of the Cloud Scheduler job |
| job_name | The name of the Cloud Scheduler job |

## Common Schedules

| Schedule | Description |
|----------|-------------|
| `*/5 * * * *` | Every 5 minutes |
| `*/15 * * * *` | Every 15 minutes |
| `0 * * * *` | Every hour |
| `0 9 * * *` | Daily at 9 AM |

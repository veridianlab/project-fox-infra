# Load Balancer + Cloud Armor Module

Global external HTTPS Load Balancer with a Cloud Armor policy fronting a Cloud Run service.

## Features

- Global external HTTPS LB with a reserved static IPv4 address
- Serverless NEG pointing at a Cloud Run service
- Cloud Armor policy: default deny 403 (allow rules are managed by the application at runtime)
- Google-managed SSL certificate (multi-domain / SAN supported)
- Backend service logging at 100% sample rate (denied and allowed requests show up in Logs Explorer)

## How It Works

1. Client hits `https://<domain>/` → DNS resolves to the LB's static IP.
2. Global forwarding rule (port 443) → target HTTPS proxy → URL map → backend service.
3. Cloud Armor evaluates the source IP against the policy rules. The Terraform-managed baseline is default-deny only (GCP implicit rule); the application populates allow rules at runtime via the IP whitelist sync. Until the app has synced at least one allow rule after apply, all traffic is denied with 403.
4. Allowed requests forward via the serverless NEG to Cloud Run.
5. Cloud Run is set to `ingress = "INGRESS_TRAFFIC_INTERNAL_LOAD_BALANCER"` so the `*.run.app` URL can't be used to bypass the LB.

## Usage

```hcl
module "api_lb" {
  source = "git::https://github.com/veridianlab/project-fox-infra.git//modules/lb-cloud-armor?ref=v1.2.0"

  project_id  = "project-fox-staging"
  region      = "asia-southeast1"
  lb_name     = "lynx-haven-lb-staging"
  environment = "staging"

  cloudrun_service_name     = module.backend_service.service_name
  cloudrun_service_location = module.backend_service.service_location

  domains = ["api.staging.example.com"]
}

output "lb_ip" {
  value = module.api_lb.lb_ip_address
}
```

Pair with Cloud Run:

```hcl
module "backend_service" {
  source = "git::https://github.com/veridianlab/project-fox-infra.git//modules/cloudrun?ref=v1.2.0"

  # ...
  ingress = "INGRESS_TRAFFIC_INTERNAL_LOAD_BALANCER"
}
```

## Inputs

| Name                      | Description                                    | Type           | Default | Required |
| ------------------------- | ---------------------------------------------- | -------------- | ------- | -------- |
| project_id                | GCP project ID                                 | `string`       | -       | yes      |
| region                    | GCP region (parity only; not used by global LB resources) | `string` | -       | yes      |
| lb_name                   | Name prefix for all LB resources               | `string`       | -       | yes      |
| environment               | Environment name                               | `string`       | -       | yes      |
| cloudrun_service_name     | Name of the Cloud Run service behind the LB   | `string`       | -       | yes      |
| cloudrun_service_location | Region of the Cloud Run service (NEG region)   | `string`       | -       | yes      |
| domains                   | Domains for the managed SSL cert (1-100 SANs)  | `list(string)` | -       | yes      |
| bootstrap_allow_ranges    | Transitional allow-list for zero-downtime migration to app-managed rules. Terraform auto-removes the rule when cleared. | `list(string)` | `[]`    | no       |

## Outputs

| Name                 | Description                                     |
| -------------------- | ----------------------------------------------- |
| lb_ip_address        | Static IPv4 address — point DNS A records here |
| backend_service_id   | ID of the backend service                       |
| security_policy_id   | ID of the Cloud Armor security policy           |
| security_policy_name | Name of the Cloud Armor security policy         |
| ssl_certificate_id   | ID of the Google-managed SSL certificate        |
| url_map_id           | ID of the URL map                               |

## Notes

1. **DNS must be in place before the cert activates.** Google-managed certs only provision after the cert's domains resolve to this LB's IP. Expect 15–60 minutes after DNS is live (sometimes up to 24h). Check status with `gcloud compute ssl-certificates describe <name>`.
2. **Restrict Cloud Run ingress.** The IP allowlist is only enforced for traffic through the LB. If Cloud Run ingress stays `INGRESS_TRAFFIC_ALL`, clients can hit `https://<service>-<hash>-<region>.run.app` directly and bypass Cloud Armor entirely. Set `ingress = "INGRESS_TRAFFIC_INTERNAL_LOAD_BALANCER"` on the cloudrun module.
3. **Allow rules are managed by the application.** The Cloud Armor policy deployed here contains only the default deny rule. IP allow rules are added and managed by the application at runtime, not via Terraform.
4. **Default deny rule.** A standalone `google_compute_security_policy_rule` resource enforces `deny(403)` at priority 2147483647. This resource is independent of the parent policy's `ignore_changes = [rule]`, so Terraform will create and drift-correct it on every plan. No manual gcloud step is needed.
5. **Drift monitoring.** Because `ignore_changes = [rule]` suppresses drift detection for inline rules, consider a Cloud Monitoring alert on security policy mutations (`log filter: resource.type="gce_security_policy"`). The standalone default-deny and bootstrap resources are tracked normally; this alert covers any unexpected changes to app-managed rules at priorities 1000+.
5. **Changing `domains` recreates the cert.** The cert name carries a `random_id` suffix keyed on the domain list, and the resource uses `create_before_destroy`, so the new cert is provisioned before the old one is removed. Expect a fresh provisioning wait whenever domains change.
6. **Cost.** Global LB, static IP, and Cloud Armor all have ongoing costs — see GCP pricing pages.
7. **Breaking change (v1.2.0).** The `allowed_ip_ranges` variable has been removed. IP allowlisting is now handled entirely by the application at runtime. If upgrading from a previous version, remove `allowed_ip_ranges` from your module block and migrate any static IPs to the application's IP whitelist settings page.

### Migration from v1.1.x to v1.2.0

Use `bootstrap_allow_ranges` for a zero-downtime transition:

```hcl
# Step 1: Add the bootstrap variable with your current CIDRs
module "api_lb" {
  source = "git::https://github.com/veridianlab/project-fox-infra.git//modules/lb-cloud-armor?ref=v1.2.0"

  # ... other variables ...

  bootstrap_allow_ranges = ["203.0.113.10/32", "198.51.100.0/24"]  # your current IPs
}
```

Apply, then deploy the application with the runtime IP whitelist sync enabled. Verify rules exist:

```bash
gcloud compute security-policies describe <POLICY_NAME>
```

Once the app has synced its allow rules, set `bootstrap_allow_ranges = []` and apply again. The bootstrap rule is a standalone `google_compute_security_policy_rule` resource, so Terraform will remove it automatically when the list is cleared.

# Load Balancer + Cloud Armor Module

Global external HTTPS Load Balancer with a Cloud Armor policy for IP allowlisting, fronting a Cloud Run service.

## Features

- Global external HTTPS LB with a reserved static IPv4 address
- Serverless NEG pointing at a Cloud Run service
- Cloud Armor policy: default deny 403, allow rule for listed CIDRs
- Google-managed SSL certificate (multi-domain / SAN supported)
- Backend service logging at 100% sample rate (denied and allowed requests show up in Logs Explorer)

## How It Works

1. Client hits `https://<domain>/` → DNS resolves to the LB's static IP.
2. Global forwarding rule (port 443) → target HTTPS proxy → URL map → backend service.
3. Cloud Armor evaluates the source IP against the allowlist. Non-matching IPs get a 403.
4. Allowed requests forward via the serverless NEG to Cloud Run.
5. Cloud Run is set to `ingress = "INGRESS_TRAFFIC_INTERNAL_LOAD_BALANCER"` so the `*.run.app` URL can't be used to bypass the LB.

## Usage

```hcl
module "api_lb" {
  source = "git::https://github.com/veridianlab/project-fox-infra.git//modules/lb-cloud-armor?ref=v1.1.4"

  project_id  = "project-fox-staging"
  region      = "asia-southeast1"
  lb_name     = "lynx-haven-lb-staging"
  environment = "staging"

  cloudrun_service_name     = module.backend_service.service_name
  cloudrun_service_location = module.backend_service.service_location

  domains = ["api.staging.example.com"]

  allowed_ip_ranges = [
    "203.0.113.10/32", # hotel office
    "198.51.100.0/24", # dev VPN
  ]
}

output "lb_ip" {
  value = module.api_lb.lb_ip_address
}
```

Pair with Cloud Run:

```hcl
module "backend_service" {
  source = "git::https://github.com/veridianlab/project-fox-infra.git//modules/cloudrun?ref=v1.1.4"

  # ...
  ingress = "INGRESS_TRAFFIC_INTERNAL_LOAD_BALANCER"
}
```

## Inputs

| Name                      | Description                                    | Type           | Default | Required |
| ------------------------- | ---------------------------------------------- | -------------- | ------- | -------- |
| project_id                | GCP project ID                                 | `string`       | -       | yes      |
| region                    | GCP region (parity with sibling modules)       | `string`       | -       | yes      |
| lb_name                   | Name prefix for all LB resources               | `string`       | -       | yes      |
| environment               | Environment name                               | `string`       | -       | yes      |
| cloudrun_service_name     | Name of the Cloud Run service behind the LB   | `string`       | -       | yes      |
| cloudrun_service_location | Region of the Cloud Run service (NEG region)   | `string`       | -       | yes      |
| domains                   | Domains for the managed SSL cert (1-100 SANs)  | `list(string)` | -       | yes      |
| allowed_ip_ranges         | CIDRs allowed by Cloud Armor; rest denied 403  | `list(string)` | -       | yes      |

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
3. **Default deny rule.** The Cloud Armor default rule (priority 2147483647) cannot be deleted, only modified. It's declared here explicitly as `deny(403)`.
4. **Changing `domains` recreates the cert.** The cert name carries a `random_id` suffix keyed on the domain list, and the resource uses `create_before_destroy`, so the new cert is provisioned before the old one is removed. Expect a fresh provisioning wait whenever domains change.
5. **Cost.** Global LB, static IP, and Cloud Armor all have ongoing costs — see GCP pricing pages.

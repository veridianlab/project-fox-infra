# Quick Start: Static IP for Cloud Run

If your Cloud Run service needs to call third-party APIs that require IP allowlisting, follow these steps:

## ⚡ Quick Implementation (5 minutes)

### 1. Add Cloud NAT Module

Add to your `main.tf`:

```hcl
module "cloud_nat" {
  source = "git::https://github.com/veridianlab/project-fox-infra.git//modules/cloud-nat?ref=v1.1.0"

  project_id       = var.project_id
  region           = var.region
  nat_name         = "cloudrun-nat-${var.environment}"
  vpc_network_name = module.vpc_network.network_name
}
```

### 2. Update Cloud Run Egress

**Critical**: Change your Cloud Run module to route ALL traffic through VPC:

```hcl
module "backend_service" {
  source = "git::..."

  # ... other config ...

  vpc_connector_name = module.vpc_connector.connector_id
  vpc_egress         = "all-traffic"  # ← Change this from "private-ranges-only"
}
```

### 3. Output the Static IP

Add to your `outputs.tf`:

```hcl
output "static_nat_ip" {
  description = "Provide this IP to third-party API providers"
  value       = module.cloud_nat.nat_ip_address
}
```

### 4. Apply Changes

```bash
terraform init -upgrade
terraform plan
terraform apply
```

### 5. Get Your Static IP

```bash
terraform output static_nat_ip
```

Example output:

```
34.87.123.45
```

### 6. Allowlist the IP

Provide this IP address to your third-party API provider for allowlisting.

## ✅ Verification

Test that your Cloud Run is using the static IP:

```bash
# From your Cloud Run service, call:
curl https://api.ipify.org?format=json

# Should return the same IP as terraform output static_nat_ip
```

## 📊 What You Need

Before implementing, ensure you have:

- ✅ VPC Network configured
- ✅ VPC Connector configured
- ✅ Cloud Run service deployed

All of these are included in the `examples/backend-complete/` if you're starting fresh.

## 💰 Cost

- **~$35-50/month** base cost
- **~$0.045/GB** data processed through NAT

## 🔍 Troubleshooting

**IP not static?**

- Check that `vpc_egress = "all-traffic"` is set
- Verify VPC Connector is attached
- Ensure Cloud NAT is in the same region as Cloud Run

**Need more details?**

- Read: [STATIC_IP_SETUP.md](STATIC_IP_SETUP.md) - Complete implementation guide
- Read: [CLOUD_NAT_CHANGES.md](CLOUD_NAT_CHANGES.md) - All changes explained
- Read: [modules/cloud-nat/README.md](modules/cloud-nat/README.md) - Module docs

## 🎯 Key Points

1. **Must set `vpc_egress = "all-traffic"`** - Without this, traffic bypasses Cloud NAT
2. **One NAT per region** - If multi-region, you need multiple NATs
3. **IP is consistent** - Same IP across all instances and scaling
4. **VPC Connector required** - Cloud Run must access VPC network

---

**That's it!** Your Cloud Run service now has a static external IP address for all egress traffic.

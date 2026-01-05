# Cloud NAT Setup for Static IP Egress

## Problem Statement

Cloud Run services have dynamic IPs that change when instances scale up or down. When your Cloud Run API needs to call third-party APIs that require IP allowlisting, you need a static external IP address for all outbound traffic.

## Solution: Cloud NAT with Static IP

This infrastructure provides a Cloud NAT gateway with a reserved static external IP address. All outbound traffic from your Cloud Run service will use this consistent IP address.

## Architecture Flow

```
Cloud Run Service
    ↓ (egress traffic)
VPC Connector
    ↓ (routes through VPC)
Cloud NAT Gateway
    ↓ (uses static IP)
Third-Party API
```

## What Changed in Your Infrastructure

### 1. New Module: `cloud-nat`

Created a new Terraform module at `modules/cloud-nat/` that includes:

- **Static External IP**: Reserved IP address that won't change
- **Cloud Router**: Required for Cloud NAT (automatically created)
- **Cloud NAT Gateway**: Routes all VPC traffic through the static IP

### 2. Updated Cloud Run Configuration

**Critical Change**: Modified `vpc_egress` setting from `"private-ranges-only"` to `"all-traffic"`

**Before:**

```hcl
vpc_egress = "private-ranges-only"  # Only private traffic (Cloud SQL) goes through VPC
```

**After:**

```hcl
vpc_egress = "all-traffic"  # ALL traffic goes through VPC (and thus Cloud NAT)
```

This ensures ALL outbound traffic from Cloud Run uses the static IP, not just private network traffic.

### 3. Updated Example Configuration

The `examples/backend-complete/main.tf` now includes:

- Cloud NAT module instantiation
- Output for the static IP address
- Variables for NAT logging configuration

## How to Apply These Changes

### Step 1: Update Your Terraform Configuration

If you're using the example as a reference, your main.tf should now include:

```hcl
# Cloud NAT with Static IP
module "cloud_nat" {
  source = "git::https://github.com/veridianlab/project-fox-infra.git//modules/cloud-nat?ref=v1.1.0"

  project_id       = var.project_id
  region           = var.region
  nat_name         = "cloudrun-nat-${var.environment}"
  vpc_network_name = module.vpc_network.network_name

  enable_logging = true
  log_filter     = "ERRORS_ONLY"

  depends_on = [module.vpc_network]
}

# Cloud Run with ALL traffic through VPC
module "backend_service" {
  source = "..."

  vpc_connector_name = module.vpc_connector.connector_id
  vpc_egress         = "all-traffic"  # Changed from "private-ranges-only"

  # ... other configuration
}

# Output the static IP
output "cloud_nat_ip_address" {
  description = "Provide this IP to third-party API providers"
  value       = module.cloud_nat.nat_ip_address
}
```

### Step 2: Initialize and Plan

```bash
# Initialize Terraform to download the new module
terraform init -upgrade

# Review the changes
terraform plan
```

You should see:

- New Cloud NAT resources being created
- Cloud Run service being updated (vpc_egress change)
- New static IP address being reserved

### Step 3: Apply the Changes

```bash
terraform apply
```

### Step 4: Get the Static IP Address

After applying, get the static IP:

```bash
terraform output cloud_nat_ip_address
```

Example output:

```
34.87.123.45
```

### Step 5: Provide IP to Third-Party Provider

Give this IP address to your third-party API provider for allowlisting.

## Verification

### Test That Traffic Uses the Static IP

1. Deploy a test endpoint in your Cloud Run service:

```go
// Example Go endpoint
func CheckMyIP(c *gin.Context) {
    resp, err := http.Get("https://api.ipify.org?format=json")
    if err != nil {
        c.JSON(500, gin.H{"error": err.Error()})
        return
    }
    defer resp.Body.Close()

    body, _ := ioutil.ReadAll(resp.Body)
    c.JSON(200, gin.H{"my_ip": string(body)})
}
```

2. Call this endpoint multiple times from different Cloud Run instances
3. Verify the IP is always the same and matches your `cloud_nat_ip_address` output

### Check Cloud NAT Logs

```bash
# View NAT logs in Google Cloud Console
gcloud logging read "resource.type=nat_gateway" --limit 50 --format json
```

## Cost Implications

- **Static IP Address**: ~$0.004/hour (~$3/month) when in use
- **Cloud NAT**: ~$0.044/hour (~$32/month) + data processing charges
- **VPC Connector**: Already in your infrastructure
- **Data Processing**: ~$0.045 per GB processed through NAT

Total additional cost: ~$35-50/month + data charges

## Important Notes

### 1. VPC Egress Setting is Critical

⚠️ **You MUST set `vpc_egress = "all-traffic"`**

- `"private-ranges-only"`: Only private traffic (like Cloud SQL) uses VPC
- `"all-traffic"`: ALL outbound traffic uses VPC and thus Cloud NAT

Without this setting, your Cloud Run service will bypass Cloud NAT for public internet traffic.

### 2. VPC Connector is Required

Cloud Run must have a VPC Connector configured to access the VPC network. This is already in your infrastructure.

### 3. Multiple Regions

If you deploy Cloud Run in multiple regions, you need:

- One Cloud NAT per region
- One static IP per region
- Provide all IPs to your third-party provider

### 4. High Availability

For production:

- Consider using multiple static IPs for redundancy
- Enable Cloud NAT logging for troubleshooting
- Monitor NAT port exhaustion metrics

## Troubleshooting

### Issue: Traffic not using static IP

**Check:**

1. `vpc_egress = "all-traffic"` is set in Cloud Run
2. VPC Connector is properly attached
3. Cloud NAT is in the same region as Cloud Run
4. Cloud NAT is configured for the correct VPC network

**Verify:**

```bash
# Check Cloud Run configuration
gcloud run services describe YOUR_SERVICE --region YOUR_REGION --format yaml | grep -A 5 vpcAccess

# Check Cloud NAT status
gcloud compute routers nats list --router YOUR_ROUTER --region YOUR_REGION
```

### Issue: Port exhaustion

If you see errors about port exhaustion:

1. Increase `max_ports_per_vm` in the Cloud NAT module
2. Add more static IPs to the NAT configuration
3. Review and optimize connection pooling in your application

### Issue: High latency

Cloud NAT adds minimal latency (~1-2ms), but if you experience issues:

1. Ensure Cloud NAT is in the same region as Cloud Run
2. Check VPC Connector performance and scaling
3. Review Cloud NAT metrics in Cloud Console

## Next Steps

1. ✅ Apply the Terraform changes
2. ✅ Get the static IP from outputs
3. ✅ Provide IP to third-party provider
4. ✅ Test connectivity
5. ✅ Monitor Cloud NAT metrics
6. ✅ Set up alerts for port exhaustion

## References

- [Cloud NAT Overview](https://cloud.google.com/nat/docs/overview)
- [Cloud Run VPC Egress](https://cloud.google.com/run/docs/configuring/vpc-direct-vpc)
- [Cloud NAT Pricing](https://cloud.google.com/nat/pricing)

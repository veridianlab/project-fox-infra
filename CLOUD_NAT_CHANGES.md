# Infrastructure Changes Summary - Cloud NAT for Static IP

## Overview

Added Cloud NAT infrastructure to provide a static external IP address for Cloud Run egress traffic, enabling third-party API providers to allowlist your service.

## Files Created

### 1. New Module: `modules/cloud-nat/`

- **main.tf**: Cloud NAT gateway, Cloud Router, and static IP reservation
- **variables.tf**: Configurable parameters for NAT setup
- **outputs.tf**: Outputs the static IP address for allowlisting
- **README.md**: Complete documentation with usage examples

### 2. Documentation

- **STATIC_IP_SETUP.md**: Comprehensive guide for implementing the solution

## Files Modified

### 1. `modules/cloudrun/variables.tf`

- Updated `vpc_egress` variable with better documentation
- Added validation to ensure correct values
- Changed to lowercase format: `"all-traffic"` or `"private-ranges-only"`

### 2. `examples/backend-complete/main.tf`

- Added Cloud NAT module instantiation
- Changed Cloud Run `vpc_egress` from `"private-ranges-only"` to `"all-traffic"`

### 3. `examples/backend-complete/variables.tf`

- Added `enable_nat_logging` variable
- Added `nat_log_filter` variable

### 4. `examples/backend-complete/outputs.tf`

- Added `cloud_nat_ip_address` output (the IP to provide to third-parties)
- Added `cloud_nat_name` output

## Key Changes Explained

### Critical Configuration Change

```hcl
# BEFORE - Only private traffic uses VPC
vpc_egress = "private-ranges-only"

# AFTER - ALL traffic uses VPC and Cloud NAT
vpc_egress = "all-traffic"
```

This is **required** for Cloud NAT to work. Without it, public internet traffic will bypass the VPC and Cloud NAT entirely.

## Architecture Components

```
┌─────────────────┐
│   Cloud Run     │
│   (Your API)    │
└────────┬────────┘
         │ egress: all-traffic
         ↓
┌─────────────────┐
│  VPC Connector  │
└────────┬────────┘
         │
         ↓
┌─────────────────┐      ┌──────────────────┐
│   VPC Network   │←────→│  Cloud Router    │
└────────┬────────┘      └────────┬─────────┘
         │                        │
         ↓                        ↓
┌─────────────────┐      ┌──────────────────┐
│   Cloud SQL     │      │   Cloud NAT      │
│   (Private IP)  │      │                  │
└─────────────────┘      └────────┬─────────┘
                                  │
                                  ↓
                         ┌──────────────────┐
                         │   Static IP      │
                         │  (Egress to     │
                         │   Internet)      │
                         └────────┬─────────┘
                                  │
                                  ↓
                         ┌──────────────────┐
                         │  Third-Party API │
                         │   (Allowlisted)  │
                         └──────────────────┘
```

## How to Use

### Step 1: Add Cloud NAT Module to Your Configuration

```hcl
module "cloud_nat" {
  source = "git::https://github.com/veridianlab/project-fox-infra.git//modules/cloud-nat?ref=v1.1.0"

  project_id       = var.project_id
  region           = var.region
  nat_name         = "cloudrun-nat-${var.environment}"
  vpc_network_name = module.vpc_network.network_name
}
```

### Step 2: Update Cloud Run VPC Egress

```hcl
module "cloudrun" {
  # ... other config
  vpc_egress = "all-traffic"  # Changed from "private-ranges-only"
}
```

### Step 3: Output the Static IP

```hcl
output "cloud_nat_ip_address" {
  value = module.cloud_nat.nat_ip_address
}
```

### Step 4: Apply and Get the IP

```bash
terraform init -upgrade
terraform plan
terraform apply
terraform output cloud_nat_ip_address
```

### Step 5: Provide IP to Third-Party

Give the IP address from the output to your third-party API provider for allowlisting.

## Cost Estimate

- Static IP: ~$3/month
- Cloud NAT: ~$32/month
- Data processing: ~$0.045/GB
- **Total**: ~$35-50/month + data charges

## Testing

After deployment, verify the setup:

1. Deploy a test endpoint that returns its external IP
2. Call it multiple times
3. Confirm the IP matches your `cloud_nat_ip_address` output
4. Check that it's the same across multiple requests

## Important Notes

1. **VPC Egress Must Be "all-traffic"**: This is non-negotiable for Cloud NAT to work
2. **Regional Resource**: Cloud NAT is per-region; if you have multi-region deployment, you need one per region
3. **Existing VPC Required**: Cloud NAT works with your existing VPC network
4. **No Cloud Run Restart**: Changes will apply on next deployment

## Troubleshooting

If traffic isn't using the static IP:

- Verify `vpc_egress = "all-traffic"`
- Check VPC Connector is attached
- Ensure Cloud NAT is in the same region as Cloud Run
- Review Cloud NAT logs for errors

## Next Steps

1. Read `STATIC_IP_SETUP.md` for detailed implementation guide
2. Review `modules/cloud-nat/README.md` for module documentation
3. Check `examples/backend-complete/` for complete working example
4. Apply changes to your environment
5. Monitor Cloud NAT metrics in GCP Console

## References

- Module: `modules/cloud-nat/`
- Example: `examples/backend-complete/`
- Guide: `STATIC_IP_SETUP.md`

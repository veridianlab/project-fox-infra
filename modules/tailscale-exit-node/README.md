# Tailscale Exit Node Module

GCP VM configured as a Tailscale exit node with a static external IP. The static IP is the stable egress point that you add to Cloud Armor (or any third-party) allowlists, so every device routing via the exit node is allowlisted.

## Features

- Static external IPv4 (reserved regional address)
- e2-micro VM running Ubuntu 22.04 LTS (defaults; overridable)
- `can_ip_forward = true` (required for exit-node routing)
- Firewall rules: Tailscale UDP 41641 (open) + SSH TCP 22 (source-restrictable, toggleable)
- Outputs the IP as both a raw address and a `/32` CIDR ready to paste into `allowed_ip_ranges`

## How It Works

1. A developer / service enables Tailscale, picks this VM as their exit node.
2. Traffic egresses GCP via this VM's static IP.
3. The IP is allowlisted in Cloud Armor (`lb-cloud-armor` module) or any upstream ACL.
4. No per-client IP whitelisting needed — everyone routing through Tailscale looks like this single IP.

## Usage

```hcl
module "tailscale_exit_node" {
  source = "git::https://github.com/veridianlab/project-fox-infra.git//modules/tailscale-exit-node?ref=v1.1.5"

  project_id  = "project-fox-production"
  region      = "asia-southeast1"
  zone        = "asia-southeast1-b"
  environment = "production"
}

output "tailscale_exit_ip" {
  value = module.tailscale_exit_node.exit_node_ip
}
```

### Feeding the IP into Cloud Armor

```hcl
module "api_lb" {
  source = "git::https://github.com/veridianlab/project-fox-infra.git//modules/lb-cloud-armor?ref=v1.1.4"

  # ... other inputs ...

  allowed_ip_ranges = concat(
    var.static_office_ips,
    [module.tailscale_exit_node.exit_node_ip_cidr],
  )
}
```

### Locking down SSH after setup

Once the VM is up and you've run `tailscale up --advertise-exit-node`, either narrow the SSH source range or drop the rule entirely:

```hcl
module "tailscale_exit_node" {
  # ...
  ssh_source_ranges = ["203.0.113.10/32"]  # your office only
  # or
  enable_ssh = false  # removes the rule; still reachable via Tailscale SSH
}
```

## Post-provision setup

This module creates the VM but does not install or configure Tailscale. SSH in and run:

```bash
curl -fsSL https://tailscale.com/install.sh | sh
sudo tailscale up --advertise-exit-node --ssh
# Then in the Tailscale admin console:
#   - Approve the exit node
#   - (Optional) disable key expiry on this node
```

Also enable IPv4 forwarding at the kernel level (Tailscale's install script handles this on recent Ubuntu, but verify):

```bash
echo 'net.ipv4.ip_forward = 1' | sudo tee -a /etc/sysctl.conf
sudo sysctl -p
```

## Inputs

| Name              | Description                                       | Type           | Default                              | Required |
| ----------------- | ------------------------------------------------- | -------------- | ------------------------------------ | -------- |
| project_id        | GCP project ID                                    | `string`       | -                                    | yes      |
| region            | Region for the static IP                          | `string`       | -                                    | yes      |
| zone              | Zone for the VM                                   | `string`       | -                                    | yes      |
| environment       | Environment name                                  | `string`       | -                                    | yes      |
| instance_name     | Name prefix for all resources                     | `string`       | `"tailscale-exit-node"`              | no       |
| machine_type      | Compute Engine machine type                       | `string`       | `"e2-micro"`                         | no       |
| os_image          | Boot disk image                                   | `string`       | `"ubuntu-os-cloud/ubuntu-2204-lts"`  | no       |
| boot_disk_size_gb | Boot disk size                                    | `number`       | `10`                                 | no       |
| network           | VPC network                                       | `string`       | `"default"`                          | no       |
| subnetwork        | Subnetwork (null = auto for network)              | `string`       | `null`                               | no       |
| enable_ssh        | Create the SSH firewall rule                      | `bool`         | `true`                               | no       |
| ssh_source_ranges | CIDRs allowed to SSH in                           | `list(string)` | `["0.0.0.0/0"]`                      | no       |

## Outputs

| Name                 | Description                                                     |
| -------------------- | --------------------------------------------------------------- |
| exit_node_ip         | Static external IP                                              |
| exit_node_ip_cidr    | IP as `/32` CIDR — drop straight into `allowed_ip_ranges`       |
| exit_node_name       | VM name                                                         |
| exit_node_self_link  | VM self_link                                                    |
| exit_node_zone       | VM zone                                                         |

## Notes

- **Provider**: tested with `hashicorp/google ~> 7.0`.
- **Cost**: e2-micro is in the free tier in some regions; a regional static IP costs ~$1.50/mo when attached to a running VM, more when detached. Check GCP pricing.
- **IP forwarding**: `can_ip_forward` on the instance is a GCP-level setting; you still need `net.ipv4.ip_forward = 1` inside the OS for the kernel to actually route packets.
- **Firewall scope**: rules target the VM via network tag (`instance_name`) so they only apply to this instance, not the whole VPC.
- **SSH after setup**: either set `ssh_source_ranges` to your office/VPN CIDRs or flip `enable_ssh = false` and use Tailscale SSH (`tailscale up --ssh`) for access.

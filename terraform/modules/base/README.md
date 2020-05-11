# base module

The base of the terraform configuration thus this module must be applied in the first turn.

ActionML automated configuration is primarily driven by Kubernetes whereas Terraform manages the essential AWS resources configuration.

The primary task of the base module is to initialize a VPC for the EKS Kubernetes cluster.

## Configuration `terraform/live/${stage}/base/terraform.tfvars`

### Inputs

| Name | Description | Type | Default | Required |
|------|-------------|:----:|:-----:|:-----:|
| azs | A list of availability zones in the region | string | `<list>` | no |
| cidr | The CIDR block for the VPC. Default value is a valid CIDR, but not acceptable by AWS and should be overridden | string | `<string>` | yes |
| private_subnets | A list of private subnets inside the VPC | string | `<list>` | no |
| public_subnets | A list of public subnets inside the VPC | string | `<list>` | no |

## Usage

This module creates a VPC for the EKS cluster. We recommended to bootstrap a VPC with not less than 2 private and 2 public subnets (VPC CIDR addresses must be from the `RFC1918` defined ranges).

The minimum number of subnets is enforced by the EKS control plane to provide the HA setup.

### VPC subnets layout

We assume:

- your workstation has all the required tools and aws credentials are installed
- we operate in the `test` stage

Edit `live/test/base/terragrunt.hcl`, sample input variables values may look like:

```hcl
inputs = {
  cidr               = "10.31.0.0/16"
  shared_k8s_cluster = "opsfleet-test-eks"

  ## EKS control plane requires at least 2 AZs.
  #

  # Relatively small ~512 hosts
  public_subnets = [
    "10.31.0.0/23",
    "10.31.2.0/23",
    # "10.31.4.0/23",
  ]

  # Bigger just in case ~2048 hosts
  private_subnets = [
    "10.31.16.0/21",
    "10.31.24.0/21",
    # "10.31.32.0/21",
  ]

  # Availabilty zones
  azs = [
    "eu-central-1a",
    "eu-central-1b",
    # "eu-central-1c",
  ]
}
```

This will create a VPC with 2 public and 2 private subnets in each of the given availability zones.

```bash
cd terraform/live/test/base

terragrunt apply
```

When applied successfully you should see the similar output as bellow:

```hcl
Apply complete! Resources: 0 added, 0 changed, 0 destroyed.
Releasing state lock. This may take a few moments...

Outputs:

vpc = {
  "azs" = [
    "eu-central-1a",
    "eu-central-1b",
  ]
  "cgw_ids" = []
  "database_network_acl_id" = ""

...
```

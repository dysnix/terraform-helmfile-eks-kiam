# eks module

A simple EKS test setup based on terraform/eks/aws module. Module bootstraps a EKS cluster in the given VPC and subnets.
For additional details please refer to EKS module 

## Configuration `terraform/live/{{ stage }}/eks/terraform.tfvars`

### Inputs

| Name | Description | Type | Default | Required |
|------|-------------|:----:|:-----:|:-----:|
| cluster_name | Name of the EKS cluster. Also used as a prefix in names of related resources. Default value is calculated base on the project variable. | string | `<string>` | no |
| cluster_version | Kubernetes version to use for the EKS cluster. | string | `"1.16"` | no |
| subnets | A list of subnets (subnet IDs) to place the EKS cluster and workers within. | string | `<list>` | yes |
| vpc_id | VPC where the cluster and workers will be deployed. | `string` | `<string>` | yes |

## Usage

Before applying this module you must apply the `base` module which outputs the new VPC and subnets IDs or in case of an existing VPC please provide:
- `vpc_id`
- `subnets`

We **recommend to use private subnets** for EKS cluster. EKS cluster control plane requires at least two availability zones for the master Kubernetes master nodes. This requirement enforces the minimal amount of subnets.

Note that in case you provide an existing VPC and subnets make sure to tag the resources respectivly.

Tag VPC:
  - `kubernetes.io/cluster/EKS_CLUSTER_NAME: shared`

Tag public subnets:
  - `kubernetes.io/role/elb: 1`
  - `kubernetes.io/cluster/EKS_CLUSTER_NAME: shared`

Tag private subnets:
  - `kubernetes.io/role/internal-elb: 1`
  - `kubernetes.io/cluster/EKS_CLUSTER_NAME: shared`

Where `EKS_CLUSTER_NAME` is defined by our configuration settings `{{project}}-{{stage}}-eks`. For the test stage the name will be `opsfleet-test-eks`. For more details please refer to `project.tfvars` and `terragrunt.hcl` for a respective stage (`live/{{stage}}` directory).

### Example configuration

We assume:

- your workstation has all the required tools and aws credentials are installed
- that the base VPC is created and all the required input for this module is available
- we operate in the `test` stage

First you need to configure input configuration for the eks module, in this case you edit `live/test/eks/terragrunt.hcl` file, the sample input settings are shown bellow:

```
inputs = {
  vpc_id = "vpc-05a3ac6b04be96afd"

  subnets = [
    # private
    "subnet-041a8dde57221b4ae",
    "subnet-045d7c6df3db764a7",
    # public
    "subnet-03562fc8f968b5da1",
    "subnet-0ffefde1c052705af",
  ]
}
```

The above inputs provide the required data for the module. Don't ignore `var.region` too, it's specified in `project.tvars` file.

The above values are provided just as an example, so after modifying the configuration to meet your specific need you can proceed and apply the module:

```bash
cd terraform/live/test/eks

terragrunt apply
```

## Use the kube config and validate

**Important**: We don't enlight any of the advanced topics as autheniction of IAM roles against Kubernetes since this just an example.

The config should have been outputed if the modlue application when successfull:

```
kube_config = apiVersion: v1
preferences: {}
kind: Config

clusters:
- cluster:
    server: https://54E846A354A1F0FEA31C303E6CF19D1B.gr7.eu-central-1.eks.amazonaws.com
    certificate-authority-data: {{omitted output}}
  name: eks_opsfleet-test-eks

contexts:
- context:
    cluster: eks_opsfleet-test-eks
    user: eks_opsfleet-test-eks
  name: eks_opsfleet-test-eks

current-context: eks_opsfleet-test-eks

users:
- name: eks_opsfleet-test-eks
  user:
    exec:
      apiVersion: client.authentication.k8s.io/v1alpha1
      command: aws-iam-authenticator
      args:
        - "token"
        - "-i"
        - "opsfleet-test-eks"
```

Merge this config into your `~/.kube/config`, not you should also have `aws-iam-authenticator` binary available on your PATH. Validate:


```bash
kubectl config use-context eks_opsfleet-test-eks
kubectl get nodes
```

You should see your nodes ready:

```
NAME                                            STATUS   ROLES    AGE   VERSION
ip-10-31-20-196.eu-central-1.compute.internal   Ready    <none>   16m   v1.16.8-eks-e16311
ip-10-31-25-4.eu-central-1.compute.internal     Ready    <none>   16m   v1.16.8-eks-e16311
```

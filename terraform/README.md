# Terraform sample configuration for AWS
## Modules

The modules are given bellow in the **application order**:

1. base module - [setup the base VPC resources](modules/base/README.md).
1. eks module - [setup the EKS cluster](modules/eks/README.md).

## Setup

Dealing with this terraform configuration will require that you install the following tools:

* [Terraform](https://www.terraform.io/) - infrastructure management which works with almost any cloud provider.
* [Terragrunt](https://github.com/gruntwork-io/terragrunt) - a thin terraform wrapper-tool which meant to make experience smoother when working with multiple terraform stages and environments.
* [AWS CLI](https://aws.amazon.com/cli/) - AWS CLI tool.
* [AWS IAM Authenticator](https://github.com/kubernetes-sigs/aws-iam-authenticator/) - A tool to use AWS IAM credentials to authenticate to a Kubernetes cluster.

### Terragrunt

Terragrunt is a thin wrapper which makes life with terraform a bit easier. It brings to its users the following best practices of the Terraform eco-system:

* Collaborative work
* Multiple project stages (*environments*) management

These two goals are achieved because terragrunt automates the remote state management  along with operations locking. Note that these features **require AWS**, specifically an S3 bucket to store the state remotely and a DynamoDB table to provide locking.

#### Base configuration [terraform/live](live) directory

`terraform/live` - is a root **terragrunt stages configuration directory**. This means it contains different stages named as *dev, prod, stage* etc for example. Additional details can be found in [the terragrunt documentation](https://github.com/gruntwork-io/terragrunt#motivation).

Live directory contains the `project.tfvars` where `namespace` and `name` should be modified. We suggest to stick to the following naming notation `namespace` - a company name, `project` can be named as **actionml**.

It's important that you configure the `bucket`, the `key` path and the `dynamodb_table` correctly. Note that it's advised that you use the **stage name** as the **key path prefix**, such as `dev/` in the above example.

**We use administrator AWS credentials** for the simplicity of this demo. This allows terragrunt to create the S3 bucket and the dynamo table automatically for you. 

## Usage

### Workflow

1. Configure AWS credentials.
1. Clone the repository.
1. Change directory into `terraform/live/{{stage}}/{{module}}` to apply a module.
1. Apply a module.

**Note** that the preceding **module's output may serve as the input** for the later one. For the details please take time and get familiar with the modules and its [documentation](#modules).

#### Applying a module

First you need to change directory into the respective terragrunt module configuration directory. Let's assume we want apply the `base` module bellow:

```bash
cd terraform/live/test/base

# if we want to apply module for the first time or maybe re-initialize it
terragrunt init

# apply a module
terragrunt apply
```

The `apply` command will build a plan and output the detailed list of CRUD operations to perform on AWS resources. **If the change list seems sane** you may proceed by inputting `yes` and clicking `enter`.

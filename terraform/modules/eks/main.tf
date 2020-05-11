terraform {
  required_version = ">= 0.12.0"
}

provider "aws" {
  version = ">= 2.28.1"
  region  = var.region
}

data "aws_eks_cluster" "cluster" {
  name = module.eks.cluster_id
}

data "aws_eks_cluster_auth" "cluster" {
  name = module.eks.cluster_id
}

provider "kubernetes" {
  host                   = data.aws_eks_cluster.cluster.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster.certificate_authority.0.data)
  token                  = data.aws_eks_cluster_auth.cluster.token
  load_config_file       = false
  version                = "~> 1.11"
}

module "label" {
  source      = "git::https://github.com/cloudposse/terraform-null-label"
  namespace   = var.project["name"]
  environment = var.stage["name"]
  tags        = var.tags
}

module "eks_label" {
  source  = "git::https://github.com/cloudposse/terraform-null-label"
  name    = "eks"
  context = module.label.context
}

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 11.1.0"

  cluster_name    = module.eks_label.id
  subnets         = var.subnets
  cluster_version = var.cluster_version

  tags   = local.tags
  vpc_id = var.vpc_id

  worker_groups = [
    {
      name                 = "kiam-server"
      instance_type        = "t2.small"
      asg_desired_capacity = 1

      # private subnets 
      subnets            = ["subnet-041a8dde57221b4ae", "subnet-045d7c6df3db764a7"]
      iam_role_id        = aws_iam_role.kiam_node.id
      kubelet_extra_args = "--node-labels=node_pool=kiam-server --register-with-taints=kiam=true:NoSchedule"
      key_name           = "denis-dysnix"
    },
    {
      name                 = "node"
      instance_type        = "t2.small"
      asg_desired_capacity = 1

      # private subnets 
      subnets  = ["subnet-041a8dde57221b4ae", "subnet-045d7c6df3db764a7"]
      key_name = "denis-dysnix"
    },
  ]

  # worker_additional_security_group_ids = [aws_security_group.all_groups.id]
  map_roles    = var.map_roles
  map_users    = var.map_users
  map_accounts = var.map_accounts

  iam_path             = var.iam_path
  permissions_boundary = var.permissions_boundary
}

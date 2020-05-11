locals {
  vpc_tags = {
    "kubernetes.io/cluster/${var.shared_k8s_cluster}" = "shared"
  }
  public_subnet_tags = {
    "kubernetes.io/role/elb"                          = 1
    "kubernetes.io/cluster/${var.shared_k8s_cluster}" = "shared"
  }
  private_subnet_tags = {
    "kubernetes.io/role/internal-elb"                 = 1
    "kubernetes.io/cluster/${var.shared_k8s_cluster}" = "shared"
  }
}

terraform {
  required_version = ">= 0.12.0"
}

provider "aws" {
  version = ">= 2.28.1"
  region  = var.region
}

module "label" {
  source    = "git::https://github.com/cloudposse/terraform-null-label"
  namespace = var.project["name"]
  stage     = var.stage["name"]
  name      = "vpc"
}

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 2.33.0"

  name = "vpc"
  cidr = var.cidr

  azs             = var.azs
  private_subnets = var.private_subnets
  public_subnets  = var.public_subnets

  enable_nat_gateway = true

  tags = module.label.tags

  vpc_tags            = var.shared_k8s_cluster != "" ? local.vpc_tags : {}
  public_subnet_tags  = var.shared_k8s_cluster != "" ? local.public_subnet_tags : {}
  private_subnet_tags = var.shared_k8s_cluster != "" ? local.private_subnet_tags : {}
}

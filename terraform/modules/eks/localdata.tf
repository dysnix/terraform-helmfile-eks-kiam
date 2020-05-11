locals {
  ec2_principal = "ec2.${data.aws_partition.current.dns_suffix}"

  policy_arn_prefix = "arn:${data.aws_partition.current.partition}:iam::aws:policy"

  tags = { for k, v in module.label.tags : k => v if k != "Name" }
}

data "aws_partition" "current" {}

## Defult assume policy
data "aws_iam_policy_document" "kiam_node_assume_policy" {
  statement {
    actions = [
      "sts:AssumeRole",
    ]

    principals {
      type        = "Service"
      identifiers = [local.ec2_principal]
    }
  }
}

## Kiam node policy to allow assuming of Kiam server role
data "aws_iam_policy_document" "kiam_node_policy" {
  statement {
    actions = [
      "sts:AssumeRole",
    ]

    resources = [aws_iam_role.kiam_server.arn]
  }
}

## Allow Kiam nodes to assume Kiam server policy
data "aws_iam_policy_document" "kiam_node_assume_server_policy" {
  statement {
    actions = [
      "sts:AssumeRole",
    ]

    principals {
      type        = "AWS"
      identifiers = [aws_iam_role.kiam_node.arn]
    }
  }
}

## Kiam Server policy assumed by Kiam nodes
data "aws_iam_policy_document" "kiam_server_assume_policy" {
  statement {
    actions = [
      "sts:AssumeRole",
    ]

    principals {
      type        = "AWS"
      identifiers = [aws_iam_role.kiam_node.arn]
    }
  }
}

## Kiam server policy to assume other roles
data "aws_iam_policy_document" "kiam_server_policy" {
  statement {
    actions = [
      "sts:AssumeRole",
    ]

    resources = ["*"]
  }
}

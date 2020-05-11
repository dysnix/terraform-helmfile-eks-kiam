## ref: https://github.com/uswitch/kiam/blob/master/docs/IAM.md
## ref: https://www.bluematador.com/blog/iam-access-in-kubernetes-installing-kiam-in-production

## Kiam worker node role
resource "aws_iam_role" "kiam_node" {
  name                  = "${module.eks_label.id}-kiam-node"
  description           = "Kiam node role"
  assume_role_policy    = data.aws_iam_policy_document.kiam_node_assume_policy.json
  force_detach_policies = true
  path                  = var.iam_path
  permissions_boundary  = var.permissions_boundary
  tags                  = local.tags
}

## Inline policy allows Kiam node to assume Kiam server policy
resource "aws_iam_role_policy" "kiam_node" {
  name   = "${module.eks_label.id}-kiam-node"
  role   = aws_iam_role.kiam_node.name
  policy = data.aws_iam_policy_document.kiam_node_policy.json
}

## Create Kiam server role assumable by Kiam nodes
resource "aws_iam_role" "kiam_server" {
  name                  = "${module.label.id}-kiam-server"
  description           = "Role the Kiam server process assumes"
  assume_role_policy    = data.aws_iam_policy_document.kiam_node_assume_server_policy.json
  force_detach_policies = true
  path                  = var.iam_path
  permissions_boundary  = var.permissions_boundary
  tags                  = local.tags
}

## Inline Kiam server process policy to assume other roles
resource "aws_iam_policy" "kiam_server" {
  name        = "${module.label.id}-kiam-server"
  description = "Policy for the Kiam Server process"
  policy      = data.aws_iam_policy_document.kiam_server_policy.json
}

## Duplicates the default EKS worker node permissions
#
# ----
resource "aws_iam_role_policy_attachment" "kiam_node_AmazonEKSWorkerNodePolicy" {
  policy_arn = "${local.policy_arn_prefix}/AmazonEKSWorkerNodePolicy"
  role       = aws_iam_role.kiam_node.name
}

resource "aws_iam_role_policy_attachment" "kiam_node_AmazonEKS_CNI_Policy" {
  policy_arn = "${local.policy_arn_prefix}/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.kiam_node.name
}

resource "aws_iam_role_policy_attachment" "kiam_node_AmazonEC2ContainerRegistryReadOnly" {
  policy_arn = "${local.policy_arn_prefix}/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.kiam_node.name
}
#  ----

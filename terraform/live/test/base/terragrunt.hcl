terraform {
  source = "${path_relative_from_include()}/../modules//base"
}

include {
  path = find_in_parent_folders()
}

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

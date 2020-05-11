terraform {
  source = "${path_relative_from_include()}/../modules//eks"
}

include {
  path = find_in_parent_folders()
}

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

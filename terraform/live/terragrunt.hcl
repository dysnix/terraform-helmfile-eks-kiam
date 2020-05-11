terraform {
  before_hook "modules-config" {
    commands = ["init-from-module", "init"]
    execute = [
      "bash",
      "-c",
      <<EOT

      # clean up first
      ls -1 ${get_parent_terragrunt_dir()}/_common | xargs rm -f

      # fresh copy (in case of disable target files)
      for file in default-backend.tf; do \
        cp ${get_parent_terragrunt_dir()}/_common/$file .
      done
EOT
    ]
  }

  extra_arguments "conditional_vars" {
    commands = [
      "apply",
      "plan",
      "import",
      "push",
      "refresh",
      "destroy",
    ]

    required_var_files = [
      "${get_parent_terragrunt_dir()}/project.tfvars"
    ]

    optional_var_files = [
      "${get_terragrunt_dir()}/../stage.tfvars"
    ]
  }
}

remote_state {
  backend = "s3"
  config = {
    bucket         = "opsfleet-terraform"
    key            = "${path_relative_to_include()}/terraform.tfstate"
    region         = "eu-central-1"
    encrypt        = true
    dynamodb_table = "opsfleet-terraform"
  }
}

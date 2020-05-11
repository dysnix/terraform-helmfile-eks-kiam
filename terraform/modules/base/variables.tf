variable "region" {
  default = ""
  type    = string
}

variable "cidr" {
  default = "VPC Cidr block"
  type    = string
}

variable "public_subnets" {
  description = "A list of public subnets inside the VPC"
  default     = []
  type        = list(string)
}

variable "private_subnets" {
  description = "A list of private subnets inside the VPC"
  default     = []
  type        = list(string)
}

variable "azs" {
  description = "A list of availability zones in the region"
  default     = []
  type        = list(string)
}

variable "shared_k8s_cluster" {
  description = "Populate tags for Kubernetes shared cluster on VPC resources"
  default     = ""
  type        = string
}

variable "project" {
  default = {}
}

variable "stage" {
  default = {}
}

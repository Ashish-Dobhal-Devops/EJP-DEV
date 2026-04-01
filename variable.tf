# Variables for General Configuration
variable "region" {}
# variable "fingerprint" {}
# variable "user_ocid" {}
#variable "tenancy_ocid" {}
variable "compartment_ocid" {}

variable "project_name" {
  default = "EJP"
}

variable "environment" {
  default = "PREPROD"
}

# PROD VCN Configuration

variable "vcn_cidr_block" {
  default = "10.14.0.0/16"
}

variable "prod_subnet_configs" {
  type = map(object({
    cidr_block = string
    type       = string
  }))
  default = {
    db = {
      cidr_block = "10.14.2.0/24"
      type       = "DB"
    }
    api = {
      cidr_block = "10.14.0.0/24"
      type       = "K8S-API"
    }
    wrk = {
      cidr_block = "10.14.1.0/24"
      type       = "K8S-WRK"
    }
    pod = {
      cidr_block = "10.14.3.0/24"
      type       = "K8S-POD"
    }
    lb = {
      cidr_block = "10.14.4.0/27"
      type       = "PVT-LB"
    }
  }
}


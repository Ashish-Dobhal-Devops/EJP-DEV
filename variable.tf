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
  default = "DEV"
}

# PROD VCN Configuration

variable "vcn_cidr_block" {
  default = "10.12.0.0/16"
}

variable "prod_subnet_configs" {
  type = map(object({
    cidr_block = string
    type       = string
  }))
  default = {
    db = {
      cidr_block = "10.12.2.0/23"
      type       = "DB"
    }
    api = {
      cidr_block = "10.12.0.0/23"
      type       = "K8S-API"
    }
    wrk = {
      cidr_block = "10.12.6.0/23"
      type       = "K8S-WRK"
    }
    pod = {
      cidr_block = "10.12.8.0/21"
      type       = "K8S-POD"
    }
    lb = {
      cidr_block = "10.12.4.0/23"
      type       = "PVT-LB"
    }
  }
}


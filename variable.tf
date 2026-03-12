# Variables for General Configuration
variable "region" {}
# variable "fingerprint" {}
# variable "user_ocid" {}
#variable "tenancy_ocid" {}
variable "compartment_ocid" {}

variable "project_name" {
  default = "KUBE"
}

variable "environment" {
  default = "DEV"
}

# PROD VCN Configuration

variable "vcn_cidr_block" {
  default = "10.101.0.0/16"
}

variable "prod_subnet_configs" {
  type = map(object({
    cidr_block = string
    type       = string
  }))
  default = {
    app = {
      cidr_block = "10.101.0.0/24"
      type       = "APP"
    }
    db = {
      cidr_block = "10.101.1.0/24"
      type       = "DB"
    }
    admin = {
      cidr_block = "10.101.2.0/24"
      type       = "ADMIN"
    }
    api = {
      cidr_block = "10.101.3.0/24"
      type       = "K8S-API"
    }
    wrk = {
      cidr_block = "10.101.4.0/24"
      type       = "K8S-WRK"
    }
    pod = {
      cidr_block = "10.101.5.0/24"
      type       = "K8S-POD"
    }
    lb = {
      cidr_block = "10.101.6.0/27"
      type       = "PVT-LB"
    }
  }
}


# Kubernetes cluster variables

variable "k8s_version" {
   type    = string
   default = "v1.33.1"
}


variable "node_pool_ocpus" {
   type    = number
   default = 2
}

variable "node_pool_memory" {
   type    = number
   default = 4
}


variable "node_pool_boot_vol_size" {
    type    = number
    default = 50
}

variable "node_pool_image_id" {
   type    = string
   default = "ocid1.image.oc1.ap-mumbai-1.aaaaaaaaxeje3tgahizij7jyydcjsezdjhqwin37mzdvv6fpor5f5w7drcqa"
}

variable "node_ad" {
   type    = string
   default = "JeMa:AP-MUMBAI-1-AD-1"
}

variable "node_pool_size" {
   type    = number
   default = 2
}    

variable "ssh_public_key" {
   type    = string
   default = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDCC/l7m/t2cxxbmkKWf01JwQZusItZpeg6KN8oaGUkOc4BtQ+xcOIVuveG6/0OIhDmt1WZhQutBLMPcUvPSAYUyT9P09twP3XytqORdo5Du34RWbE6D36SWmzwOZ2yloL5hIJ7dypoVpXRNoNdxBdi4jte1sD6nBv6+OunTZPmbzE8l45XI13lgJlKOvWzK9GrijP56NHgLkuZNainbDJJ5FeWKprq8RHXPmaJiVBl23WhbYBx2GSJ3gHC9jkLOD72AlqTDpjoi8g/1d+B8LM2x9jLfJdQw5WsE9Q0DX+xoQd57YEezqg5RFeP0uV+LYDwsxrtweLNpOGLHGzk94/p"
}

# Jenkins server variables

variable "Jenkins_ocpus" {
   type    = number
   default = 2
}

variable "Jenkins_memory" {
   type    = number
   default = 4
}

variable "Jenkins_image_id" {
   type    = string
   default = "ocid1.image.oc1.ap-mumbai-1.aaaaaaaaq5pnlxumt6qmpnlupl3nibefpqmhdh56ps4w345cia5dhgaeipra"
}

variable "Jenkins_boot_volume_size" {
    type    = number
    default = 100
}


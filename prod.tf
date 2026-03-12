locals {
  subnet_cidrs = { for k, v in var.prod_subnet_configs : k => v.cidr_block }
}

# Virtual Cloud Network (VCN)
resource "oci_core_vcn" "vcn" {
  cidr_block     = var.vcn_cidr_block     
  dns_label      = lower(substr("${var.project_name}${lower(var.environment)}vcn", 0, 15))
  compartment_id = var.compartment_ocid
  display_name   = "${var.project_name}-${var.environment}-VCN"
}

# NAT Gateway
resource "oci_core_nat_gateway" "nat_gateway" {
  compartment_id = var.compartment_ocid
  vcn_id         = oci_core_vcn.vcn.id
  display_name   = "${var.project_name}-${var.environment}-NATGW"
}

# Data Source for OCI Services
data "oci_core_services" "oci_services" {}

# Service Gateway
resource "oci_core_service_gateway" "service_gateway" {
  compartment_id = var.compartment_ocid
  vcn_id         = oci_core_vcn.vcn.id
  display_name   = "${var.project_name}-${var.environment}-SGW"

  services {
    service_id = data.oci_core_services.oci_services.services[1].id
  }
}

# Route Table
resource "oci_core_route_table" "route_table" {
  compartment_id = var.compartment_ocid
  vcn_id         = oci_core_vcn.vcn.id
  display_name   = "${var.project_name}-${var.environment}-VCN-PVT-RT"

  route_rules {
    network_entity_id = oci_core_service_gateway.service_gateway.id
    destination       = "all-hyd-services-in-oracle-services-network"
    destination_type  = "SERVICE_CIDR_BLOCK"
  }

  route_rules {
    network_entity_id = oci_core_nat_gateway.nat_gateway.id
    destination       = "0.0.0.0/0"
    destination_type  = "CIDR_BLOCK"
  }
}

# Security Lists with DYNAMIC CIDRs from locals (No hard-coding!)
resource "oci_core_security_list" "subnet_sls" {
  for_each = var.prod_subnet_configs

  compartment_id = var.compartment_ocid
  vcn_id         = oci_core_vcn.vcn.id
  display_name   = "${var.project_name}-${var.environment}-${each.value.type}-SL"

# ========== K8S-API SUBNET RULES (Dynamic CIDRs) ==========
  
  dynamic "ingress_security_rules" {
    for_each = each.value.type == "K8S-API" ? [1] : []
    content {
      source      = local.subnet_cidrs["wrk"]
      protocol    = "6"
      description = "Kubernetes worker to Kubernetes API endpoint communication"
      tcp_options {
          min = 6443
          max = 6443
      }
    }
  }

  dynamic "ingress_security_rules" {
    for_each = each.value.type == "K8S-API" ? [1] : []
    content {
      source      = local.subnet_cidrs["wrk"]
      protocol    = "6"
      description = "Kubernetes worker to Kubernetes API endpoint communication"
      tcp_options {
          min = 12250
          max = 12250
      }
    }
  }

  dynamic "ingress_security_rules" {
    for_each = each.value.type == "K8S-API" ? [1] : []
    content {
      source      = local.subnet_cidrs["pod"]
      protocol    = "6"
      description = "Pod to Kubernetes API endpoint communication (when using VCN-native pod networking)"
      tcp_options {
          min = 6443
          max = 6443
      }
    }
  }

  dynamic "ingress_security_rules" {
    for_each = each.value.type == "K8S-API" ? [1] : []
    content {
      source      = local.subnet_cidrs["pod"]
      protocol    = "6"
      description = "Pod to Kubernetes API endpoint communication (when using VCN-native pod networking)"
      tcp_options {
          min = 12250
          max = 12250
      }
    }
  }

  dynamic "ingress_security_rules" {
    for_each = each.value.type == "K8S-API" ? [1] : []
    content {
      source      = local.subnet_cidrs["admin"]
      protocol    = "6"
      description = "For cluster access from Jenkins server subnet"
      tcp_options {
          min = 6443
          max = 6443
      }
    }
  }

  dynamic "egress_security_rules" {
    for_each = each.value.type == "K8S-API" ? [1] : []
    content {
      destination      = local.subnet_cidrs["wrk"]
      protocol         = "6"
      description = "Allow Kubernetes control plane to communicate with worker nodes"
      destination_type = "CIDR_BLOCK"
    }
  }

  dynamic "egress_security_rules" {
    for_each = each.value.type == "K8S-API" ? [1] : []
    content {
      destination      = local.subnet_cidrs["pod"]
      protocol         = "all"
      description = "Allow Kubernetes API endpoint to communicate with pods (when using VCN-native pod networking)"
      destination_type = "CIDR_BLOCK"
    }
  }

  dynamic "egress_security_rules" {
    for_each = each.value.type == "K8S-API" ? [1] : []
    content {
      destination      = "all-bom-services-in-oracle-services-network"
      protocol         = "6"
      description = "	Allow Kubernetes API endpoint to communicate with OKE"
      destination_type = "SERVICE_CIDR_BLOCK"
    }
  }

   # ========== K8S-WRK SUBNET RULES (Dynamic CIDRs) ==========
  
  dynamic "ingress_security_rules" {
    for_each = each.value.type == "K8S-WRK" ? [1] : []
    content {
      source      = local.subnet_cidrs["wrk"]
      protocol    = "all"
      description = "Allows communication from or to worker nodes"
      source_type = "CIDR_BLOCK"
    }
  }

  dynamic "ingress_security_rules" {
    for_each = each.value.type == "K8S-WRK" ? [1] : []
    content {
      source      = local.subnet_cidrs["pod"]
      protocol    = "all"
      description = "Allow pods on one worker node to communicate with pods on other worker nodes (when using VCN-native pod networking)"
      source_type = "CIDR_BLOCK"
    }
  }

  dynamic "ingress_security_rules" {
    for_each = each.value.type == "K8S-WRK" ? [1] : []
    content {
      source      = local.subnet_cidrs["api"]
      protocol    = "6"
      description = "Allow Kubernetes API endpoint to communicate with worker nodes"
      source_type = "CIDR_BLOCK"
    }
  }

  dynamic "ingress_security_rules" {
    for_each = each.value.type == "K8S-WRK" ? [1] : []
    content {
      source      = local.subnet_cidrs["admin"]
      protocol    = "6"
      description = "Allow inbound SSH traffic to managed nodes from Jenkins server subnet"
      tcp_options {
          min = 22
          max = 22
      }
    }
  }

  dynamic "egress_security_rules" {
    for_each = each.value.type == "K8S-WRK" ? [1] : []
    content {
      destination      = local.subnet_cidrs["wrk"]
      protocol         = "all"
      description = "	Allows communication from (or to) worker nodes"
      destination_type = "CIDR_BLOCK"
    }
  }

  dynamic "egress_security_rules" {
    for_each = each.value.type == "K8S-WRK" ? [1] : []
    content {
      destination      = local.subnet_cidrs["pod"]
      protocol         = "all"
      description = "Allow worker nodes to communicate with pods on other worker nodes (when using VCN-native pod networking)"
      destination_type = "CIDR_BLOCK"
    }
  }

  dynamic "egress_security_rules" {
    for_each = each.value.type == "K8S-WRK" ? [1] : []
    content {
      destination      = "0.0.0.0/0"
      protocol         = "6"
      description = "Allow worker nodes to communicate with internet"
      destination_type = "CIDR_BLOCK"
    }
  }

  dynamic "egress_security_rules" {
    for_each = each.value.type == "K8S-WRK" ? [1] : []
    content {
      destination      = "all-bom-services-in-oracle-services-network"
      protocol         = "6"
      description = "Allow nodes to communicate with OKE"
      destination_type = "SERVICE_CIDR_BLOCK"
    }
  }

  dynamic "egress_security_rules" {
    for_each = each.value.type == "K8S-WRK" ? [1] : []
    content {
      destination      = local.subnet_cidrs["api"]
      protocol         = "6"
      description = "Kubernetes worker to Kubernetes API endpoint communication"
      tcp_options {
          min = 6443
          max = 6443
      }
    }
  }

  dynamic "egress_security_rules" {
    for_each = each.value.type == "K8S-WRK" ? [1] : []
    content {
      destination      = local.subnet_cidrs["api"]
      protocol         = "6"
      description = "Kubernetes worker to Kubernetes API endpoint communication"
      tcp_options {
          min = 12250
          max = 12250
      }
    }
  }

# ========== K8S-POD SUBNET RULES (Dynamic CIDRs) ==========
  
  dynamic "ingress_security_rules" {
    for_each = each.value.type == "K8S-POD" ? [1] : []
    content {
      source      = local.subnet_cidrs["wrk"]
      protocol    = "all"
      description = "Allow pods on one worker node to communicate with pods on other worker nodes"
      source_type = "CIDR_BLOCK"
    }
  }

  dynamic "ingress_security_rules" {
    for_each = each.value.type == "K8S-POD" ? [1] : []
    content {
      source      = local.subnet_cidrs["pod"]
      protocol    = "all"
      description = "Allow pods to communicate with each other"
      source_type = "CIDR_BLOCK"
    }
  }

  dynamic "ingress_security_rules" {
    for_each = each.value.type == "K8S-POD" ? [1] : []
    content {
      source      = local.subnet_cidrs["api"]
      protocol    = "all"
      description = "Kubernetes API endpoint to pod communication (when using VCN-native pod networking)"
      source_type = "CIDR_BLOCK"
    }
  }


  dynamic "egress_security_rules" {
    for_each = each.value.type == "K8S-POD" ? [1] : []
    content {
      destination      = local.subnet_cidrs["pod"]
      protocol         = "all"
      description = "Allow pods to communicate with each other"
      destination_type = "CIDR_BLOCK"
    }
  }

  dynamic "egress_security_rules" {
    for_each = each.value.type == "K8S-POD" ? [1] : []
    content {
      destination      = "all-bom-services-in-oracle-services-network"
      protocol         = "6"
      description = "	Allow worker nodes/pods to communicate with OCI services"
      destination_type = "SERVICE_CIDR_BLOCK"
    }
  }

  dynamic "egress_security_rules" {
    for_each = each.value.type == "K8S-POD" ? [1] : []
    content {
      destination      = "0.0.0.0/0"
      protocol         = "6"
      description = "Allow pods to communicate with internet"
      destination_type = "CIDR_BLOCK"
    }
  } 

  dynamic "egress_security_rules" {
    for_each = each.value.type == "K8S-POD" ? [1] : []
    content {
      destination      = local.subnet_cidrs["wrk"]
      protocol         = "6"
      description = "Allows communication with worker nodes"
      destination_type = "CIDR_BLOCK"
    }
  } 

  dynamic "egress_security_rules" {
    for_each = each.value.type == "K8S-POD" ? [1] : []
    content {
      destination      = local.subnet_cidrs["api"]
      protocol         = "6"
      description = "Pod to Kubernetes API endpoint communication (when using VCN-native pod networking)"
      tcp_options {
          min = 6443
          max = 6443
      }
    }
  }

  dynamic "egress_security_rules" {
    for_each = each.value.type == "K8S-POD" ? [1] : []
    content {
      destination      = local.subnet_cidrs["api"]
      protocol         = "6"
      description = "Pod to Kubernetes API endpoint communication (when using VCN-native pod networking)"
      tcp_options {
          min = 12250
          max = 12250
      }
    }
  }

# ========== ADMIN SUBNET RULES (Dynamic CIDRs) ==========
  
  dynamic "ingress_security_rules" {
    for_each = each.value.type == "ADMIN" ? [1] : []
    content {
      source      = "10.20.0.54/32"
      protocol    = "6"
      description = "Allow SSH over the VPN server"
      tcp_options {
          min = 22
          max = 22
      }
    }
  }

  dynamic "ingress_security_rules" {
    for_each = each.value.type == "ADMIN" ? [1] : []
    content {
      source      = "10.20.0.54/32"
      protocol    = "6"
      description = "Allow Jenkins UI access over VPN"
      tcp_options {
          min = 8080
          max = 8080
      }
    }
  }

  
  dynamic "egress_security_rules" {
    for_each = each.value.type == "ADMIN" ? [1] : []
    content {
      destination      = local.subnet_cidrs["api"]
      protocol         = "6"
      description = "Allow Jenkins access to Kubernetes via kubectl"
      tcp_options {
          min = 6443
          max = 6443
      }
    }
  }

  dynamic "egress_security_rules" {
    for_each = each.value.type == "ADMIN" ? [1] : []
    content {
      destination      = local.subnet_cidrs["wrk"]
      protocol         = "6"
      description = "Allow SSH access of worker nodes via Jenkins"
      tcp_options {
          min = 22
          max = 22
      }
    }
  }


  dynamic "egress_security_rules" {
    for_each = each.value.type == "ADMIN" ? [1] : []
    content {
      destination      = "0.0.0.0/0"
      protocol         = "6"
      description = "Allow pods to communicate with internet"
      tcp_options {
          min = 80
          max = 80
      }
    }
  } 

  dynamic "egress_security_rules" {
    for_each = each.value.type == "ADMIN" ? [1] : []
    content {
      destination      = "0.0.0.0/0"
      protocol         = "6"
      description = "Allow pods to communicate with internet"
      tcp_options {
          min = 443
          max = 443
      }
    }
  } 
}



# Subnets created dynamically and assigned respective security lists
resource "oci_core_subnet" "subnets" {
  for_each = var.prod_subnet_configs

  cidr_block                 = each.value.cidr_block
  compartment_id             = var.compartment_ocid
  vcn_id                    = oci_core_vcn.vcn.id
  display_name               = "${var.project_name}-${var.environment}-${each.value.type}-SN"
  dns_label                  = lower(substr("${var.project_name}${lower(var.environment)}${replace(each.value.type, "-", "")}sn", 0, 15))
  prohibit_public_ip_on_vnic = true

  security_list_ids = [oci_core_security_list.subnet_sls[each.key].id]
  route_table_id    = oci_core_route_table.route_table.id
}

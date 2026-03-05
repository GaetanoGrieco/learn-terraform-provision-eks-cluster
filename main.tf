# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MPL-2.0

############################################
# Provider AWS (usa var.region = us-east-1)
############################################
provider "aws" {
  region = var.region
}

############################################
# Dati di supporto
############################################

# Filtra le AZ (no local zones)
data "aws_availability_zones" "available" {
  filter {
    name   = "opt-in-status"
    values = ["opt-in-not-required"]
  }
}

############################################
# Naming cluster
############################################
locals {
  cluster_name = "education-eks-${random_string.suffix.result}"
}

resource "random_string" "suffix" {
  length  = 8
  special = false
}

############################################
# VPC
############################################
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "5.8.1"

  name = "education-vpc"

  cidr = "10.0.0.0/16"
  azs  = slice(data.aws_availability_zones.available.names, 0, 3)

  private_subnets = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  public_subnets  = ["10.0.4.0/24", "10.0.5.0/24", "10.0.6.0/24"]

  enable_nat_gateway   = true
  single_nat_gateway   = true
  enable_dns_hostnames = true

  public_subnet_tags = {
    "kubernetes.io/role/elb" = 1
  }

  private_subnet_tags = {
    "kubernetes.io/role/internal-elb" = 1
  }
}

############################################
# EKS Node Group Configuration
############################################
locals {
  eks_managed_node_groups_config = {
    one = {
      name = "node-group-1"

      instance_types = ["t3.small"]

      min_size     = 1
      max_size     = 3
      desired_size = 2

      # NESSUN user_data: installazione CloudWatch Agent gestita via SSM
    }

    two = {
      name = "node-group-2"

      instance_types = ["t3.small"]

      min_size     = 1
      max_size     = 2
      desired_size = 1

      # NESSUN user_data: installazione CloudWatch Agent gestita via SSM
    }
  }

  # Extract node group names for dynamic targeting (riuso per SSM targets)
  node_group_names = [for _, ng in local.eks_managed_node_groups_config : ng.name]
}
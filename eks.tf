# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MPL-2.0

############################################
# EKS Cluster Configuration
############################################

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "20.8.5"

  cluster_name    = local.cluster_name
  cluster_version = "1.35"

  cluster_endpoint_public_access           = true
  enable_cluster_creator_admin_permissions = true

  # EBS CSI driver addon with IRSA
  cluster_addons = {
    aws-ebs-csi-driver = {
      service_account_role_arn = module.irsa-ebs-csi.iam_role_arn
    }
  }

  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnets

  eks_managed_node_group_defaults = {
    ami_type = "AL2023_x86_64_STANDARD"
  }

  eks_managed_node_groups = local.eks_managed_node_groups_config
}

############################################
# IAM Role for EBS CSI Driver (IRSA)
############################################
# https://aws.amazon.com/blogs/containers/amazon-ebs-csi-driver-is-now-generally-available-in-amazon-eks-add-ons/

data "aws_iam_policy" "ebs_csi_policy" {
  arn = "arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy"
}

module "irsa-ebs-csi" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-assumable-role-with-oidc"
  version = "5.39.0"

  create_role                   = true
  role_name                     = "AmazonEKSTFEBSCSIRole-${module.eks.cluster_name}"
  provider_url                  = module.eks.oidc_provider
  role_policy_arns              = [data.aws_iam_policy.ebs_csi_policy.arn]
  oidc_fully_qualified_subjects = ["system:serviceaccount:kube-system:ebs-csi-controller-sa"]
}

############################################
# Kubernetes Provider
############################################
# Token for cluster authentication
data "aws_eks_cluster_auth" "this" {
  name = module.eks.cluster_name
}

# Configure Kubernetes provider with cluster endpoint/CA/token
provider "kubernetes" {
  host                   = module.eks.cluster_endpoint
  cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)
  token                  = data.aws_eks_cluster_auth.this.token
}

############################################
# Wait for EKS Cluster to be Active
############################################
resource "null_resource" "wait_for_eks_active" {
  depends_on = [module.eks]

  provisioner "local-exec" {
    command = "aws eks wait cluster-active --name ${module.eks.cluster_name} --region ${var.region}"
  }
}

resource "null_resource" "update_kubeconfig" {
  depends_on = [null_resource.wait_for_eks_active]

  provisioner "local-exec" {
    command = "aws eks update-kubeconfig --name ${module.eks.cluster_name} --region ${var.region}"
  }
}
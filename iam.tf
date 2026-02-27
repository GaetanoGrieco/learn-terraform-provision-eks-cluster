data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

locals {
  cw_role_name = "EKS-PodId-CWObs-${module.eks.cluster_name}"
}

resource "aws_iam_role" "cw_observability" {
  name = substr(local.cw_role_name, 0, 64)

  # TRUST POLICY EKS POD IDENTITY: entrambe le azioni sono necessarie
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Sid       = "AllowEksAuthToAssumeRoleForPodIdentity",
      Effect    = "Allow",
      Principal = { Service = "pods.eks.amazonaws.com" },
      Action = [
        "sts:AssumeRole",
        "sts:TagSession"
      ]
    }]
  })
}

resource "aws_iam_role_policy_attachment" "cw_observability_policy" {
  role = aws_iam_role.cw_observability.name
  # In sandbox questa è la policy disponibile e sufficiente
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
}
data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

locals {
  cw_role_name = "EKS-PodId-CWObs-${module.eks.cluster_name}"
  cw_namespace = "amazon-cloudwatch"
  cw_sa        = "cloudwatch-agent"

  # L'output module.eks.oidc_provider è l'URL tipo: oidc.eks.<region>.amazonaws.com/id/<ID>
  # Costruiamo l'ARN del provider OIDC dinamicamente per l'AssumeRoleWithWebIdentity
  oidc_provider_arn = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:oidc-provider/${module.eks.oidc_provider}"
}


resource "aws_iam_role" "cw_observability" {
  name = substr(local.cw_role_name, 0, 64)

  # TRUST POLICY IRSA dinamica (sandbox-safe)
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect = "Allow",
      Action = "sts:AssumeRoleWithWebIdentity",
      Principal = {
        Federated = local.oidc_provider_arn
      },
      Condition = {
        StringEquals = {
          # Esempio chiave: "oidc.eks.us-east-1.amazonaws.com/id/<OIDC_ID>:sub"
          "${module.eks.oidc_provider}:sub" = "system:serviceaccount:${local.cw_namespace}:${local.cw_sa}"
        }
      }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "cw_observability_policy" {
  role       = aws_iam_role.cw_observability.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
}

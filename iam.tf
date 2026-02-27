data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

# Ruolo IAM per l’add-on Amazon CloudWatch Observability via EKS Pod Identity
resource "aws_iam_role" "cw_observability" {
  name = "AmazonEKSPodIdentityAmazonCloudWatchObservabilityRole-${module.eks.cluster_name}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect = "Allow",
      Action = "sts:AssumeRole",
      Principal = { Service = "pods.eks.amazonaws.com" }, # <- Pod Identity (NON OIDC/IRSA)
      Condition = {
        StringEquals = {
          "aws:SourceAccount" = data.aws_caller_identity.current.account_id
        },
        ArnLike = {
          # Restringe al tuo cluster EKS
          "aws:SourceArn" = "arn:aws:eks:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:cluster/${module.eks.cluster_name}"
        }
      }
    }]
  })
}

# Policy consigliata da AWS per l’osservabilità del cluster
resource "aws_iam_role_policy_attachment" "cw_observability_policy" {
  role       = aws_iam_role.cw_observability.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSCloudWatchObservability"
}

# In alternativa (più permissiva, se ti serve anche CW Agent classico):
# resource "aws_iam_role_policy_attachment" "cw_agent_server_policy" {
#   role       = aws_iam_role.cw_observability.name
#   policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
# }
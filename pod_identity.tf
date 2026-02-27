resource "aws_eks_pod_identity_association" "cw_observability" {
  cluster_name    = module.eks.cluster_name
  namespace       = kubernetes_namespace.amazon_cloudwatch.metadata[0].name
  service_account = kubernetes_service_account.cloudwatch_agent.metadata[0].name

  role_arn = aws_iam_role.cw_observability.arn

  depends_on = [
    aws_eks_addon.pod_identity_agent,
    aws_eks_addon.cloudwatch_observability,
    kubernetes_service_account.cloudwatch_agent
  ]
}
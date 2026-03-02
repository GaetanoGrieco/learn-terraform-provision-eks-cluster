output "cluster_name" {
  description = "EKS cluster name"
  value       = module.eks.cluster_name
}

output "cluster_endpoint" {
  description = "EKS cluster endpoint"
  value       = module.eks.cluster_endpoint
}

output "oidc_provider_url" {
  description = "OIDC provider URL used by the EKS cluster"
  value       = module.eks.oidc_provider
}

output "cloudwatch_observability_role_arn" {
  description = "IAM Role ARN used by CloudWatch Observability via Pod Identity"
  value       = aws_iam_role.cw_observability.arn
}
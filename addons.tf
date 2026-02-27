# Assicuriamoci di conoscere il nome del cluster (già creato dal modulo EKS)
# Se preferisci, puoi usare direttamente module.eks.cluster_name
data "aws_eks_cluster" "this" {
  name = module.eks.cluster_name
}

# 1) EKS Pod Identity Agent (obbligatorio per far funzionare le associazioni Pod Identity)
resource "aws_eks_addon" "pod_identity_agent" {
  cluster_name                = data.aws_eks_cluster.this.name
  addon_name                  = "eks-pod-identity-agent"
  resolve_conflicts_on_create = "OVERWRITE"
  resolve_conflicts_on_update = "OVERWRITE"
}

# 2) Amazon CloudWatch Observability (installa CloudWatch Agent e abilita Container Insights)
resource "aws_eks_addon" "cloudwatch_observability" {
  cluster_name                = data.aws_eks_cluster.this.name
  addon_name                  = "amazon-cloudwatch-observability"
  resolve_conflicts_on_create = "OVERWRITE"
  resolve_conflicts_on_update = "OVERWRITE"
}
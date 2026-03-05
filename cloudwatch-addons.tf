data "aws_eks_cluster" "this" {
  name       = module.eks.cluster_name
  depends_on = [module.eks]
}

resource "aws_eks_addon" "cloudwatch_observability" {
  cluster_name                = data.aws_eks_cluster.this.name
  addon_name                  = "amazon-cloudwatch-observability"
  resolve_conflicts_on_create = "OVERWRITE"
  resolve_conflicts_on_update = "OVERWRITE"
}

resource "null_resource" "annotate_cw_sa" {
  depends_on = [
    aws_eks_addon.cloudwatch_observability,
    null_resource.update_kubeconfig
  ]

  provisioner "local-exec" {
    command = "bash -c 'NS=amazon-cloudwatch; SA=cloudwatch-agent; ROLE_ARN=${aws_iam_role.cw_observability.arn}; echo \"Attendo il ServiceAccount...\"; for i in {1..30}; do if kubectl get sa \"$SA\" -n \"$NS\" >/dev/null 2>&1; then echo Annotazione IRSA...; kubectl annotate sa \"$SA\" -n \"$NS\" \"eks.amazonaws.com/role-arn=$ROLE_ARN\" --overwrite; exit 0; fi; sleep 10; done; echo \"ServiceAccount non trovato\" >&2; exit 1'"
  }
}
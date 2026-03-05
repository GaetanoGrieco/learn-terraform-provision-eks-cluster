############################################
# CloudWatch Agent Manifest dinamico
############################################

data "template_file" "cw_agent_manifest" {
  template = file("${path.module}/cloudwatch-agent.yaml")
  vars = {
    cluster_name = local.cluster_name
  }
}

resource "kubernetes_manifest" "cloudwatch_agent" {
  manifest = yamldecode(data.template_file.cw_agent_manifest.rendered)

  field_manager {
    force_conflicts = true
  }
}
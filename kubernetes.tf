resource "kubernetes_namespace_v1" "amazon_cloudwatch" {
  metadata {
    name = "amazon-cloudwatch"
  }
}

resource "kubernetes_service_account_v1" "cloudwatch_agent" {
  metadata {
    name      = "cloudwatch-agent"
    namespace = kubernetes_namespace_v1.amazon_cloudwatch.metadata[0].name
  }
}
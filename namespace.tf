resource "kubernetes_namespace" "default" {
  metadata {
    name = var.namespace
  }
}
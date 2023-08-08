variable "namespace" {
  default = "aplicaciones-comunes"
  type    = string
}

resource "kubernetes_namespace" "default" {
  metadata {
    name = var.namespace
  }
}
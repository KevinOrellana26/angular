variable "namespace" {
  default = "aplicaciones-comunes"
  type    = string
}

///////////////////////////// Provider
terraform {
  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = ">=2.21.1"
    }
  }
}

provider "kubernetes" {
}

provider "aws" {
}

resource "kubernetes_manifest" "angular-pvc" {
  depends_on = [
    kubernetes_namespace.default
  ]
  manifest = yamldecode(templatefile(
    "${path.module}/manifests/angular-pvc.tpl.yaml",
    {
      "namespace" = var.namespace
    }
  ))
}

resource "kubernetes_stateful_set" "angular" {
  depends_on = [
    kubernetes_namespace.default
  ]
  metadata {
    name      = "angular"
    namespace = var.namespace
  }
  spec {
    replicas = 1
    selector {
      match_labels = {
        app = "angular"
      }
    }
    template {
      metadata {
        labels = {
          app = "angular"
        }
      }
      spec {
        volume {
          name = "angular"
          persistent_volume_claim {
            claim_name = "angular-pvc"
          }
        }
        container {
          name  = "angular"
          image = "kevinorellana/angular:v1"
          port {
            container_port = 4500
          }
          resources {
            limits = {
              memory = "5Gi"
              cpu    = "1000m"
            }
            requests = {
              memory = "2Gi"
              cpu    = "500m"
            }
          }
          volume_mount {
            name       = "angular"
            mount_path = "/hello-world"
          }
          image_pull_policy = "Always"
        }
      }
    }
    service_name = "angular"
    update_strategy {
      type = "RollingUpdate"
    }
  }
}

resource "kubernetes_manifest" "angular_service" {
  depends_on = [
    kubernetes_namespace.default,
  ]
  manifest = yamldecode(templatefile(
    "${path.module}/manifests/angular-service.tpl.yaml",
    {
      "namespace" = var.namespace
    }
  ))
}

resource "kubernetes_manifest" "angular_ingress" {
  depends_on = [
    kubernetes_namespace.default,
  ]
  manifest = yamldecode(templatefile(
    "${path.module}/manifests/angular-ingress.tpl.yaml",
    {
      "namespace" = var.namespace
    }
  ))
}